/// Base class for all failures
abstract class Failure {
  final String message;
  final String? code;
  final dynamic originalError;

  const Failure({
    required this.message,
    this.code,
    this.originalError,
  });

  @override
  String toString() =>
      'Failure: $message${code != null ? ' (Code: $code)' : ''}';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Failure &&
          runtimeType == other.runtimeType &&
          message == other.message &&
          code == other.code;

  @override
  int get hashCode => message.hashCode ^ code.hashCode;
}

/// Network-related failures
class NetworkFailure extends Failure {
  const NetworkFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Database-related failures
class DatabaseFailure extends Failure {
  const DatabaseFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Cache-related failures
class CacheFailure extends Failure {
  const CacheFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Validation-related failures
class ValidationFailure extends Failure {
  const ValidationFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Not found failures
class NotFoundFailure extends Failure {
  const NotFoundFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Authentication-related failures
class AuthFailure extends Failure {
  const AuthFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}

/// Server-related failures
class ServerFailure extends Failure {
  const ServerFailure({
    required String message,
    String? code,
    dynamic originalError,
  }) : super(message: message, code: code, originalError: originalError);
}
