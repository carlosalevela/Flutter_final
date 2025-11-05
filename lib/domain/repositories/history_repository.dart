import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/skin_analysis_history_entity.dart';

abstract class HistoryRepository {
  Future<Either<Failure, List<SkinAnalysisHistoryEntity>>> getHistory();
  
  Future<Either<Failure, void>> saveAnalysis({
    required String imageUrl,
    required String diagnosis,
    required String description,
    required String riskLevel,
    required List<String> recommendations,
    required bool requiresMedicalAttention,
  });
  
  Future<Either<Failure, void>> deleteAnalysis(String analysisId);
}