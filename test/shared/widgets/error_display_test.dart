import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../lib/shared/widgets/error_display.dart';
import '../../../lib/core/errors/app_exception.dart';

void main() {
  group('ErrorDisplay', () {
    testWidgets('should display basic error message', (tester) async {
      // Arrange
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.text('Connection failed'), findsOneWidget);
      expect(find.byIcon(Icons.wifi_off), findsOneWidget);
      expect(find.text('再試行'), findsOneWidget);
    });

    testWidgets('should display custom error message', (tester) async {
      // Arrange
      const error = ValidationException('Invalid input');
      const customMessage = 'カスタムエラーメッセージ';

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              message: customMessage,
              onRetry: () {},
            ),
          ),
        ),
      );

      // Assert
      expect(find.text(customMessage), findsOneWidget);
      expect(find.text('Invalid input'), findsOneWidget);
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

    testWidgets('should call onRetry when retry button is tapped', (tester) async {
      // Arrange
      bool retryCalled = false;
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.text('再試行'));

      // Assert
      expect(retryCalled, isTrue);
    });

    testWidgets('should display error details when showDetails is true', (tester) async {
      // Arrange
      const error = ApiException(
        'API Error',
        statusCode: 500,
        details: 'Internal server error',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              showDetails: true,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('詳細を表示'), findsOneWidget);
      
      // Tap to show details
      await tester.tap(find.text('詳細を表示'));
      await tester.pump();

      expect(find.text('Internal server error'), findsOneWidget);
      expect(find.text('Status: 500'), findsOneWidget);
    });

    testWidgets('should hide error details when showDetails is false', (tester) async {
      // Arrange
      const error = ApiException(
        'API Error',
        statusCode: 500,
        details: 'Internal server error',
      );

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              showDetails: false,
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('詳細を表示'), findsNothing);
      expect(find.text('Internal server error'), findsNothing);
    });

    testWidgets('should display appropriate icon for different error types', (tester) async {
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

      // Test DatabaseException icon
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(error: DatabaseException('Database error')),
          ),
        ),
      );
      expect(find.byIcon(Icons.storage), findsOneWidget);
    });

    testWidgets('should display localized error messages', (tester) async {
      // Arrange
      const error = NetworkException('Connection timeout');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          locale: const Locale('ja', 'JP'),
          home: Scaffold(
            body: ErrorDisplay(error: error),
          ),
        ),
      );

      // Assert
      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.text('インターネット接続を確認してください。'), findsOneWidget);
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

      // Assert
      expect(find.text('Invalid email format'), findsOneWidget);
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

    testWidgets('should hide dismiss button when onDismiss is null', (tester) async {
      // Arrange
      const error = ValidationException('Validation error');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: InlineErrorDisplay(error: error),
          ),
        ),
      );

      // Assert
      expect(find.byIcon(Icons.close), findsNothing);
    });
  });

  group('ErrorSnackBar', () {
    testWidgets('should display error snackbar widget', (tester) async {
      // Arrange
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: const ErrorSnackBar(error: error),
          ),
        ),
      );

      // Assert
      expect(find.text('ネットワークエラー'), findsOneWidget);
      expect(find.byIcon(Icons.error_outline), findsOneWidget);
    });

    testWidgets('should show retry action in snackbar', (tester) async {
      // Arrange
      bool retryCalled = false;
      const error = NetworkException('Connection failed');

      // Act
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: ErrorSnackBar(
              error: error,
              onRetry: () {
                retryCalled = true;
              },
            ),
          ),
        ),
      );

      // Assert
      expect(find.text('再試行'), findsOneWidget);
      
      await tester.tap(find.text('再試行'));
      expect(retryCalled, isTrue);
    });
  });
}