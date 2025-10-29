import 'dart:io';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../models/skin_analysis_model.dart';

abstract class GeminiAiDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class GeminiAiDataSourceImpl implements GeminiAiDataSource {
  GeminiAiDataSourceImpl();

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      // API Key desde .env
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        throw Exception('API Key de Gemini no configurada');
      }

      // Inicializar modelo - MODELO MÁS RECIENTE
      final model = GenerativeModel(
        model: 'gemini-1.5-flash',  // 👈 CAMBIAR A ESTE
        apiKey: apiKey,
      );

      // Leer imagen
      final imageBytes = await imageFile.readAsBytes();

      // Crear prompt
      final prompt = _buildDermatologyPrompt();

      // Crear contenido con imagen
      final content = [
        Content.multi([
          TextPart(prompt),
          DataPart('image/jpeg', imageBytes),
        ])
      ];

      // Generar respuesta
      final response = await model.generateContent(content);
      final responseText = response.text ?? '';

      if (responseText.isEmpty) {
        throw Exception('No se recibió respuesta de Gemini');
      }

      return SkinAnalysisModel.fromClaudeResponse(responseText);
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