import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/widgets/error_boundary.dart';
import '../../../lib/core/errors/app_exception.dart';

class ThrowingWidget extends StatelessWidget {
  final Exception? exception;

  const ThrowingWidget({Key? key, this.exception}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (exception != null) {
      throw exception!;
    }
    return const Text('Normal Widget');
  }
}

void main() {
  group('ErrorBoundary', () {
    testWidgets('should render child when no error occurs', (tester) async {
      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: const ThrowingWidget(),
          ),
        ),
      );

      // Assert
      expect(find.text('Normal Widget'), findsOneWidget);
    });

    testWidgets('should catch and display error when child throws', (tester) async {
      // Arrange
      final exception = NetworkException('Test error');

      // Act & Assert
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      // Should show error display instead of crashing
      expect(find.text('Normal Widget'), findsNothing);
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('Test error'), findsOneWidget);
    });

    testWidgets('should call onError callback when error occurs', (tester) async {
      // Arrange
      Exception? capturedError;
      StackTrace? capturedStackTrace;
      final exception = ValidationException('Validation failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (error, stackTrace) {
              capturedError = error as Exception;
              capturedStackTrace = stackTrace;
            },
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      // Assert
      expect(capturedError, isNotNull);
      expect(capturedError?.toString(), contains('Validation failed'));
      expect(capturedStackTrace, isNotNull);
    });

    testWidgets('should allow custom error widget', (tester) async {
      // Arrange
      final exception = AuthException('Auth failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            errorWidgetBuilder: (error, stackTrace) {
              return const Text('Custom Error Widget');
            },
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      // Assert
      expect(find.text('Custom Error Widget'), findsOneWidget);
    });

    testWidgets('should reset error state when child changes', (tester) async {
      // Arrange
      final exception = NetworkException('Network error');

      // Act - First render with error
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      expect(find.text('エラーが発生しました'), findsOneWidget);

      // Act - Re-render with normal child
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: const ThrowingWidget(),
          ),
        ),
      );

      // Assert
      expect(find.text('Normal Widget'), findsOneWidget);
      expect(find.text('エラーが発生しました'), findsNothing);
    });

    testWidgets('should provide retry functionality', (tester) async {
      // Arrange
      bool retryPressed = false;
      final exception = NetworkException('Network timeout');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onRetry: () {
              retryPressed = true;
            },
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));

      // Assert
      expect(retryPressed, isTrue);
    });

    testWidgets('should handle different error types with appropriate messages', (tester) async {
      // Test NetworkException
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: ThrowingWidget(exception: NetworkException('Network error')),
          ),
        ),
      );
      expect(find.text('ネットワークエラー'), findsOneWidget);

      // Test AuthException
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: ThrowingWidget(exception: AuthException('Auth error')),
          ),
        ),
      );
      expect(find.text('認証エラー'), findsOneWidget);

      // Test DatabaseException
      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            child: ThrowingWidget(exception: DatabaseException('Database error')),
          ),
        ),
      );
      expect(find.text('データエラー'), findsOneWidget);
    });

    testWidgets('should prevent error boundary from crashing the app', (tester) async {
      // Arrange
      final multipleExceptions = [
        NetworkException('Error 1'),
        AuthException('Error 2'),
        DatabaseException('Error 3'),
      ];

      // Act & Assert - Multiple errors should not crash
      for (final exception in multipleExceptions) {
        await tester.pumpWidget(
          MaterialApp(
            home: ErrorBoundary(
              child: ThrowingWidget(exception: exception),
            ),
          ),
        );
        
        // Should show error display, not crash
        expect(find.text('エラーが発生しました'), findsOneWidget);
      }
    });

    testWidgets('should report errors to error handler', (tester) async {
      // This test would be more meaningful with a mock error handler
      // For now, we ensure the error boundary doesn't prevent error reporting
      
      bool errorReported = false;
      final exception = ApiException('API Error', statusCode: 500);

      await tester.pumpWidget(
        MaterialApp(
          home: ErrorBoundary(
            onError: (error, stackTrace) {
              errorReported = true;
            },
            child: ThrowingWidget(exception: exception),
          ),
        ),
      );

      expect(errorReported, isTrue);
    });
  });

  group('AsyncErrorBoundary', () {
    testWidgets('should handle async errors in FutureBuilder', (tester) async {
      // Arrange
      Future<String> failingFuture() async {
        throw NetworkException('Async network error');
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncErrorBoundary(
            child: FutureBuilder<String>(
              future: failingFuture(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  throw snapshot.error!;
                }
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(); // Wait for Future to complete

      // Assert
      expect(find.text('エラーが発生しました'), findsOneWidget);
      expect(find.text('Async network error'), findsOneWidget);
    });

    testWidgets('should handle async errors in StreamBuilder', (tester) async {
      // Arrange
      Stream<String> failingStream() async* {
        yield 'Initial data';
        throw AuthException('Async auth error');
      }

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: AsyncErrorBoundary(
            child: StreamBuilder<String>(
              stream: failingStream(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  throw snapshot.error!;
                }
                if (snapshot.hasData) {
                  return Text(snapshot.data!);
                }
                return const CircularProgressIndicator();
              },
            ),
          ),
        ),
      );

      await tester.pump(); // Initial render
      await tester.pump(); // Stream emits data
      await tester.pump(); // Stream throws error

      // Assert
      expect(find.text('認証エラー'), findsOneWidget);
    });
  });
}