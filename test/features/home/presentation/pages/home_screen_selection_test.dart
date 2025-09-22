import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/features/home/presentation/pages/home_screen.dart';
import 'package:barcode_scanner/features/home/presentation/widgets/product_card.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/features/products/presentation/providers/product_selection_provider.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';

void main() {
  group('HomeScreen - Selection', () {
    late List<Product> testProducts;

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
    });

    Widget createHomeScreen() {
      return ProviderScope(
        overrides: [
          productsProvider.overrideWith((ref) => testProducts),
        ],
        child: const MaterialApp(
          home: HomeScreen(),
        ),
      );
    }

    group('Selection Mode Toggle', () {
      testWidgets('should enter selection mode on long press', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        expect(find.byType(FloatingActionButton), findsNothing);

        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.isSelectionMode, true);
      });

      testWidgets('should show delete button when in selection mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        
        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should hide delete button when not in selection mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());

        // Assert
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should show selection UI when in selection mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        
        // Act
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        expect(find.byType(Checkbox), findsWidgets);
      });
    });

    group('Product Selection', () {
      testWidgets('should select product when tapped in selection mode', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Act
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds, contains('product-1'));
      });

      testWidgets('should deselect product when tapped again', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();

        // Act
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds, isEmpty);
      });

      testWidgets('should select multiple products', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Act
        await tester.tap(find.byType(ProductCard).at(0));
        await tester.pump();
        await tester.tap(find.byType(ProductCard).at(1));
        await tester.pump();

        // Assert
        final container = ProviderScope.containerOf(tester.element(find.byType(HomeScreen)));
        final selectionState = container.read(productSelectionProvider);
        expect(selectionState.selectedProductIds, containsAll(['product-1', 'product-2']));
      });
    });

    group('Delete Button', () {
      testWidgets('should show delete button when products are selected', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        expect(find.byType(FloatingActionButton), findsOneWidget);
        expect(find.byIcon(Icons.delete), findsOneWidget);
      });

      testWidgets('should hide delete button when no products are selected', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();

        // Assert
        expect(find.byType(FloatingActionButton), findsNothing);
      });

      testWidgets('should show confirmation dialog when delete button is tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());
        await tester.longPress(find.byType(ProductCard).first);
        await tester.pump();
        await tester.tap(find.byType(ProductCard).first);
        await tester.pump();

        // Act
        await tester.tap(find.byType(FloatingActionButton));
        await tester.pump();

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

        // Assert
        expect(find.text('Product 1'), findsOneWidget);
        expect(find.text('Product 2'), findsOneWidget);
        expect(find.text('Product 3'), findsOneWidget);
      });

      testWidgets('should display product categories', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());

        // Assert
        expect(find.text('Food'), findsNWidgets(2));
        expect(find.text('Drink'), findsOneWidget);
      });

      testWidgets('should display expiry information', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createHomeScreen());

        // Assert
        expect(find.textContaining('日後'), findsNWidgets(3));
      });
    });
  });
}
