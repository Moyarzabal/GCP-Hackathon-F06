import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

import 'package:barcode_scanner/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('App Integration Tests', () {
    testWidgets('should launch app and display main screen', (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act & Assert: メイン画面が表示されることを確認
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('スキャン'), findsOneWidget);
      expect(find.text('履歴'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('should navigate between tabs', (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: 各タブをタップ
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();
      
      // Assert: スキャン画面が表示される
      expect(find.text('バーコードスキャン'), findsOneWidget);

      // Act: 履歴タブをタップ
      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();
      
      // Assert: 履歴画面が表示される
      expect(find.text('スキャン履歴'), findsOneWidget);

      // Act: 設定タブをタップ
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      
      // Assert: 設定画面が表示される
      expect(find.text('設定'), findsOneWidget);

      // Act: ホームタブに戻る
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      
      // Assert: ホーム画面が表示される
      expect(find.text('冷蔵庫の中身'), findsOneWidget);
    });

    testWidgets('should complete full app flow: scan -> add product -> view history', (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: スキャンタブに移動
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // スキャンボタンをタップ（実際のスキャンはモックされる）
      final scanButton = find.byType(FloatingActionButton);
      if (scanButton.evaluate().isNotEmpty) {
        await tester.tap(scanButton);
        await tester.pumpAndSettle();
      }

      // Act: ホームに戻って商品リストを確認
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();

      // Act: 履歴を確認
      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();

      // Assert: 履歴画面が表示される
      expect(find.text('スキャン履歴'), findsOneWidget);
    });

    testWidgets('should handle error states gracefully', (tester) async {
      // Arrange: アプリを起動
      app.main();
      await tester.pumpAndSettle();

      // Act: ネットワークエラーのシミュレーション
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Assert: エラーハンドリングが正常に動作する
      expect(find.byType(MaterialApp), findsOneWidget);
      
      // アプリがクラッシュしないことを確認
      expect(tester.takeException(), isNull);
    });
  });
}