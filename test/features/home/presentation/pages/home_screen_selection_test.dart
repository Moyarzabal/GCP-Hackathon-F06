import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/features/home/presentation/pages/home_screen.dart';
import 'package:barcode_scanner/features/home/presentation/widgets/product_card.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/features/products/presentation/providers/product_selection_provider.dart';
import 'package:barcode_scanner/features/products/presentation/providers/product_provider.dart';
import 'package:barcode_scanner/features/fridge/presentation/providers/fridge_view_provider.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';

void main() {
  group('HomeScreen - Selection', () {
    late List<Product> testProducts;
    late ProviderContainer container;

    setUp(() {
      testProducts = [
        Product(
          id: 'product-1',
          name: 'Product 1',
          category: 'Food',
          expiryDate: DateTime.now().add(const Duration(days: 7)),
        ),
        Product(
          id: 'product-2',
          name: 'Product 2',
          category: 'Drink',
          expiryDate: DateTime.now().add(const Duration(days: 3)),
        ),
        Product(
          id: 'product-3',
          name: 'Product 3',
          category: 'Food',
          expiryDate: DateTime.now().add(const Duration(days: 1)),
        ),
      ];

      container = ProviderContainer(overrides: [
        appStateProvider
            .overrideWith((ref) => _TestAppStateNotifier(testProducts)),
        availableCategoriesProvider.overrideWith((ref) async {
          final categories = {'すべて', ...testProducts.map((p) => p.category)};
          return categories.toList();
        }),
      ]);

      container.read(fridgeViewProvider.notifier).selectSection(
            const SelectedFridgeSection(
              compartment: FridgeCompartment.refrigerator,
              level: 0,
            ),
          );
    });

    tearDown(() {
      container.dispose();
    });

    Widget createHomeScreen() {
      return UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: HomeScreen()),
      );
    }

    group('Selection Mode Toggle', () {
      testWidgets('should enter selection mode on long press',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        expect(find.byType(FloatingActionButton), findsNothing);

        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.isSelectionMode, true);
      });

      testWidgets('should show delete button when in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should hide delete button when not in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should show selection UI when in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(Checkbox), findsWidgets);
      });
    });

    group('Product Selection', () {
      testWidgets('should select product when tapped in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds, contains('product-3'));
      });

      testWidgets('should deselect product when tapped again',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds, isEmpty);
      });

      testWidgets('should select multiple products',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(ProductCard).at(0));
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ProductCard).at(1));
        await tester.pumpAndSettle();

        // Assert
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds,
            containsAll(['product-3', 'product-2']));
      });
    });

    group('Delete Button', () {
      testWidgets('should show delete button when products are selected',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should hide delete button when no products are selected',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets(
          'should show confirmation dialog when delete button is tapped',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pumpAndSettle();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pumpAndSettle();

        // Act
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pumpAndSettle();

        // Assert
        expect(find.byType(AlertDialog), findsOneWidget);
        expect(find.text('商品を削除'), findsOneWidget);
        expect(find.text('キャンセル'), findsOneWidget);
        expect(find.text('削除'), findsOneWidget);
      });
    });

    group('Product Display', () {
      testWidgets('should display all products', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Product 3'), findsOneWidget);
      });

      testWidgets('should display product categories',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Assert
        expect(find.text('Food'), findsNWidgets(2));
        expect(find.text('Drink'), findsOneWidget);
      });

      testWidgets('should display expiry information',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.pumpAndSettle();

        // Assert
        expect(find.textContaining('日後'), findsNWidgets(3));
      });
    });
  });
}

class _TestAppStateNotifier extends AppStateNotifier {
  _TestAppStateNotifier(List<Product> initialProducts) : super(null) {
    state = AppState(products: initialProducts);
  }

  @override
  Future<void> loadProductsFromFirebase() async {}

  @override
  void watchProductsFromFirebase() {}

  @override
  Future<void> deleteProductFromFirebase(String productId) async {
    state = state.copyWith(
      products:
          state.products.where((product) => product.id != productId).toList(),
    );
  }

  @override
  Future<void> deleteProductsFromFirebase(List<String> productIds) async {
    state = state.copyWith(
      products: state.products
          .where((product) => !productIds.contains(product.id))
          .toList(),
    );
  }
}
