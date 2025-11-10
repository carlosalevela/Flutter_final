import 'dart:convert';
import 'dart:io';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:image/image.dart' as img;
import '../models/skin_analysis_model.dart';
import 'dart:async';

abstract class OpenAIDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class OpenAIDataSourceImpl implements OpenAIDataSource {
  final http.Client client;
  OpenAIDataSourceImpl({required this.client});

  // Cache muy simple por hash de imagen (evita repetir llamadas iguales)
  static final Map<String, String> _memoryCache = {};

  // ====== API CONFIG ======
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini'; // visión + barato
  static const _maxTokens = 250;       // reduce TPM
  static const _timeout = Duration(seconds: 35);
  static const _maxRetries = 5;

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key de OpenAI no configurada');
      }

      // 1) Preprocesar la imagen: escalar y comprimir
      final base64Image = await _imageToBase64Compressed(imageFile,
          maxSide: 768, jpegQuality: 72);

      // 2) Cache por hash de la imagen comprimida
      final imgHash = sha1.convert(utf8.encode(base64Image)).toString();
      if (_memoryCache.containsKey(imgHash)) {
        final cached = _memoryCache[imgHash]!;
        return SkinAnalysisModel.fromClaudeResponse(cached);
      }

      // 3) Construir prompt breve (menos tokens)
      final userPrompt = _buildDermatologyPrompt();

      final body = {
        'model': _model,
        'messages': [
          {
            'role': 'system',
            'content':
                'Eres un asistente de triaje dermatológico. Responde en formato breve solicitado y evita explicaciones largas.'
          },
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': userPrompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                }
              }
            ]
          }
        ],
        'temperature': 0.2,
        'max_tokens': _maxTokens
      };

      final response = await _postWithRetry(
        uri: Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode(body),
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final data = jsonDecode(response.body);
        final text = (data['choices'][0]['message']['content'] as String?)?.trim();
        if (text == null || text.isEmpty) {
          throw Exception('Respuesta vacía del modelo');
        }
        // Guarda en cache
        _memoryCache[imgHash] = text;
        return SkinAnalysisModel.fromClaudeResponse(text);
      } else {
        // Si llegó aquí es que los reintentos no resolvieron
        final err = _safeDecode(response.body);
        final msg = err?['error']?['message'] ?? response.body;
        throw Exception('Error de OpenAI: ${response.statusCode} $msg');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on FormatException catch (e) {
      throw Exception('Formato de respuesta no válido: $e');
    } on HttpException catch (e) {
      throw Exception('Error HTTP: $e');
    } on TimeoutException {
      throw Exception('Tiempo de espera agotado');
    } catch (e) {
      throw Exception('Error al analizar la imagen: $e');
    }
  }

  // ===== util: POST con reintentos, backoff y Retry-After =====
  Future<http.Response> _postWithRetry({
    required Uri uri,
    required Map<String, String> headers,
    required String body,
  }) async {
    http.Response? last;
    for (int attempt = 0; attempt <= _maxRetries; attempt++) {
      try {
        final res = await client
            .post(uri, headers: headers, body: body)
            .timeout(_timeout);

        // Éxito
        if (res.statusCode >= 200 && res.statusCode < 300) {
          return res;
        }

        // 429 o 5xx → reintentar con backoff
        if ((res.statusCode == 429 || (res.statusCode >= 500 && res.statusCode <= 504)) &&
            attempt < _maxRetries) {
          final retryAfterHeader = res.headers['retry-after'];
          // Respeta Retry-After si viene
          int? waitMs = int.tryParse(retryAfterHeader ?? '')?.clamp(1, 60) != null
              ? (int.parse(retryAfterHeader!) * 1000)
              : null;

          waitMs ??= (800 * math.pow(2, attempt)).toInt() + math.Random().nextInt(400);
          await Future.delayed(Duration(milliseconds: waitMs));
          last = res;
          continue;
        }

        // Otros errores → devolver de una
        return res;
      } on SocketException {
        // si no hay red, no sirve reintentar muchas veces
        rethrow;
      } on TimeoutException {
        if (attempt == _maxRetries) rethrow;
        final waitMs = (800 * math.pow(2, attempt)).toInt();
        await Future.delayed(Duration(milliseconds: waitMs));
      }
    }
    // Por si sale del bucle sin devolver
    throw HttpException('No se pudo completar la solicitud', uri: uri);
  }

  // ===== util: comprimir/redimensionar imagen =====
  Future<String> _imageToBase64Compressed(
    File file, {
    int maxSide = 768,
    int jpegQuality = 72,
  }) async {
    final bytes = await file.readAsBytes();
    final original = img.decodeImage(bytes);
    if (original == null) {
      throw Exception('No se pudo decodificar la imagen');
    }

    // Escala manteniendo aspecto si supera el lado máximo
    img.Image processed = original;
    final maxDim = math.max(original.width, original.height);
    if (maxDim > maxSide) {
      processed = img.copyResize(
        original,
        width: original.width >= original.height ? maxSide : null,
        height: original.height > original.width ? maxSide : null,
        interpolation: img.Interpolation.cubic,
      );
    }

    // Codifica a JPEG con calidad dada
    final jpg = img.encodeJpg(processed, quality: jpegQuality);
    return base64Encode(jpg);
  }

  Map<String, dynamic>? _safeDecode(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _buildDermatologyPrompt() {
    return '''
Analiza la imagen de piel como triaje dermatológico temprano.
Responde SOLO con el siguiente formato, en frases breves:

Diagnóstico preliminar: ...
Descripción: color, forma, tamaño aprox., textura, bordes.
Nivel de riesgo: BAJO | MEDIO | ALTO
Recomendaciones:
- ...
- ...
- ...
Requiere atención médica: SÍ | NO

Notas:
- No es diagnóstico definitivo.
- Si ves señales ABCDE de melanoma, menciónalas en la descripción.
''';
  }
}
