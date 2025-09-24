import 'package:flutter_test/flutter_test.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:barcode_scanner/features/products/data/datasources/firestore_product_datasource.dart';
import 'package:barcode_scanner/shared/models/product.dart';

void main() {
  late FakeFirebaseFirestore fakeFirestore;
  late FirestoreProductDataSource dataSource;

  setUp(() {
    fakeFirestore = FakeFirebaseFirestore();
    dataSource = FirestoreProductDataSource(fakeFirestore);
  });

  group('FirestoreProductDataSource', () {
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

    test('should add product to Firestore', () async {
      // Act
      final productId = await dataSource.addProduct(testProduct);

      // Assert
      expect(productId, isNotEmpty);

      final doc =
          await fakeFirestore.collection('products').doc(productId).get();

      expect(doc.exists, true);
      expect(doc.data()!['name'], testProduct.name);
      expect(doc.data()!['janCode'], testProduct.janCode);
      expect(doc.data()!['category'], testProduct.category);
    });

    test('should get all products from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('products').add(testProduct.toFirestore());

      // Act
      final products = await dataSource.getAllProducts();

      // Assert
      expect(products.length, 1);
      expect(products.first.name, testProduct.name);
      expect(products.first.janCode, testProduct.janCode);
    });

    test('should get product by id from Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore
          .collection('products')
          .add(testProduct.toFirestore());

      // Act
      final product = await dataSource.getProduct(docRef.id);

      // Assert
      expect(product, isNotNull);
      expect(product!.name, testProduct.name);
      expect(product.janCode, testProduct.janCode);
    });

    test('should update product in Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore
          .collection('products')
          .add(testProduct.toFirestore());

      final updatedProduct = testProduct.copyWith(
        id: docRef.id,
        name: '更新された商品',
        quantity: 2,
      );

      // Act
      await dataSource.updateProduct(updatedProduct);

      // Assert
      final doc =
          await fakeFirestore.collection('products').doc(docRef.id).get();

      expect(doc.data()!['name'], '更新された商品');
      expect(doc.data()!['quantity'], 2);
    });

    test('should delete product from Firestore', () async {
      // Arrange
      final docRef = await fakeFirestore
          .collection('products')
          .add(testProduct.toFirestore());

      // Act
      await dataSource.deleteProduct(docRef.id);

      // Assert
      final doc =
          await fakeFirestore.collection('products').doc(docRef.id).get();

      expect(doc.exists, false);
    });

    test('should watch products stream from Firestore', () async {
      // Arrange
      await fakeFirestore.collection('products').add(testProduct.toFirestore());

      // Act
      final stream = dataSource.watchProducts();
      final products = await stream.first;

      // Assert
      expect(products.length, 1);
      expect(products.first.name, testProduct.name);
    });

    test('should return null when product not found', () async {
      // Act
      final product = await dataSource.getProduct('non-existent-id');

      // Assert
      expect(product, isNull);
    });

    test('should handle empty collection', () async {
      // Act
      final products = await dataSource.getAllProducts();

      // Assert
      expect(products, isEmpty);
    });
  });
}
