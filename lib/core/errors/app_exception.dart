/// アプリケーション固有の例外クラス
abstract class AppException implements Exception {
  final String message;
  final String? details;
  final StackTrace? stackTrace;

  const AppException(this.message, {this.details, this.stackTrace});

  @override
  String toString() => 'AppException: $message${details != null ? ' ($details)' : ''}';
}

/// ネットワーク関連の例外
class NetworkException extends AppException {
  const NetworkException(super.message, {super.details, super.stackTrace});
}

/// 認証関連の例外
class AuthException extends AppException {
  const AuthException(super.message, {super.details, super.stackTrace});
}

/// データベース関連の例外
class DatabaseException extends AppException {
  const DatabaseException(super.message, {super.details, super.stackTrace});
}

/// バリデーション例外
class ValidationException extends AppException {
  const ValidationException(super.message, {super.details, super.stackTrace});
}

/// カメラ/スキャナー関連の例外
class ScannerException extends AppException {
  const ScannerException(super.message, {super.details, super.stackTrace});
}

/// API関連の例外
class ApiException extends AppException {
  final int? statusCode;
  
  const ApiException(super.message, {this.statusCode, super.details, super.stackTrace});
  
  @override
  String toString() => 'ApiException: $message${statusCode != null ? ' (Status: $statusCode)' : ''}${details != null ? ' ($details)' : ''}';
}