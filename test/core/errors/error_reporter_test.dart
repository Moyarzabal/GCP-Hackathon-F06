import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logging/logging.dart';

import 'package:barcode_scanner/core/errors/error_reporter.dart';
import 'package:barcode_scanner/core/errors/app_exception.dart';
import 'package:barcode_scanner/core/errors/error_messages.dart';

import 'error_reporter_test.mocks.dart';

@GenerateMocks([Logger])
void main() {
  group('ErrorReporter', () {
    late ErrorReporter errorReporter;
    late MockLogger mockLogger;

    setUp(() {
      mockLogger = MockLogger();
      errorReporter = ErrorReporter(logger: mockLogger);
    });

    group('reportError', () {
      test('should report error with all metadata', () async {
        // Arrange
        final exception = NetworkException('Connection failed');
        final stackTrace = StackTrace.current;
        const context = 'API call';

        // Act
        await errorReporter.reportError(
          exception,
          stackTrace: stackTrace,
          context: context,
          fatal: false,
        );

        // Assert
        verify(mockLogger.severe(
          'Error reported: Connection failed',
          exception,
          stackTrace,
        )).called(1);
      });

      test('should classify error severity correctly', () {
        // Test severity classification
        expect(errorReporter.getErrorSeverity(NetworkException('error')),
               ErrorSeverity.warning);
        expect(errorReporter.getErrorSeverity(AuthException('error')),
               ErrorSeverity.error);
        expect(errorReporter.getErrorSeverity(DatabaseException('error')),
               ErrorSeverity.critical);
        expect(errorReporter.getErrorSeverity(ValidationException('error')),
               ErrorSeverity.info);
        expect(errorReporter.getErrorSeverity(Exception('generic')),
               ErrorSeverity.warning);
      });

      test('should collect device info for error context', () async {
        // Act
        final deviceInfo = await errorReporter.collectDeviceInfo();

        // Assert
        expect(deviceInfo, isNotNull);
        expect(deviceInfo['platform'], isNotNull);
        expect(deviceInfo['version'], isNotNull);
        expect(deviceInfo['locale'], isNotNull);
      });

      test('should format error for external reporting', () {
        // Arrange
        final exception = ApiException('API Error', statusCode: 500);
        final stackTrace = StackTrace.current;
        const context = 'Product fetch';

        // Act
        final formatted = errorReporter.formatErrorForReporting(
          exception,
          stackTrace: stackTrace,
          context: context,
          fatal: true,
        );

        // Assert
        expect(formatted['error'], contains('API Error'));
        expect(formatted['error_type'], equals('ApiException'));
        expect(formatted['status_code'], equals(500));
        expect(formatted['context'], equals(context));
        expect(formatted['fatal'], isTrue);
        expect(formatted['stack_trace'], isNotNull);
        expect(formatted['timestamp'], isNotNull);
      });

      test('should handle errors without stack trace', () async {
        // Arrange
        final exception = ValidationException('Invalid data');

        // Act
        await errorReporter.reportError(exception);

        // Assert
        verify(mockLogger.severe(
          'Error reported: Invalid data',
          exception,
          null,
        )).called(1);
      });
    });

    group('error filtering', () {
      test('should filter duplicate errors within time window', () async {
        // Arrange
        final exception = NetworkException('Same error');
        
        // Act
        await errorReporter.reportError(exception);
        await errorReporter.reportError(exception);
        await errorReporter.reportError(exception);

        // Assert - should only report once
        verify(mockLogger.severe(
          'Error reported: Same error',
          exception,
          null,
        )).called(1);
      });

      test('should not filter different errors', () async {
        // Arrange
        final error1 = NetworkException('Error 1');
        final error2 = NetworkException('Error 2');
        
        // Act
        await errorReporter.reportError(error1);
        await errorReporter.reportError(error2);

        // Assert - should report both
        verify(mockLogger.severe(
          'Error reported: Error 1',
          error1,
          null,
        )).called(1);
        
        verify(mockLogger.severe(
          'Error reported: Error 2',
          error2,
          null,
        )).called(1);
      });
    });

    group('breadcrumbs', () {
      test('should add and retrieve breadcrumbs', () {
        // Act
        errorReporter.addBreadcrumb('User opened app');
        errorReporter.addBreadcrumb('User navigated to scanner');
        errorReporter.addBreadcrumb('User scanned barcode');

        // Assert
        final breadcrumbs = errorReporter.getBreadcrumbs();
        expect(breadcrumbs, hasLength(3));
        expect(breadcrumbs.last['message'], equals('User scanned barcode'));
        expect(breadcrumbs.first['message'], equals('User opened app'));
      });

      test('should limit breadcrumb count', () {
        // Act - Add more than max breadcrumbs
        for (int i = 0; i < 25; i++) {
          errorReporter.addBreadcrumb('Breadcrumb $i');
        }

        // Assert
        final breadcrumbs = errorReporter.getBreadcrumbs();
        expect(breadcrumbs.length, lessThanOrEqualTo(20)); // Max limit
      });
    });

    group('user context', () {
      test('should set and get user context', () {
        // Act
        errorReporter.setUserContext(
          userId: 'user123',
          email: 'test@example.com',
          name: 'Test User',
        );

        // Assert
        final userContext = errorReporter.getUserContext();
        expect(userContext['userId'], equals('user123'));
        expect(userContext['email'], equals('test@example.com'));
        expect(userContext['name'], equals('Test User'));
      });

      test('should clear user context', () {
        // Arrange
        errorReporter.setUserContext(userId: 'user123');
        
        // Act
        errorReporter.clearUserContext();

        // Assert
        final userContext = errorReporter.getUserContext();
        expect(userContext, isEmpty);
      });
    });

    group('error tags', () {
      test('should set custom tags for error categorization', () {
        // Act
        errorReporter.setTag('feature', 'scanner');
        errorReporter.setTag('environment', 'production');

        // Assert
        final tags = errorReporter.getTags();
        expect(tags['feature'], equals('scanner'));
        expect(tags['environment'], equals('production'));
      });
    });

    group('performance tracking', () {
      test('should measure error reporting performance', () async {
        // Arrange
        final exception = NetworkException('Test error');
        
        // Act
        final stopwatch = Stopwatch()..start();
        await errorReporter.reportError(exception);
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThan(100));
      });
    });
  });
}
