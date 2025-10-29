import 'dart:convert';
import '../../domain/entities/skin_analysis_entity.dart';

class SkinAnalysisModel extends SkinAnalysisEntity {
  const SkinAnalysisModel({
    required super.diagnosis,
    required super.description,
    required super.riskLevel,
    required super.recommendations,
    required super.requiresMedicalAttention,
  });

  // Factory para crear desde JSON de Claude
  factory SkinAnalysisModel.fromClaudeResponse(String responseText) {
    try {
      // Claude devuelve texto, lo parseamos
      final lines = responseText.split('\n');
      
      String diagnosis = '';
      String description = '';
      String riskLevel = 'low';
      List<String> recommendations = [];
      bool requiresMedicalAttention = false;

      // Parsear la respuesta de Claude
      for (var line in lines) {
        if (line.toLowerCase().contains('diagnóstico') || 
            line.toLowerCase().contains('diagnosis')) {
          diagnosis = line.split(':').last.trim();
        } else if (line.toLowerCase().contains('descripción') || 
                   line.toLowerCase().contains('description')) {
          description = line.split(':').last.trim();
        } else if (line.toLowerCase().contains('riesgo') || 
                   line.toLowerCase().contains('risk')) {
          final risk = line.toLowerCase();
          if (risk.contains('alto') || risk.contains('high')) {
            riskLevel = 'high';
            requiresMedicalAttention = true;
          } else if (risk.contains('medio') || risk.contains('medium')) {
            riskLevel = 'medium';
          }
        } else if (line.toLowerCase().contains('recomendación') || 
                   line.toLowerCase().contains('recommendation')) {
          recommendations.add(line.split(':').last.trim());
        }
      }

      // Si contiene palabras clave que indican urgencia
      if (responseText.toLowerCase().contains('médico') ||
          responseText.toLowerCase().contains('doctor') ||
          responseText.toLowerCase().contains('urgente')) {
        requiresMedicalAttention = true;
      }

      return SkinAnalysisModel(
        diagnosis: diagnosis.isEmpty ? 'Análisis completado' : diagnosis,
        description: description.isEmpty ? responseText : description,
        riskLevel: riskLevel,
        recommendations: recommendations.isEmpty 
            ? ['Consulta con un profesional de la salud'] 
            : recommendations,
        requiresMedicalAttention: requiresMedicalAttention,
      );
    } catch (e) {
      throw Exception('Error al parsear respuesta de Claude: $e');
    }
  }

  // Convertir a JSON para guardar localmente si lo necesitas
  Map<String, dynamic> toJson() {
    return {
      'diagnosis': diagnosis,
      'description': description,
      'riskLevel': riskLevel,
      'recommendations': recommendations,
      'requiresMedicalAttention': requiresMedicalAttention,
    };
  }

  // Crear desde JSON local
  factory SkinAnalysisModel.fromJson(Map<String, dynamic> json) {
    return SkinAnalysisModel(
      diagnosis: json['diagnosis'] ?? '',
      description: json['description'] ?? '',
      riskLevel: json['riskLevel'] ?? 'low',
      recommendations: List<String>.from(json['recommendations'] ?? []),
      requiresMedicalAttention: json['requiresMedicalAttention'] ?? false,
    );
  }
}