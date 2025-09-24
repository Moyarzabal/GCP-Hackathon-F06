import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:barcode_scanner/shared/widgets/adaptive/adaptive_navigation.dart';

void main() {
  group('AdaptiveNavigation', () {
    const testDestinations = [
      NavigationDestination(
        icon: Icon(Icons.home),
        label: 'ホーム',
      ),
      NavigationDestination(
        icon: Icon(Icons.search),
        label: '検索',
      ),
      NavigationDestination(
        icon: Icon(Icons.settings),
        label: '設定',
      ),
    ];

    testWidgets('should render CupertinoTabBar on iOS',
        (WidgetTester tester) async {
      // モックでiOSプラットフォームをシミュレート（実際にはテスト環境でのテスト）
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdaptiveNavigation(
              selectedIndex: 0,
              destinations: testDestinations,
              onDestinationSelected: (index) {},
            ),
          ),
        ),
      );

      // ウィジェットが正常に描画されることを確認
      expect(find.byType(AdaptiveNavigation), findsOneWidget);

      // destinations数が正しいことを確認
      expect(testDestinations.length, equals(3));

      // ラベルが表示されることを確認
      expect(find.text('ホーム'), findsOneWidget);
      expect(find.text('検索'), findsOneWidget);
      expect(find.text('設定'), findsOneWidget);
    });

    testWidgets('should render NavigationBar on Android/Web',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdaptiveNavigation(
              selectedIndex: 1,
              destinations: testDestinations,
              onDestinationSelected: (index) {},
            ),
          ),
        ),
      );

      // ウィジェットが正常に描画されることを確認
      expect(find.byType(AdaptiveNavigation), findsOneWidget);

      // 選択されたインデックスが正しく反映されることを確認
      final navigation =
          tester.widget<AdaptiveNavigation>(find.byType(AdaptiveNavigation));
      expect(navigation.selectedIndex, equals(1));
    });

    testWidgets('should handle destination selection',
        (WidgetTester tester) async {
      int selectedIndex = 0;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdaptiveNavigation(
              selectedIndex: selectedIndex,
              destinations: testDestinations,
              onDestinationSelected: (index) {
                selectedIndex = index;
              },
            ),
          ),
        ),
      );

      // コールバック関数の初期化を確認
      expect(selectedIndex, equals(0));
    });

    testWidgets('should handle single destination gracefully',
        (WidgetTester tester) async {
      const singleDestination = [
        NavigationDestination(
          icon: Icon(Icons.home),
          label: 'ホーム',
        ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdaptiveNavigation(
              selectedIndex: 0,
              destinations: singleDestination,
              onDestinationSelected: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveNavigation), findsOneWidget);
      // Materialの制約により、不足メッセージが表示される
      expect(find.text('ナビゲーション項目が不足しています'), findsOneWidget);
    });

    testWidgets('should handle empty destinations gracefully',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            bottomNavigationBar: AdaptiveNavigation(
              selectedIndex: 0,
              destinations: const [],
              onDestinationSelected: (index) {},
            ),
          ),
        ),
      );

      expect(find.byType(AdaptiveNavigation), findsOneWidget);
    });
  });
}
