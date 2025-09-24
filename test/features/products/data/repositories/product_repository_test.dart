import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:barcode_scanner/features/products/data/repositories/product_repository_impl.dart';
import 'package:barcode_scanner/features/products/data/datasources/product_datasource.dart';
import 'package:barcode_scanner/shared/models/product.dart';

import 'product_repository_test.mocks.dart';

@GenerateMocks([ProductDataSource])
void main() {
  late ProductRepositoryImpl repository;
  late MockProductDataSource mockDataSource;

  setUp(() {
    mockDataSource = MockProductDataSource();
    repository = ProductRepositoryImpl(mockDataSource);
  });

  group('ProductRepositoryImpl', () {
    final testProduct = Product(
      id: 'test-id',
      janCode: '4901777018888',
      name: 'コカ・コーラ 500ml',
      category: '飲料',
      scannedAt: DateTime(2024, 1, 1),
      addedDate: DateTime(2024, 1, 1),
      expiryDate: DateTime(2024, 12, 31),
      quantity: 1,
      unit: 'piece',
    );

    test('should get all products from data source', () async {
      // Arrange
      final testProducts = [testProduct];
      when(mockDataSource.getAllProducts())
          .thenAnswer((_) async => testProducts);

      // Act
      final result = await repository.getAllProducts();

      // Assert
      expect(result, equals(testProducts));
      verify(mockDataSource.getAllProducts()).called(1);
    });

    test('should get product by id from data source', () async {
      // Arrange
      when(mockDataSource.getProduct('test-id'))
          .thenAnswer((_) async => testProduct);

      // Act
      final result = await repository.getProduct('test-id');

      // Assert
      expect(result, equals(testProduct));
      verify(mockDataSource.getProduct('test-id')).called(1);
    });

    test('should add product through data source', () async {
      // Arrange
      const expectedId = 'new-product-id';
      when(mockDataSource.addProduct(testProduct))
          .thenAnswer((_) async => expectedId);

      // Act
      final result = await repository.addProduct(testProduct);

      // Assert
      expect(result, equals(expectedId));
      verify(mockDataSource.addProduct(testProduct)).called(1);
    });

    test('should update product through data source', () async {
      // Arrange
      when(mockDataSource.updateProduct(testProduct))
          .thenAnswer((_) async => {});

      // Act
      await repository.updateProduct(testProduct);

      // Assert
      verify(mockDataSource.updateProduct(testProduct)).called(1);
    });

    test('should delete product through data source', () async {
      // Arrange
      when(mockDataSource.deleteProduct('test-id')).thenAnswer((_) async => {});

      // Act
      await repository.deleteProduct('test-id');

      // Assert
      verify(mockDataSource.deleteProduct('test-id')).called(1);
    });

    test('should watch products stream from data source', () async {
      // Arrange
      final testProducts = [testProduct];
      when(mockDataSource.watchProducts())
          .thenAnswer((_) => Stream.value(testProducts));

      // Act
      final stream = repository.watchProducts();
      final result = await stream.first;

      // Assert
      expect(result, equals(testProducts));
      verify(mockDataSource.watchProducts()).called(1);
    });

    test('should handle exceptions from data source', () async {
      // Arrange
      when(mockDataSource.getAllProducts())
          .thenThrow(Exception('Network error'));

      // Act & Assert
      expect(
        () => repository.getAllProducts(),
        throwsException,
      );
    });
  });
}
