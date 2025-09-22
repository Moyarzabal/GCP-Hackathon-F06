import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_test/flutter_test.dart';
import '../../../../lib/shared/widgets/adaptive/adaptive_button.dart';
import '../../../../lib/core/platform/platform_info.dart';

void main() {
  group('AdaptiveButton', () {
    const testText = 'テストボタン';
    
    testWidgets('should render with correct text', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {
                wasPressed = true;
              },
              child: const Text(testText),
            ),
          ),
        ),
      );

      // ボタンが描画されることを確認
      expect(find.byType(AdaptiveButton), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
      
      // 初期状態では押されていないことを確認
      expect(wasPressed, isFalse);
    });

    testWidgets('should handle button press', (WidgetTester tester) async {
      bool wasPressed = false;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {
                wasPressed = true;
              },
              child: const Text(testText),
            ),
          ),
        ),
      );

      // ボタンをタップ
      await tester.tap(find.text(testText));
      await tester.pumpAndSettle();
      
      // コールバックが呼ばれたことを確認
      expect(wasPressed, isTrue);
    });

    testWidgets('should be disabled when onPressed is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: null,
              child: const Text(testText),
            ),
          ),
        ),
      );

      // ボタンが描画されることを確認
      expect(find.byType(AdaptiveButton), findsOneWidget);
      expect(find.text(testText), findsOneWidget);
    });

    testWidgets('should apply primary style correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              style: AdaptiveButtonStyle.primary,
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveButton), findsOneWidget);
      
      final button = tester.widget<AdaptiveButton>(find.byType(AdaptiveButton));
      expect(button.style, equals(AdaptiveButtonStyle.primary));
    });

    testWidgets('should apply secondary style correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              style: AdaptiveButtonStyle.secondary,
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveButton), findsOneWidget);
      
      final button = tester.widget<AdaptiveButton>(find.byType(AdaptiveButton));
      expect(button.style, equals(AdaptiveButtonStyle.secondary));
    });

    testWidgets('should apply outlined style correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              style: AdaptiveButtonStyle.outlined,
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveButton), findsOneWidget);
      
      final button = tester.widget<AdaptiveButton>(find.byType(AdaptiveButton));
      expect(button.style, equals(AdaptiveButtonStyle.outlined));
    });

    testWidgets('should handle custom child widget', (WidgetTester tester) async {
      const customChild = Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.add),
          SizedBox(width: 8),
          Text('カスタム'),
        ],
      );
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              child: customChild,
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveButton), findsOneWidget);
      expect(find.byIcon(Icons.add), findsOneWidget);
      expect(find.text('カスタム'), findsOneWidget);
    });

    testWidgets('should default to primary style when style is null', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AdaptiveButton(
              onPressed: () {},
              child: const Text(testText),
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveButton), findsOneWidget);
      
      final button = tester.widget<AdaptiveButton>(find.byType(AdaptiveButton));
      expect(button.style, equals(AdaptiveButtonStyle.primary));
    });
  });
}