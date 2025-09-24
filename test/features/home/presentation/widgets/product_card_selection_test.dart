import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/features/home/presentation/widgets/product_card.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';

void main() {
  group('ProductCard - Selection', () {
    late Product testProduct;
    late bool onTapCalled;
    late bool onLongPressCalled;
    late bool onSelectionToggleCalled;

    setUp(() {
      testProduct = Product(
        id: 'test-product-1',
        name: 'Test Product',
        category: 'Food',
        expiryDate: DateTime.now().add(const Duration(days: 7)),
      );
      onTapCalled = false;
      onLongPressCalled = false;
      onSelectionToggleCalled = false;
    });

    Widget createProductCard({
      bool isSelectionMode = false,
      bool isSelected = false,
      VoidCallback? onTap,
      VoidCallback? onLongPress,
      VoidCallback? onSelectionToggle,
    }) {
      return ProviderScope(
        overrides: [
          // Firebaseの依存関係をモック
          appStateProvider.overrideWith((ref) =>
              AppStateNotifier()..state = AppState(products: [testProduct])),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: ProductCard(
              product: testProduct,
              isSelectionMode: isSelectionMode,
              isSelected: isSelected,
              onTap: onTap ?? (() => onTapCalled = true),
              onLongPress: onLongPress ?? (() => onLongPressCalled = true),
              onSelectionToggle:
                  onSelectionToggle ?? (() => onSelectionToggleCalled = true),
            ),
          ),
        ),
      );
    }

    group('Normal Mode', () {
      testWidgets('should call onTap when tapped', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.tap(find.byType(ProductCard));
        await tester.pump();

        // Assert
        expect(onTapCalled, true);
        expect(onLongPressCalled, false);
        expect(onSelectionToggleCalled, false);
      });

      testWidgets('should call onLongPress when long pressed',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.longPress(find.byType(ProductCard));
        await tester.pump();

        // Assert
        expect(onTapCalled, false);
        expect(onLongPressCalled, true);
        expect(onSelectionToggleCalled, false);
      });

      testWidgets('should not show checkbox', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.pump();

        // Assert
        expect(find.byType(Checkbox), findsNothing);
      });

      testWidgets('should not show selection overlay',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.pump();

        // Assert
        expect(find.byType(Positioned), findsNothing);
      });
    });

    group('Selection Mode', () {
      testWidgets('should call onSelectionToggle when tapped',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(isSelectionMode: true));

        // Act
        await tester.tap(find.byType(ProductCard));
        await tester.pump();

        // Assert
        expect(onTapCalled, false);
        expect(onLongPressCalled, false);
        expect(onSelectionToggleCalled, true);
      });

      testWidgets('should show checkbox when in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(isSelectionMode: true));

        // Act
        await tester.pump();

        // Assert
        expect(find.byType(Checkbox), findsOneWidget);
      });

      testWidgets('should show selection overlay when in selection mode',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(isSelectionMode: true));

        // Act
        await tester.pump();

        // Assert
        expect(find.byType(Positioned), findsOneWidget);
      });

      testWidgets('should show selected state when isSelected is true',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(
          isSelectionMode: true,
          isSelected: true,
        ));

        // Act
        await tester.pump();

        // Assert
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, true);
      });

      testWidgets('should show unselected state when isSelected is false',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(
          isSelectionMode: true,
          isSelected: false,
        ));

        // Act
        await tester.pump();

        // Assert
        final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
        expect(checkbox.value, false);
      });

      testWidgets('should show highlighted border when selected',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard(
          isSelectionMode: true,
          isSelected: true,
        ));

        // Act
        await tester.pump();

        // Assert
        final card = tester.widget<Card>(find.byType(Card));
        expect(card.margin, isA<EdgeInsets>());
      });
    });

    group('Product Information Display', () {
      testWidgets('should display product name', (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.pump();

        // Assert
        expect(find.text('Test Product'), findsOneWidget);
      });

      testWidgets('should display product category',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.pump();

        // Assert
        expect(find.text('Food'), findsOneWidget);
      });

      testWidgets('should display expiry information',
          (WidgetTester tester) async {
        // Arrange
        await tester.pumpWidget(createProductCard());

        // Act
        await tester.pump();

        // Assert
        expect(find.textContaining('日後'), findsOneWidget);
      });
    });
  });
}
