import 'package:dartz/dartz.dart';
import '../../../core/errors/failures.dart';
import '../../entities/auth/user_entity.dart';
import '../../repositories/auth/auth_repository.dart';

class SignUpUseCase {
  final AuthRepository repository;

  SignUpUseCase(this.repository);

  Future<Either<Failure, UserEntity>> call({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return await repository.signUpWithEmailAndPassword(
      email: email,
      password: password,
      fullName: fullName,
    );
  }
}