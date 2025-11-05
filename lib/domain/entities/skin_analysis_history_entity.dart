import 'package:equatable/equatable.dart';

class SkinAnalysisHistoryEntity extends Equatable {
  final String id;
  final String userId;
  final String imageUrl;
  final String diagnosis;
  final String description;
  final String riskLevel;
  final List<String> recommendations;
  final bool requiresMedicalAttention;
  final DateTime createdAt;

  const SkinAnalysisHistoryEntity({
    required this.id,
    required this.userId,
    required this.imageUrl,
    required this.diagnosis,
    required this.description,
    required this.riskLevel,
    required this.recommendations,
    required this.requiresMedicalAttention,
    required this.createdAt,
  });

  @override
  List<Object?> get props => [
        id,
        userId,
        imageUrl,
        diagnosis,
        description,
        riskLevel,
        recommendations,
        requiresMedicalAttention,
        createdAt,
      ];
}