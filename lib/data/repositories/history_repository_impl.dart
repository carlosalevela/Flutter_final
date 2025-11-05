import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/skin_analysis_history_entity.dart';
import '../../domain/repositories/history_repository.dart';
import '../datasources/history_datasource.dart';

class HistoryRepositoryImpl implements HistoryRepository {
  final HistoryDataSource dataSource;

  HistoryRepositoryImpl({required this.dataSource});

  @override
  Future<Either<Failure, List<SkinAnalysisHistoryEntity>>> getHistory() async {
    try {
      final history = await dataSource.getHistory();
      return Right(history);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> saveAnalysis({
    required String imageUrl,
    required String diagnosis,
    required String description,
    required String riskLevel,
    required List<String> recommendations,
    required bool requiresMedicalAttention,
  }) async {
    try {
      await dataSource.saveAnalysis(
        imageUrl: imageUrl,
        diagnosis: diagnosis,
        description: description,
        riskLevel: riskLevel,
        recommendations: recommendations,
        requiresMedicalAttention: requiresMedicalAttention,
      );
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }

  @override
  Future<Either<Failure, void>> deleteAnalysis(String analysisId) async {
    try {
      await dataSource.deleteAnalysis(analysisId);
      return const Right(null);
    } catch (e) {
      return Left(ServerFailure(e.toString()));
    }
  }
}