import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/skin_analysis_model.dart';

abstract class HuggingFaceDataSource {
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile);
}

class HuggingFaceDataSourceImpl implements HuggingFaceDataSource {
  final http.Client client;

  HuggingFaceDataSourceImpl({required this.client});

  @override
  Future<SkinAnalysisModel> analyzeSkinImage(File imageFile) async {
    try {
      // Por ahora, retornamos un análisis simulado
      await Future.delayed(const Duration(seconds: 2));
      
      // Análisis simulado basado en patrones comunes
      return const SkinAnalysisModel(
        diagnosis: 'Análisis simulado - Activar API de pago',
        description: 'Para obtener análisis reales con IA, por favor configura tu método de pago en OpenAI. Este es un resultado de ejemplo que simula el funcionamiento de la aplicación.',
        riskLevel: 'low',
        recommendations: [
          'Configura tu método de pago en OpenAI',
          'Consulta con un dermatólogo para análisis real',
          'Mantén la piel hidratada',
        ],
        requiresMedicalAttention: false,
      );
    } catch (e) {
      throw Exception('Error al analizar: $e');
    }
  }
}