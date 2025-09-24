import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:barcode_scanner/app.dart';
import 'package:barcode_scanner/features/home/presentation/pages/home_screen.dart';
import 'package:barcode_scanner/features/scanner/presentation/pages/scanner_screen.dart';
import 'package:barcode_scanner/features/history/presentation/pages/history_screen.dart';
import 'package:barcode_scanner/features/settings/presentation/pages/settings_screen.dart';
import 'package:barcode_scanner/features/products/data/providers/product_data_source_provider.dart';
import 'package:barcode_scanner/features/products/data/datasources/product_datasource.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/shared/widgets/adaptive/adaptive_scaffold.dart';

final _testOverrides = <Override>[
  productDataSourceProvider.overrideWith((ref) => _FakeProductDataSource()),
];

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('App Widget Integration Tests', () {
    testWidgets('MyApp should render MaterialApp with MainScreen',
        (tester) async {
      // Arrange & Act: MyAppを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MyApp(),
        ),
      );

      // Assert: MaterialAppが存在する
      expect(find.byType(MaterialApp), findsOneWidget);
      expect(find.byType(MainScreen), findsOneWidget);
    });

    testWidgets('MainScreen should display navigation and screens correctly',
        (tester) async {
      // Arrange & Act: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ナビゲーションバーが表示される
      expect(find.bySemanticsLabel('ホーム'), findsWidgets);
      expect(find.bySemanticsLabel('スキャン'), findsWidgets);
      expect(find.bySemanticsLabel('履歴'), findsWidgets);
      expect(find.bySemanticsLabel('設定'), findsWidgets);

      // Assert: デフォルトでホーム画面が表示される
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should navigate between screens using bottom navigation',
        (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act & Assert: スキャン画面に移動
      final scanNav = find.bySemanticsLabel('スキャン');
      expect(scanNav, findsWidgets);
      await tester.tap(scanNav.first);
      await tester.pumpAndSettle();
      expect(find.byType(ScannerScreen), findsOneWidget);

      // Act & Assert: 履歴画面に移動
      final historyNav = find.bySemanticsLabel('履歴');
      expect(historyNav, findsWidgets);
      await tester.tap(historyNav.first);
      await tester.pumpAndSettle();
      expect(find.byType(HistoryScreen), findsOneWidget);

      // Act & Assert: 設定画面に移動
      final settingsNav = find.bySemanticsLabel('設定');
      expect(settingsNav, findsWidgets);
      await tester.tap(settingsNav.first);
      await tester.pumpAndSettle();
      expect(find.byType(SettingsScreen), findsOneWidget);

      // Act & Assert: ホーム画面に戻る
      final homeNav = find.bySemanticsLabel('ホーム');
      expect(homeNav, findsWidgets);
      await tester.tap(homeNav.first);
      await tester.pumpAndSettle();
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('should maintain navigation state during screen transitions',
        (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 複数回画面遷移を行う
      final scanNav = find.bySemanticsLabel('スキャン');
      expect(scanNav, findsWidgets);
      await tester.tap(scanNav.first);
      await tester.pumpAndSettle();

      final historyNav = find.bySemanticsLabel('履歴');
      expect(historyNav, findsWidgets);
      await tester.tap(historyNav.first);
      await tester.pumpAndSettle();

      final homeNav = find.bySemanticsLabel('ホーム');
      expect(homeNav, findsWidgets);
      await tester.tap(homeNav.first);
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
          overrides: _testOverrides,
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

    testWidgets('should display correct icons for navigation items',
        (tester) async {
      // Arrange & Act: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ナビゲーションバーのテキストが正しく表示される
      // アイコンはNavigation実装により異なるため、テキストで確認
      expect(find.bySemanticsLabel('ホーム'), findsWidgets);
      expect(find.bySemanticsLabel('スキャン'), findsWidgets);
      expect(find.bySemanticsLabel('履歴'), findsWidgets);
      expect(find.bySemanticsLabel('設定'), findsWidgets);
    });

    testWidgets('should update selected navigation item when tab is tapped',
        (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: スキャンタブをタップ
      final scanNav = find.bySemanticsLabel('スキャン');
      expect(scanNav, findsWidgets);
      await tester.tap(scanNav.first);
      await tester.pumpAndSettle();

      // Assert: スキャンタブが選択され、対応する画面が表示される
      expect(find.byType(ScannerScreen), findsOneWidget);

      // スキャン画面が表示されていることを確認
      expect(find.byType(ScannerScreen), findsOneWidget);
    });

    testWidgets('should preserve IndexedStack behavior for screen switching',
        (tester) async {
      // Arrange: MainScreenを構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const MainScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Act: 画面を切り替える
      final scanNav = find.bySemanticsLabel('スキャン');
      expect(scanNav, findsWidgets);
      await tester.tap(scanNav.first);
      await tester.pumpAndSettle();

      final homeNav = find.bySemanticsLabel('ホーム');
      expect(homeNav, findsWidgets);
      await tester.tap(homeNav.first);
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
          overrides: _testOverrides,
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

    // TODO: Firebase をテスト用にモックしたら skip を解除する
    testWidgets('ScannerScreen should render without errors', (tester) async {
      // Arrange & Act: ScannerScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
          child: MaterialApp(
            home: const ScannerScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Assert: ScannerScreenが正常に表示される
      expect(find.byType(ScannerScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    }, skip: true);

    testWidgets('HistoryScreen should render without errors', (tester) async {
      // Arrange & Act: HistoryScreenを単独で構築
      await tester.pumpWidget(
        ProviderScope(
          overrides: _testOverrides,
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
          overrides: _testOverrides,
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

class _FakeProductDataSource implements ProductDataSource {
  final List<Product> _products = [];

  @override
  Future<String> addProduct(Product product) async {
    final newProduct = product.id == null
        ? product.copyWith(id: 'test-id-${_products.length}')
        : product;
    _products.add(newProduct);
    return newProduct.id!;
  }

  @override
  Future<void> deleteProduct(String id) async {
    _products.removeWhere((element) => element.id == id);
  }

  @override
  Future<List<Product>> getAllProducts() async => List.unmodifiable(_products);

  @override
  Future<List<Product>> getAllProductsIncludingDeleted() async =>
      List.unmodifiable(_products);

  @override
  Future<Product?> getProduct(String id) async {
    try {
      return _products.firstWhere((element) => element.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    final index = _products.indexWhere((element) => element.id == product.id);
    if (index >= 0) {
      _products[index] = product;
    }
  }

  @override
  Stream<List<Product>> watchProducts() =>
      Stream.value(List.unmodifiable(_products));
}
