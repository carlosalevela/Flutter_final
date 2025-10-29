import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../entities/skin_analysis_entity.dart';
import '../repositories/skin_analysis_repository.dart';

class AnalyzeSkinImage {
  final SkinAnalysisRepository repository;

  AnalyzeSkinImage(this.repository);

  Future<Either<Failure, SkinAnalysisEntity>> call(File imageFile) async {
    return await repository.analyzeSkinImage(imageFile);
  }
}