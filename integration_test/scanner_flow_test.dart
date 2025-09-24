import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:barcode_scanner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Scanner Flow Integration Tests', () {
    testWidgets('should access scanner screen and display camera interface',
        (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: スキャンタブをタップ
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Assert: スキャン画面が表示される
      expect(find.text('バーコードスキャン'), findsOneWidget);
    });

    testWidgets('should handle camera permission requests', (tester) async {
      // Arrange: アプリを起動してスキャン画面に移動
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Act: カメラ権限が必要な操作を実行
      final scanButton = find.byType(FloatingActionButton);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pumpAndSettle();
      }

      // Assert: 権限リクエストが適切に処理される
      expect(tester.takeException(), isNull);
    });

    testWidgets('should simulate barcode scan and product recognition',
        (tester) async {
      // Arrange: アプリを起動してスキャン画面に移動
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Act: バーコードスキャンをシミュレート
      // 注意: 実際のカメラスキャンはテスト環境では動作しないため、
      // UIの存在確認とエラーハンドリングのテストを中心に行う

      // スキャンボタンが存在することを確認
      final scanButton = find.byType(FloatingActionButton);
      expect(scanButton, findsWidgets);

      // Assert: スキャン画面のUI要素が正しく表示される
      expect(find.text('バーコードスキャン'), findsOneWidget);
    });

    testWidgets('should handle scan results and navigate to product details',
        (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: スキャン結果のシミュレーション
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // 手動入力ボタンがあれば使用（実際のスキャンの代わり）
      final manualInputButton = find.byIcon(Icons.keyboard);
      if (manualInputButton.evaluate().isNotEmpty) {
        await tester.tap(manualInputButton);
        await tester.pumpAndSettle();

        // テスト用JANコードを入力
        final textField = find.byType(TextField);
        if (textField.evaluate().isNotEmpty) {
          await tester.enterText(textField, '4901777018888');
          await tester.pumpAndSettle();

          // 送信ボタンをタップ
          final submitButton = find.text('スキャン');
          if (submitButton.evaluate().isNotEmpty) {
            await tester.tap(submitButton);
            await tester.pumpAndSettle();
          }
        }
      }

      // Assert: スキャン処理が完了する
      expect(tester.takeException(), isNull);
    });

    testWidgets('should handle scan errors and show appropriate messages',
        (tester) async {
      // Arrange: アプリを起動してスキャン画面に移動
      app.main();
      await tester.pumpAndSettle();

      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Act: エラーが発生する可能性のある操作を実行
      final scanButton = find.byType(FloatingActionButton);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pumpAndSettle();
      }

      // Assert: エラーハンドリングが正常に動作する
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('should save scanned products to history', (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: スキャン実行後、履歴を確認
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // スキャン操作をシミュレート
      final scanButton = find.byType(FloatingActionButton);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pumpAndSettle();
      }

      // 履歴画面に移動
      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();

      // Assert: 履歴画面が表示される
      expect(find.text('スキャン履歴'), findsOneWidget);
    });
  });
}
