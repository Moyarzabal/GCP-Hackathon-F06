/// アプリケーション固有の例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;
  final int? errorCode;

  const AppException(
    this.message, {
    this.details,
    this.stackTrace,
    this.errorCode,
  });

  @override
  String toString() {
    final parts = ['${runtimeType}: $message'];
    if (errorCode != null) parts.add('(Code: $errorCode)');
    if (details != null) parts.add('($details)');
    return parts.join(' ');
  }
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException(super.message,
      {super.details, super.stackTrace, super.errorCode});
}

/// 認証関連の例外
class AuthException extends AppException {
  const AuthException(super.message,
      {super.details, super.stackTrace, super.errorCode});
}

/// データベース関連の例外
class DatabaseException extends AppException {
  const DatabaseException(super.message,
      {super.details, super.stackTrace, super.errorCode});
}

/// バリデーション例外
class ValidationException extends AppException {
  const ValidationException(super.message,
      {super.details, super.stackTrace, super.errorCode});
}

/// カメラ/スキャナー関連の例外
class ScannerException extends AppException {
  const ScannerException(super.message,
      {super.details, super.stackTrace, super.errorCode});
}

/// API関連の例外
class ApiException extends AppException {
  final int? statusCode;

  const ApiException(super.message,
      {this.statusCode, super.details, super.stackTrace, super.errorCode});

  @override
  String toString() {
    final parts = ['ApiException: $message'];
    if (statusCode != null) parts.add('(Status: $statusCode)');
    if (errorCode != null) parts.add('(Code: $errorCode)');
    if (details != null) parts.add('($details)');
    return parts.join(' ');
  }
}
