import 'dart:io';
import 'package:dartz/dartz.dart';
import '../../core/errors/failures.dart';
import '../../domain/entities/skin_analysis_entity.dart';
import '../../domain/repositories/skin_analysis_repository.dart';
import '../datasources/openai_datasource.dart'; // 👈 IMPORT DE OPENAI

class SkinAnalysisRepositoryImpl implements SkinAnalysisRepository {
  final OpenAIDataSource remoteDataSource; // 👈 TIPO OPENAI

  SkinAnalysisRepositoryImpl({
    required this.remoteDataSource,
  });

  @override
  Future<Either<Failure, SkinAnalysisEntity>> analyzeSkinImage(
    File imageFile,
  ) async {
    try {
      // Validar que el archivo existe
      if (!await imageFile.exists()) {
        return const Left(
          ValidationFailure('El archivo de imagen no existe'),
        );
      }

      // Validar el tamaño del archivo (máximo 5MB)
      final fileSizeInBytes = await imageFile.length();
      final fileSizeInMB = fileSizeInBytes / (1024 * 1024);
      
      if (fileSizeInMB > 5) {
        return const Left(
          ValidationFailure('La imagen es muy grande. Máximo 5MB'),
        );
      }

      // Validar que es una imagen
      final extension = imageFile.path.split('.').last.toLowerCase();
      final validExtensions = ['jpg', 'jpeg', 'png', 'gif', 'webp'];
      
      if (!validExtensions.contains(extension)) {
        return const Left(
          ValidationFailure('Formato de imagen no válido. Usa JPG, PNG o WebP'),
        );
      }

      // Llamar al datasource
      final result = await remoteDataSource.analyzeSkinImage(imageFile);
      
      return Right(result);
      
    } on SocketException {
      return const Left(
        ConnectionFailure('Sin conexión a internet. Verifica tu conexión'),
      );
    } catch (e) {
      // Clasificar el tipo de error
      if (e.toString().contains('API Key')) {
        return const Left(
          ServerFailure('Error de configuración. API Key no válida'),
        );
      } else if (e.toString().contains('timeout')) {
        return const Left(
          ConnectionFailure('Tiempo de espera agotado. Intenta de nuevo'),
        );
      } else if (e.toString().contains('OpenAI')) {
        return Left(
          AIFailure('Error del servicio de IA: ${e.toString()}'),
        );
      } else {
        return Left(
          ServerFailure('Error inesperado: ${e.toString()}'),
        );
      }
    }
  }
}