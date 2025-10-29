import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/skin_analysis_entity.dart';

abstract class SkinAnalysisRepository {
  Future<Either<Failure, SkinAnalysisEntity>> analyzeSkinImage(File imageFile);
}