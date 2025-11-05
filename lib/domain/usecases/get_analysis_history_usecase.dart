import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/skin_analysis_history_entity.dart';
import '../repositories/history_repository.dart';

class GetAnalysisHistoryUseCase {
  final HistoryRepository repository;

  GetAnalysisHistoryUseCase(this.repository);

  Future<Either<Failure, List<SkinAnalysisHistoryEntity>>> call() async {
    return await repository.getHistory();
  }
}