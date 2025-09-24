import 'package:flutter_test/flutter_test.dart';
import 'package:logging/logging.dart';

import 'package:barcode_scanner/core/errors/error_handler.dart';
import 'package:barcode_scanner/core/errors/error_reporter.dart';
import 'package:barcode_scanner/core/errors/app_exception.dart';
import 'package:barcode_scanner/core/errors/error_messages.dart';

void main() {
  group('Basic Error Handling', () {
    late Logger logger;
    late ErrorReporter errorReporter;
    late ErrorHandler errorHandler;

    setUp(() {
      logger = Logger('test');
      errorReporter = ErrorReporter(logger: logger);
      errorHandler = ErrorHandler(
        errorReporter: errorReporter,
        logger: logger,
      );
    });

    test('should create ErrorHandler instance', () {
      expect(errorHandler, isNotNull);
      expect(errorHandler, isA<ErrorHandler>());
    });

    test('should categorize error severity correctly', () {
      expect(errorHandler.isCriticalError(DatabaseException('error')), isTrue);
      expect(errorHandler.isCriticalError(AuthException('error')), isTrue);
      expect(errorHandler.isCriticalError(NetworkException('error')), isFalse);
      expect(
          errorHandler.isCriticalError(ValidationException('error')), isFalse);
      expect(errorHandler.isCriticalError(Exception('generic')), isFalse);
    });

    test('should provide error recovery suggestions', () {
      final networkError = NetworkException('Connection timeout');
      final authError = AuthException('Token expired');
      final validationError = ValidationException('Invalid input');

      expect(
          errorHandler.getRecoverySuggestion(networkError), contains('ネットワーク'));
      expect(errorHandler.getRecoverySuggestion(authError), contains('ログイン'));
      expect(
          errorHandler.getRecoverySuggestion(validationError), contains('入力'));
    });

    test('should provide user-friendly messages', () {
      expect(errorHandler.getUserFriendlyMessage(NetworkException('error')),
          equals('ネットワークエラー'));
      expect(errorHandler.getUserFriendlyMessage(AuthException('error')),
          equals('認証エラー'));
      expect(errorHandler.getUserFriendlyMessage(ValidationException('error')),
          equals('入力エラー'));
    });

    test('should handle basic error reporting', () async {
      final exception = NetworkException('Connection failed');

      // Should not throw
      await errorHandler.handleError(
        exception,
        context: 'Test context',
      );
    });
  });

  group('ErrorReporter Basic Functionality', () {
    late Logger logger;
    late ErrorReporter errorReporter;

    setUp(() {
      logger = Logger('test');
      errorReporter = ErrorReporter(logger: logger);
    });

    test('should classify error severity correctly', () {
      expect(errorReporter.getErrorSeverity(NetworkException('error')),
          ErrorSeverity.warning);
      expect(errorReporter.getErrorSeverity(AuthException('error')),
          ErrorSeverity.error);
      expect(errorReporter.getErrorSeverity(DatabaseException('error')),
          ErrorSeverity.critical);
      expect(errorReporter.getErrorSeverity(ValidationException('error')),
          ErrorSeverity.info);
    });

    test('should add and retrieve breadcrumbs', () {
      errorReporter.addBreadcrumb('User opened app');
      errorReporter.addBreadcrumb('User navigated to scanner');
      errorReporter.addBreadcrumb('User scanned barcode');

      final breadcrumbs = errorReporter.getBreadcrumbs();
      expect(breadcrumbs, hasLength(3));
      expect(breadcrumbs.last['message'], equals('User scanned barcode'));
      expect(breadcrumbs.first['message'], equals('User opened app'));
    });

    test('should manage user context', () {
      errorReporter.setUserContext(
        userId: 'user123',
        email: 'test@example.com',
        name: 'Test User',
      );

      final userContext = errorReporter.getUserContext();
      expect(userContext['userId'], equals('user123'));
      expect(userContext['email'], equals('test@example.com'));
      expect(userContext['name'], equals('Test User'));

      errorReporter.clearUserContext();
      expect(errorReporter.getUserContext(), isEmpty);
    });

    test('should format error for reporting', () {
      final exception = ApiException('API Error', statusCode: 500);
      const context = 'Product fetch';

      final formatted = errorReporter.formatErrorForReporting(
        exception,
        context: context,
        fatal: true,
      );

      expect(formatted['error'], contains('API Error'));
      expect(formatted['error_type'], equals('ApiException'));
      expect(formatted['status_code'], equals(500));
      expect(formatted['context'], equals(context));
      expect(formatted['fatal'], isTrue);
      expect(formatted['timestamp'], isNotNull);
    });

    test('should collect device info', () async {
      final deviceInfo = await errorReporter.collectDeviceInfo();

      expect(deviceInfo, isNotNull);
      expect(deviceInfo['platform'], isNotNull);
    });
  });

  group('AppException Types', () {
    test('should create different exception types', () {
      final networkException = NetworkException('Network error');
      final authException = AuthException('Auth error');
      final databaseException = DatabaseException('DB error');
      final validationException = ValidationException('Validation error');
      final scannerException = ScannerException('Scanner error');
      final apiException = ApiException('API error', statusCode: 404);

      expect(networkException, isA<NetworkException>());
      expect(authException, isA<AuthException>());
      expect(databaseException, isA<DatabaseException>());
      expect(validationException, isA<ValidationException>());
      expect(scannerException, isA<ScannerException>());
      expect(apiException, isA<ApiException>());

      expect(apiException.statusCode, equals(404));
    });

    test('should provide proper string representation', () {
      final apiException = ApiException('Server error', statusCode: 500);
      expect(apiException.toString(),
          contains('ApiException: Server error (Status: 500)'));
    });
  });
}
