import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:logging/logging.dart';
import 'dart:async';

import 'package:barcode_scanner/core/errors/error_handler.dart';
import 'package:barcode_scanner/core/errors/app_exception.dart';
import 'package:barcode_scanner/core/errors/error_reporter.dart';

import 'error_handler_test.mocks.dart';

@GenerateMocks([ErrorReporter, Logger])
void main() {
  group('ErrorHandler', () {
    late ErrorHandler errorHandler;
    late MockErrorReporter mockErrorReporter;
    late MockLogger mockLogger;

    setUp(() {
      mockErrorReporter = MockErrorReporter();
      mockLogger = MockLogger();
      errorHandler = ErrorHandler(
        errorReporter: mockErrorReporter,
        logger: mockLogger,
      );

      final originalPresentError = FlutterError.presentError;
      addTearDown(() {
        FlutterError.onError = FlutterError.dumpErrorToConsole;
        PlatformDispatcher.instance.onError = null;
        FlutterError.presentError = originalPresentError;
      });

      FlutterError.presentError = (_) {};
    });

    group('initialize', () {
      test('should set up Flutter error handlers', () {
        // Act
        errorHandler.initialize();

        // Assert
        expect(FlutterError.onError, isNotNull);
        expect(PlatformDispatcher.instance.onError, isNotNull);
      });
    });

    group('handleFlutterError', () {
      test('should log error and report to error reporter', () async {
        // Arrange
        final flutterError = FlutterErrorDetails(
          exception: Exception('Test Flutter error'),
          stack: StackTrace.current,
          context: ErrorDescription('Test context'),
        );

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {});

        // Act
        await errorHandler.handleFlutterError(flutterError);

        // Assert
        verify(mockLogger.severe(
          argThat(allOf(
              startsWith('Flutter Error'), contains('Test Flutter error'))),
          any,
          any,
        )).called(1);

        verify(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: 'Flutter Error: Test context',
          fatal: false,
        )).called(1);
      });

      test('should handle errors with null stack trace', () async {
        // Arrange
        final flutterError = FlutterErrorDetails(
          exception: Exception('Test error'),
        );

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {});

        // Act
        await errorHandler.handleFlutterError(flutterError);

        // Assert
        verify(mockErrorReporter.reportError(
          any,
          stackTrace: null,
          context: 'Flutter Error',
          fatal: false,
        )).called(1);
      });
    });

    group('handleAsyncError', () {
      test('should log and report async errors', () async {
        // Arrange
        final exception = NetworkException('Connection failed');
        final stackTrace = StackTrace.current;

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {});

        // Act
        await errorHandler.handleAsyncError(exception, stackTrace);

        // Assert
        verify(mockLogger.severe(
          argThat(
              allOf(startsWith('Async Error'), contains('Connection failed'))),
          exception,
          stackTrace,
        )).called(1);

        verify(mockErrorReporter.reportError(
          exception,
          stackTrace: stackTrace,
          context: 'Async Error',
          fatal: false,
        )).called(1);
      });

      test('should mark critical errors as fatal', () async {
        // Arrange
        final exception = DatabaseException('Database corrupted');
        final stackTrace = StackTrace.current;

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {});

        // Act
        await errorHandler.handleAsyncError(exception, stackTrace);

        // Assert
        verify(mockErrorReporter.reportError(
          exception,
          stackTrace: stackTrace,
          context: 'Async Error',
          fatal: true,
        )).called(1);
      });
    });

    group('handleError', () {
      test('should handle generic errors with context', () async {
        // Arrange
        final error = Exception('Generic error');
        final stackTrace = StackTrace.current;
        const context = 'User action';

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {});

        // Act
        await errorHandler.handleError(
          error,
          stackTrace: stackTrace,
          context: context,
        );

        // Assert
        verify(mockLogger.warning(
          argThat(allOf(startsWith('Error'), contains('Generic error'),
              contains('User action'))),
          error,
          stackTrace,
        )).called(1);

        verify(mockErrorReporter.reportError(
          error,
          stackTrace: stackTrace,
          context: context,
          fatal: false,
        )).called(1);
      });

      test('should categorize error severity correctly', () {
        // Test error categorization
        expect(
            errorHandler.isCriticalError(DatabaseException('error')), isTrue);
        expect(errorHandler.isCriticalError(AuthException('error')), isTrue);
        expect(
            errorHandler.isCriticalError(NetworkException('error')), isFalse);
        expect(errorHandler.isCriticalError(ValidationException('error')),
            isFalse);
        expect(errorHandler.isCriticalError(Exception('generic')), isFalse);
      });
    });

    group('error recovery', () {
      test('should provide error recovery suggestions', () {
        final networkError = NetworkException('Connection timeout');
        final authError = AuthException('Token expired');
        final validationError = ValidationException('Invalid input');

        expect(errorHandler.getRecoverySuggestion(networkError),
            contains('ネットワーク'));
        expect(errorHandler.getRecoverySuggestion(authError), contains('ログイン'));
        expect(errorHandler.getRecoverySuggestion(validationError),
            contains('入力'));
      });
    });

    group('zone error handling', () {
      test('should catch and handle zone errors', () async {
        // Arrange
        var errorCaught = false;

        when(mockErrorReporter.reportError(
          any,
          stackTrace: anyNamed('stackTrace'),
          context: anyNamed('context'),
          fatal: anyNamed('fatal'),
        )).thenAnswer((_) async {
          errorCaught = true;
        });

        errorHandler.initialize();

        // Act
        runZonedGuarded(() {
          Future.microtask(() => throw Exception('Zone error test'));
        }, (error, stack) {
          errorHandler.handleAsyncError(error, stack);
        });

        // Wait for async operations to complete
        await Future.delayed(const Duration(milliseconds: 50));

        // Assert
        expect(errorCaught, isTrue);
      });
    });
  });
}
