import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../../core/constanst/api_constants.dart';
import '../models/skin_analysis_model.dart';

abstract class ClaudeAiDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class ClaudeAiDataSourceImpl implements ClaudeAiDataSource {
  final http.Client client;

  ClaudeAiDataSourceImpl({required this.client});

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      // Leer la imagen y convertirla a base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);
      
      // Obtener la extensión del archivo
      final extension = imageFile.path.split('.').last.toLowerCase();
      final mediaType = _getMediaType(extension);

      // API Key desde .env
      final apiKey = dotenv.env['CLAUDE_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key no configurada');
      }

      // Construir el prompt para análisis dermatológico
      final prompt = _buildDermatologyPrompt();

      // Construir el body de la petición
      final body = jsonEncode({
        'model': ApiConstants.claudeModel,
        'max_tokens': ApiConstants.maxTokens,
        'messages': [
          {
            'role': 'user',
            'content': [
              {
                'type': 'image',
                'source': {
                  'type': 'base64',
                  'media_type': mediaType,
                  'data': base64Image,
                }
              },
              {
                'type': 'text',
                'text': prompt,
              }
            ]
          }
        ]
      });

      // Hacer la petición
      final response = await client
          .post(
            Uri.parse('${ApiConstants.claudeBaseUrl}${ApiConstants.messagesEndpoint}'),
            headers: {
              ApiConstants.apiKeyHeader: apiKey,
              ApiConstants.apiVersionHeader: ApiConstants.apiVersion,
              'content-type': ApiConstants.contentTypeHeader,
            },
            body: body,
          )
          .timeout(const Duration(seconds: ApiConstants.timeoutSeconds));

      // Verificar respuesta
      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final responseText = jsonResponse['content'][0]['text'] as String;
        
        return SkinAnalysisModel.fromClaudeResponse(responseText);
      } else {
        final error = jsonDecode(response.body);
        throw Exception('Error de Claude API: ${error['error']?['message'] ?? response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión con el servidor');
    } catch (e) {
      throw Exception('Error al analizar la imagen: $e');
    }
  }

  String _getMediaType(String extension) {
    switch (extension) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      default:
        return 'image/jpeg';
    }
  }

  String _buildDermatologyPrompt() {
    return '''
Analiza esta imagen de piel como un asistente de detección temprana de condiciones dermatológicas.

Por favor proporciona:

1. DIAGNÓSTICO PRELIMINAR: Identifica posibles condiciones (ej: lunar normal, dermatitis, lesión sospechosa, etc.)

2. DESCRIPCIÓN: Describe lo que observas en la imagen (color, forma, tamaño, textura, bordes)

3. NIVEL DE RIESGO: 
   - BAJO: Condición común, probablemente benigna
   - MEDIO: Requiere observación
   - ALTO: Requiere evaluación médica urgente

4. RECOMENDACIONES: Proporciona 2-3 recomendaciones específicas

5. ATENCIÓN MÉDICA: Indica claramente si la persona DEBE consultar a un dermatólogo

IMPORTANTE: 
- Este NO es un diagnóstico médico definitivo
- Siempre recomienda consulta profesional ante dudas
- Menciona señales de alarma si las detectas (ABCDE del melanoma)

Formato de respuesta:
Diagnóstico preliminar: [tu diagnóstico]
Descripción: [tu descripción]
Nivel de riesgo: [BAJO/MEDIO/ALTO]
Recomendaciones:
- [recomendación 1]
- [recomendación 2]
- [recomendación 3]
Requiere atención médica: [SÍ/NO]
''';
  }
}