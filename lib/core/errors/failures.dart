import 'package:equatable/equatable.dart';

abstract class Failure extends Equatable {
  final String message;

  const Failure(this.message);

  @override
  List<Object> get props => [message];
}

// Fallo del servidor
class ServerFailure extends Failure {
  const ServerFailure(super.message);
}

// Fallo de conexión
class ConnectionFailure extends Failure {
  const ConnectionFailure(super.message);
}

// Fallo de caché
class CacheFailure extends Failure {
  const CacheFailure(super.message);
}

// Fallo de validación
class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

// Fallo de la IA
class AIFailure extends Failure {
  const AIFailure(super.message);
}