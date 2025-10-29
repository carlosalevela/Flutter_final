import 'package:equatable/equatable.dart';

class SkinAnalysisEntity extends Equatable {
  final String diagnosis;
  final String description;
  final String riskLevel; // low, medium, high
  final List<String> recommendations;
  final bool requiresMedicalAttention;

  const SkinAnalysisEntity({
    required this.diagnosis,
    required this.description,
    required this.riskLevel,
    required this.recommendations,
    required this.requiresMedicalAttention,
  });

  @override
  List<Object?> get props => [
        diagnosis,
        description,
        riskLevel,
        recommendations,
        requiresMedicalAttention,
      ];
}