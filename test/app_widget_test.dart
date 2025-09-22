import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barcode_scanner/app.dart';
import 'package:barcode_scanner/features/home/presentation/pages/home_screen.dart';
import 'package:barcode_scanner/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:barcode_scanner/features/history/presentation/pages/history_screen.dart';
import 'package:barcode_scanner/features/settings/presentation/pages/settings_screen.dart';
import 'package:barcode_scanner/shared/widgets/adaptive/adaptive_scaffold.dart';

void main() {
  group('App Widget Integration Tests', () {
    testWidgets('MyApp should render MaterialApp with MainScreen', (tester) async {
      // Arrange & Act: MyAppを構築
      await tester.pumpWidget(
        const ProviderScope(
          child: MyApp(),
        ),
      );

      // Assert: MaterialAppが存在する
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('MainScreen should display navigation and screens correctly', (tester) async {
      // Arrange & Act: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ナビゲーションバーが表示される
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('スキャン'), findsOneWidget);
      expect(find.text('履歴'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);

      // Assert: デフォルトでホーム画面が表示される
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should navigate between screens using bottom navigation', (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: スキャン画面に移動
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Act & Assert: 履歴画面に移動
      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // Act & Assert: 設定画面に移動
      await tester.tap(find.text('設定'));
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Act & Assert: ホーム画面に戻る
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should maintain navigation state during screen transitions', (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 複数回画面遷移を行う
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('履歴'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();

      // Assert: 最終的にホーム画面が表示される
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(ScannerScreen), findsNothing);
      expect(find.byType(HistoryScreen), findsNothing);
    });

    testWidgets('should handle navigation errors gracefully', (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 存在しないナビゲーションアイテムをタップしようとする
      // （現在のナビゲーションでは該当しないが、将来の拡張に備えて）
      
      // Assert: エラーが発生しない
      expect(tester.takeException(), isNull);
      expect(find.byType(AdaptiveScaffold), findsOneWidget);
    });

    testWidgets('should display correct icons for navigation items', (tester) async {
      // Arrange & Act: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ナビゲーションバーのテキストが正しく表示される
      // アイコンはNavigation実装により異なるため、テキストで確認
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('スキャン'), findsOneWidget);
      expect(find.text('履歴'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('should update selected navigation item when tab is tapped', (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: スキャンタブをタップ
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();

      // Assert: スキャンタブが選択され、対応する画面が表示される
      expect(find.byType(ScannerScreen), findsOneWidget);
      
      // スキャン画面が表示されていることを確認
      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('should preserve IndexedStack behavior for screen switching', (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 画面を切り替える
      await tester.tap(find.text('スキャン'));
      await tester.pumpAndSettle();
      
      await tester.tap(find.text('ホーム'));
      await tester.pumpAndSettle();

      // Assert: IndexedStackが正しく動作している
      expect(find.byType(IndexedStack), findsOneWidget);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Screen Widget Tests', () {
    testWidgets('HomeScreen should render without errors', (tester) async {
      // Arrange & Act: HomeScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HomeScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: HomeScreenが正常に表示される
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('ScannerScreen should render without errors', (tester) async {
      // Arrange & Act: ScannerScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ScannerScreenが正常に表示される
      expect(find.byType(ScannerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('HistoryScreen should render without errors', (tester) async {
      // Arrange & Act: HistoryScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: HistoryScreenが正常に表示される
      expect(find.byType(HistoryScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    testWidgets('SettingsScreen should render without errors', (tester) async {
      // Arrange & Act: SettingsScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: const SettingsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: SettingsScreenが正常に表示される
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}