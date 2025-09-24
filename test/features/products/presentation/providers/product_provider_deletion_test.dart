import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:barcode_scanner/features/products/presentation/providers/product_provider.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';
import 'package:barcode_scanner/shared/models/product.dart';

void main() {
  group('ProductNotifier - Deletion', () {
    late ProviderContainer container;
    late ProductNotifier notifier;

    setUp(() {
      container = ProviderContainer();
      notifier = container.read(productProvider.notifier);
    });

    tearDown(() {
      container.dispose();
    });

    group('deleteSelectedProducts', () {
      test('should delete multiple products successfully', () async {
        // Arrange
        final products = [
          Product(id: 'product1', name: 'Product 1', category: 'Food'),
          Product(id: 'product2', name: 'Product 2', category: 'Food'),
          Product(id: 'product3', name: 'Product 3', category: 'Drink'),
        ];

        // Mock the app state provider to return products
        container = ProviderContainer(
          overrides: [
            productsProvider.overrideWith((ref) => products),
          ],
        );
        notifier = container.read(productProvider.notifier);

        // Act
        final result =
            await notifier.deleteSelectedProducts(['product1', 'product2']);

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle empty product list', () async {
        // Arrange
        container = ProviderContainer(
          overrides: [
            productsProvider.overrideWith((ref) => []),
          ],
        );
        notifier = container.read(productProvider.notifier);

        // Act
        final result = await notifier.deleteSelectedProducts([]);

        // Assert
        expect(result.isSuccess, true);
      });

      test('should handle non-existent product IDs', () async {
        // Arrange
        final products = [
          Product(id: 'product1', name: 'Product 1', category: 'Food'),
        ];

        container = ProviderContainer(
          overrides: [
            productsProvider.overrideWith((ref) => products),
          ],
        );
        notifier = container.read(productProvider.notifier);

        // Act
        final result = await notifier.deleteSelectedProducts(['non-existent']);

        // Assert
        expect(result.isSuccess,
            true); // Should succeed even if product doesn't exist
      });

      test('should handle mixed existing and non-existing products', () async {
        // Arrange
        final products = [
          Product(id: 'product1', name: 'Product 1', category: 'Food'),
          Product(id: 'product2', name: 'Product 2', category: 'Food'),
        ];

        container = ProviderContainer(
          overrides: [
            productsProvider.overrideWith((ref) => products),
          ],
        );
        notifier = container.read(productProvider.notifier);

        // Act
        final result = await notifier
            .deleteSelectedProducts(['product1', 'non-existent', 'product2']);

        // Assert
        expect(result.isSuccess, true);
      });
    });
  });
}
