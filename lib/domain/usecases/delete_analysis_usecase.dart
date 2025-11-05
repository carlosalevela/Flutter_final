import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../repositories/history_repository.dart';

class DeleteAnalysisUseCase {
  final HistoryRepository repository;

  DeleteAnalysisUseCase(this.repository);

  Future<Either<Failure, void>> call(String analysisId) async {
    return await repository.deleteAnalysis(analysisId);
  }
}