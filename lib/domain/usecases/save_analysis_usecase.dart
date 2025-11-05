import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/history_repository.dart';

class SaveAnalysisUseCase {
  final HistoryRepository repository;

  SaveAnalysisUseCase(this.repository);

  Future<Either<Failure, void>> call({
    required String imageUrl,
    required String diagnosis,
    required String description,
    required String riskLevel,
    required List<String> recommendations,
    required bool requiresMedicalAttention,
  }) async {
    return await repository.saveAnalysis(
      imageUrl: imageUrl,
      diagnosis: diagnosis,
      description: description,
      riskLevel: riskLevel,
      recommendations: recommendations,
      requiresMedicalAttention: requiresMedicalAttention,
    );
  }
}