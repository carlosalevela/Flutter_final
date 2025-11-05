import '../../domain/entities/skin_analysis_history_entity.dart';

class AnalysisHistoryModel extends SkinAnalysisHistoryEntity {
  const AnalysisHistoryModel({
    required super.id,
    required super.userId,
    required super.imageUrl,
    required super.diagnosis,
    required super.description,
    required super.riskLevel,
    required super.recommendations,
    required super.requiresMedicalAttention,
    required super.createdAt,
  });

  factory AnalysisHistoryModel.fromJson(Map<String, dynamic> json) {
    return AnalysisHistoryModel(
      id: json['id'],
      userId: json['user_id'],
      imageUrl: json['image_url'],
      diagnosis: json['diagnosis'],
      description: json['description'],
      riskLevel: json['risk_level'],
      recommendations: List<String>.from(json['recommendations']),
      requiresMedicalAttention: json['requires_medical_attention'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'image_url': imageUrl,
      'diagnosis': diagnosis,
      'description': description,
      'risk_level': riskLevel,
      'recommendations': recommendations,
      'requires_medical_attention': requiresMedicalAttention,
      'created_at': createdAt.toIso8601String(),
    };
  }
}