import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/widgets/error_display.dart';
import '../../../lib/core/errors/app_exception.dart';

void main() {
  group('Simple ErrorDisplay Tests', () {
    testWidgets('should display error display widget', (tester) async {
      // Arrange
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
            ),
          ),
        ),
      );

      // Assert
      expect(find.byType(ErrorDisplay), findsOneWidget);
      expect(find.text('ネットワークエラー'), findsOneWidget);
    });

    testWidgets('should show retry button when onRetry is provided', (tester) async {
      // Arrange
      bool retryPressed = false;
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              onRetry: () {
                retryPressed = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('再試行'), findsOneWidget);

      await tester.tap(find.text('再試行'));
      expect(retryPressed, isTrue);
    });

    testWidgets('should hide retry button when onRetry is null', (tester) async {
      // Arrange
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(error: error),
          ),
        ),
      );

      // Assert
      expect(find.text('再試行'), findsNothing);
    });

    testWidgets('should display appropriate icons for different error types', (tester) async {
      // Test NetworkException icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(error: NetworkException('Network error')),
          ),
        ),
      );
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);

      // Test AuthException icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(error: AuthException('Auth error')),
          ),
        ),
      );
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });
  });

  group('InlineErrorDisplay', () {
    testWidgets('should display inline error message', (tester) async {
      // Arrange
      const error = ValidationException('Invalid email format');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorDisplay(error: error),
          ),
        ),
      );

      // Assert - Using the error's toString representation
      expect(find.textContaining('Invalid email format'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show dismiss button when onDismiss is provided', (tester) async {
      // Arrange
      bool dismissCalled = false;
      const error = ValidationException('Validation error');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorDisplay(
              error: error,
              onDismiss: () {
                dismissCalled = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsOneWidget);
      
      await tester.tap(find.byIcon(Icons.close));
      expect(dismissCalled, isTrue);
    });
  });
}