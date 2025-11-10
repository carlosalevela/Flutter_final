import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/skin_analysis_model.dart';

abstract class GroqDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class GroqDataSourceImpl implements GroqDataSource {
  final http.Client client;

  /// Modelo principal (puedes cambiarlo aquí o inyectarlo por constructor)
  static const String _DEFAULT_MODEL = 'meta-llama/llama-4-scout-17b-16e-instruct';

  /// Candidatos de respaldo por si uno está deprecado
  static const List<String> _FALLBACK_MODELS = <String>[
    'llama-3.2-11b-vision-preview',
    'llama-3.2-90b-vision-preview', // por si sigue activo en tu cuenta
  ];

  /// Permite sobreescribir el modelo desde el lugar donde instancies el datasource,
  /// pero **no** desde .env (según lo que pediste).
  final String _modelOverride;

  GroqDataSourceImpl({
    required this.client,
    String? model, // opcional
  }) : _modelOverride = model ?? _DEFAULT_MODEL;

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      // API Key desde .env (solo la key queda en .env)
      final apiKey = dotenv.env['GROQ_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key de Groq no configurada');
      }

      final prompt = _buildDermatologyPrompt();

      // Lista efectiva de modelos a intentar: override primero + fallbacks únicos
      final modelsToTry = <String>{
        _modelOverride,
        ..._FALLBACK_MODELS,
      }.toList();

      Exception? lastErr;

      for (final model in modelsToTry) {
        try {
          final body = jsonEncode({
            'model': model,
            'messages': [
              {
                'role': 'user',
                'content': [
                  {'type': 'text', 'text': prompt},
                  {
                    'type': 'image_url',
                    'image_url': {'url': 'data:image/jpeg;base64,$base64Image'}
                  }
                ]
              }
            ],
            'temperature': 0.5,
            'max_tokens': 1000,
          });

          final response = await client
              .post(
                Uri.parse('https://api.groq.com/openai/v1/chat/completions'),
                headers: {
                  'Authorization': 'Bearer $apiKey',
                  'Content-Type': 'application/json',
                },
                body: body,
              )
              .timeout(const Duration(seconds: 30));

          if (response.statusCode == 200) {
            final jsonResponse = jsonDecode(response.body);
            final responseText =
                jsonResponse['choices'][0]['message']['content'] as String;
            return SkinAnalysisModel.fromClaudeResponse(responseText);
          } else {
            // Si es un error claro de modelo, probamos el siguiente.
            final err = _safeJson(response.body);
            final code = err?['error']?['code']?.toString() ?? '';
            final message = err?['error']?['message']?.toString() ??
                response.body;

            final isModelIssue = code.contains('model_not_found') ||
                message.toLowerCase().contains('decommission') ||
                message.toLowerCase().contains('no longer supported');

            if (!isModelIssue) {
              // No es tema de modelo → salimos con este error.
              throw Exception('Groq API ($code): $message');
            }

            // Guardamos y seguimos con el siguiente modelo.
            lastErr = Exception('Groq API ($code): $message');
            continue;
          }
        } catch (e) {
          // Guardamos el último error e intentamos el siguiente modelo
          lastErr = Exception(e.toString());
          continue;
        }
      }

      // Si llegamos aquí, ningún modelo funcionó
      throw Exception(
        'Ningún modelo disponible respondió correctamente. '
        'Revisa que el/los modelos de visión estén activos en tu cuenta de Groq. '
        'Último error: ${lastErr?.toString() ?? 'desconocido'}.',
      );
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } on http.ClientException {
      throw Exception('Error de conexión con el servidor');
    } catch (e) {
      throw Exception('Error al analizar la imagen: $e');
    }
  }

  Map<String, dynamic>? _safeJson(String body) {
    try {
      return jsonDecode(body) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  String _buildDermatologyPrompt() {
  return '''
Eres un asistente clínico de dermatología. Analiza **solo la imagen** proporcionada y responde en español siguiendo **exactamente** el formato indicado al final (sin texto extra). No incluyas advertencias legales, solo el contenido solicitado.

INSTRUCCIONES CLÍNICAS
1) Diagnóstico preliminar:
   - Propón la condición cutánea más probable (p. ej., acné inflamatorio, dermatitis atópica, eczema de contacto, psoriasis en placa, queratosis seborreica, foliculitis, impétigo, herpes simple, verruga vulgar, melasma, nevo melanocítico, lesión pigmentada sospechosa, etc.).
   - Incluye 1–3 **diagnósticos diferenciales** si aplica.

2) Descripción objetiva (lo que ves en la imagen):
   - Color predominante y secundarios (eritema/hiperpigmentación/hipopigmentación).
   - Morfología/lesiones primarias (mácula, pápula, pústula, placa, nódulo, vesícula), patrón (agrupadas/lineales/dispersas).
   - Bordes (regulares/irregulares), simetría/asimetría.
   - Superficie (lisa, descamativa, costrosa, ulcerada), brillo.
   - Tamaño **estimado** (aprox. en mm/cm, si es inferible por referencia), y localización relativa en la imagen.

3) Nivel de riesgo (elige uno: BAJO, MEDIO o ALTO) aplicando estas reglas:
   - **ALTO** si observas cualquiera de:
     • Criterios ABCDE de melanoma: Asimetría marcada, Bordes irregulares/borrosos, Color múltiple/heterogéneo (negro/azul/blanco/rojo/marrón), Diámetro ≥6 mm (si es estimable) o crecimiento rápido, Evolución/cambio notorio.
     • Úlcera, sangrado espontáneo, costra hemorrágica persistente.
     • Signos de infección moderada-severa (pus abundante, celulitis evidente).
     • Lesión nodular dura de rápido crecimiento.
   - **MEDIO** si:
     • Lesión probablemente benigna pero con elementos atípicos leves (borde algo irregular, coloración mixta leve, prurito/dolor sugeridos por la imagen como rascado).
     • Lesiones inflamatorias extensas o en zona sensible (ojos, labios, genital).
   - **BAJO** si:
     • Patrones típicos de afecciones benignas comunes y autolimitadas (p. ej., acné leve, dermatitis irritativa leve, queratosis seborreica típica, melasma, verruga estable) **sin** signos de alarma anteriores.

4) Recomendaciones (3 ítems):
   - Deben ser **concretas y accionables** (cuidado de la piel, higiene, fotoprotección, emolientes, tratamientos OTC simples si procede — sin prescribir fármacos de receta).
   - Si el riesgo es ALTO, la primera recomendación debe ser **consulta prioritaria** con dermatología.

5) Requiere atención médica:
   - Responde **SÍ** si el riesgo es ALTO o si la lesión necesita evaluación presencial por criterios de duda diagnóstica relevante.
   - En caso contrario, **NO**.

ACLARACIONES
- No inventes datos que la imagen no soporte. Si algo no es inferible, dilo como "no evaluable en imagen".
- No uses lenguaje probabilístico vago: sé breve y directo.

FORMATO DE RESPUESTA (respeta exactamente encabezados y viñetas):
Diagnóstico preliminar: [condición más probable; incluye 1–3 diferenciales entre paréntesis si aplica]
Descripción: [color, morfología, bordes, simetría, superficie, tamaño aprox., distribución/localización relativa]
Nivel de riesgo: [BAJO/MEDIO/ALTO]
Recomendaciones:
- [recomendación 1]
- [recomendación 2]
- [recomendación 3]
Requiere atención médica: [SÍ/NO]
''';
}
}
