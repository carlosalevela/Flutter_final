import 'dart:convert';
import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import '../models/skin_analysis_model.dart';

abstract class OpenAIDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class OpenAIDataSourceImpl implements OpenAIDataSource {
  final http.Client client;

  OpenAIDataSourceImpl({required this.client});

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      final apiKey = dotenv.env['OPENAI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key de OpenAI no configurada');
      }

      // Leer y convertir imagen a base64
      final imageBytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(imageBytes);

      final prompt = _buildDermatologyPrompt();

      final body = jsonEncode({
        'model': 'gpt-4o-mini',  // Modelo más económico con visión
        'messages': [
          {
            'role': 'user',
            'content': [
              {'type': 'text', 'text': prompt},
              {
                'type': 'image_url',
                'image_url': {
                  'url': 'data:image/jpeg;base64,$base64Image',
                }
              }
            ]
          }
        ],
        'max_tokens': 500
      });

      final response = await client.post(
        Uri.parse('https://api.openai.com/v1/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: body,
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        final responseText =
            jsonResponse['choices'][0]['message']['content'] as String;

        return SkinAnalysisModel.fromClaudeResponse(responseText);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(
            'Error de OpenAI: ${error['error']?['message'] ?? response.body}');
      }
    } on SocketException {
      throw Exception('Sin conexión a internet');
    } catch (e) {
      throw Exception('Error al analizar la imagen: $e');
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