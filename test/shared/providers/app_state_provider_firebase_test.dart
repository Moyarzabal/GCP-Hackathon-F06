import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:barcode_scanner/shared/providers/app_state_provider.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'package:barcode_scanner/features/products/data/datasources/product_datasource.dart';
import 'package:barcode_scanner/features/products/data/providers/product_data_source_provider.dart';
import 'app_state_provider_firebase_test.mocks.dart';

// Mock classes
@GenerateMocks([ProductDataSource])
void main() {
  group('AppStateNotifier Firebase Integration Tests', () {
    late MockProductDataSource mockDataSource;
    late ProviderContainer container;

    setUp(() {
      mockDataSource = MockProductDataSource();
      container = ProviderContainer(
        overrides: [
          productDataSourceProvider.overrideWithValue(mockDataSource),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    group('loadProductsFromFirebase', () {
      test('should load products from Firebase and update state', () async {
        // Arrange
        final mockProducts = [
          Product(
            id: '1',
            name: 'Test Product 1',
            category: 'Food',
            expiryDate: DateTime(2024, 12, 25),
            quantity: 1,
            unit: 'piece',
          ),
          Product(
            id: '2',
            name: 'Test Product 2',
            category: 'Drink',
            expiryDate: DateTime(2024, 12, 30),
            quantity: 2,
            unit: 'bottles',
          ),
        ];

        when(mockDataSource.getAllProducts())
            .thenAnswer((_) async => mockProducts);

        // Act
        final notifier = container.read(appStateProvider.notifier);
        await notifier.loadProductsFromFirebase();

        // Assert
        final state = container.read(appStateProvider);
        expect(state.products, hasLength(2));
        expect(state.products[0].name, equals('Test Product 1'));
        expect(state.products[1].name, equals('Test Product 2'));
        expect(state.isLoading, isFalse);
        expect(state.error, isNull);
      });

      test('should handle Firebase error and set error state', () async {
        // Arrange
        when(mockDataSource.getAllProducts())
            .thenThrow(Exception('Firebase connection failed'));

        // Act
        final notifier = container.read(appStateProvider.notifier);
        await notifier.loadProductsFromFirebase();

        // Assert
        final state = container.read(appStateProvider);
        expect(state.products, isEmpty);
        expect(state.isLoading, isFalse);
        expect(state.error, isNotNull);
        expect(state.error, contains('Firebase connection failed'));
      });

      test('should set loading state during Firebase operation', () async {
        // Arrange
        when(mockDataSource.getAllProducts()).thenAnswer((_) async {
          await Future.delayed(Duration(milliseconds: 100));
          return [];
        });

        // Act
        final notifier = container.read(appStateProvider.notifier);
        final future = notifier.loadProductsFromFirebase();

        // Assert - Check loading state during operation
        final stateDuringLoading = container.read(appStateProvider);
        expect(stateDuringLoading.isLoading, isTrue);

        await future;

        // Assert - Check final state
        final finalState = container.read(appStateProvider);
        expect(finalState.isLoading, isFalse);
      });
    });

    group('addProductToFirebase', () {
      test('should add product to Firebase and update state', () async {
        // Arrange
        final product = Product(
          name: 'New Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        when(mockDataSource.addProduct(any))
            .thenAnswer((_) async => 'new-product-id');

        // Act
        final notifier = container.read(appStateProvider.notifier);
        await notifier.addProductToFirebase(product);

        // Assert
        verify(mockDataSource.addProduct(product)).called(1);
        final state = container.read(appStateProvider);
        expect(state.products, hasLength(1));
        expect(state.products[0].name, equals('New Product'));
        expect(state.products[0].id, equals('new-product-id'));
      });

      test('should handle Firebase error when adding product', () async {
        // Arrange
        final product = Product(
          name: 'New Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        when(mockDataSource.addProduct(any)).thenThrow(Exception('Add failed'));

        // Act
        final notifier = container.read(appStateProvider.notifier);
        await notifier.addProductToFirebase(product);

        // Assert
        final state = container.read(appStateProvider);
        expect(state.products, isEmpty);
        expect(state.error, isNotNull);
        expect(state.error, contains('Add failed'));
      });
    });

    group('updateProductInFirebase', () {
      test('should update product in Firebase and update state', () async {
        // Arrange
        final existingProduct = Product(
          id: '1',
          name: 'Original Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        final updatedProduct = existingProduct.copyWith(
          name: 'Updated Product',
          quantity: 2,
        );

        // Set up initial state
        final notifier = container.read(appStateProvider.notifier);
        notifier.addProduct(existingProduct);

        when(mockDataSource.updateProduct(any)).thenAnswer((_) async {});

        // Act
        await notifier.updateProductInFirebase(updatedProduct);

        // Assert
        verify(mockDataSource.updateProduct(updatedProduct)).called(1);
        final state = container.read(appStateProvider);
        expect(state.products, hasLength(1));
        expect(state.products[0].name, equals('Updated Product'));
        expect(state.products[0].quantity, equals(2));
      });

      test('should handle Firebase error when updating product', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        // Set up initial state
        final notifier = container.read(appStateProvider.notifier);
        notifier.addProduct(product);

        when(mockDataSource.updateProduct(any))
            .thenThrow(Exception('Update failed'));

        // Act
        await notifier.updateProductInFirebase(product);

        // Assert
        final state = container.read(appStateProvider);
        expect(state.error, isNotNull);
        expect(state.error, contains('Update failed'));
      });
    });

    group('deleteProductFromFirebase', () {
      test('should delete product from Firebase and update state', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        // Set up initial state
        final notifier = container.read(appStateProvider.notifier);
        notifier.addProduct(product);

        when(mockDataSource.deleteProduct(any)).thenAnswer((_) async {});

        // Act
        await notifier.deleteProductFromFirebase('1');

        // Assert
        verify(mockDataSource.deleteProduct('1')).called(1);
        final state = container.read(appStateProvider);
        expect(state.products, isEmpty);
      });

      test('should handle Firebase error when deleting product', () async {
        // Arrange
        final product = Product(
          id: '1',
          name: 'Test Product',
          category: 'Food',
          expiryDate: DateTime(2024, 12, 25),
          quantity: 1,
          unit: 'piece',
        );

        // Set up initial state
        final notifier = container.read(appStateProvider.notifier);
        notifier.addProduct(product);

        when(mockDataSource.deleteProduct(any))
            .thenThrow(Exception('Delete failed'));

        // Act
        await notifier.deleteProductFromFirebase('1');

        // Assert
        final state = container.read(appStateProvider);
        expect(
            state.products, hasLength(1)); // Product should still be in state
        expect(state.error, isNotNull);
        expect(state.error, contains('Delete failed'));
      });
    });

    group('watchProductsFromFirebase', () {
      test('should watch products stream from Firebase', () async {
        // Arrange
        final mockProducts = [
          Product(
            id: '1',
            name: 'Test Product 1',
            category: 'Food',
            expiryDate: DateTime(2024, 12, 25),
            quantity: 1,
            unit: 'piece',
          ),
        ];

        when(mockDataSource.watchProducts())
            .thenAnswer((_) => Stream.value(mockProducts));

        // Act
        final notifier = container.read(appStateProvider.notifier);
        notifier.watchProductsFromFirebase();

        // Wait for stream to emit
        await Future.delayed(Duration(milliseconds: 100));

        // Assert
        final state = container.read(appStateProvider);
        expect(state.products, hasLength(1));
        expect(state.products[0].name, equals('Test Product 1'));
      });
    });
  });
}
