import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:barcode_scanner/shared/models/product.dart';
import 'product_firestore_test.mocks.dart';

// Mock classes
@GenerateMocks([Timestamp])
void main() {
  group('Product Firestore Integration Tests', () {
    group('fromFirestore', () {
      test('should parse Firestore Timestamp correctly', () {
        // Arrange
        final mockTimestamp = MockTimestamp();
        when(mockTimestamp.toDate()).thenReturn(DateTime(2024, 12, 19, 10, 30));
        
        final firestoreData = {
          'janCode': '1234567890123',
          'name': 'Test Product',
          'scannedAt': mockTimestamp,
          'addedDate': mockTimestamp,
          'expiryDate': mockTimestamp,
          'category': 'Food',
          'imageUrl': 'https://example.com/image.jpg',
          'imageUrls': {
            'veryFresh': 'https://example.com/very-fresh.jpg',
            'fresh': 'https://example.com/fresh.jpg',
            'warning': 'https://example.com/warning.jpg',
            'urgent': 'https://example.com/urgent.jpg',
            'expired': 'https://example.com/expired.jpg',
          },
          'barcode': '1234567890123',
          'manufacturer': 'Test Manufacturer',
          'quantity': 2,
          'unit': 'pieces',
          'deletedAt': null,
        };

        // Act
        final product = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(product.id, equals('test-id'));
        expect(product.janCode, equals('1234567890123'));
        expect(product.name, equals('Test Product'));
        expect(product.scannedAt, equals(DateTime(2024, 12, 19, 10, 30)));
        expect(product.addedDate, equals(DateTime(2024, 12, 19, 10, 30)));
        expect(product.expiryDate, equals(DateTime(2024, 12, 19, 10, 30)));
        expect(product.category, equals('Food'));
        expect(product.imageUrl, equals('https://example.com/image.jpg'));
        expect(product.imageUrls, isNotNull);
        expect(product.imageUrls![ImageStage.veryFresh], equals('https://example.com/very-fresh.jpg'));
        expect(product.barcode, equals('1234567890123'));
        expect(product.manufacturer, equals('Test Manufacturer'));
        expect(product.quantity, equals(2));
        expect(product.unit, equals('pieces'));
        expect(product.deletedAt, isNull);
      });

      test('should parse millisecondsSinceEpoch correctly (backward compatibility)', () {
        // Arrange
        final testDate = DateTime(2024, 12, 19, 10, 30);
        final firestoreData = {
          'name': 'Test Product',
          'scannedAt': testDate.millisecondsSinceEpoch,
          'addedDate': testDate.millisecondsSinceEpoch,
          'expiryDate': testDate.millisecondsSinceEpoch,
          'category': 'Food',
          'quantity': 1,
          'unit': 'piece',
        };

        // Act
        final product = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(product.id, equals('test-id'));
        expect(product.name, equals('Test Product'));
        expect(product.scannedAt, equals(testDate));
        expect(product.addedDate, equals(testDate));
        expect(product.expiryDate, equals(testDate));
        expect(product.category, equals('Food'));
        expect(product.quantity, equals(1));
        expect(product.unit, equals('piece'));
        expect(product.deletedAt, isNull);
      });

      test('should parse deletedAt field correctly', () {
        // Arrange
        final testDate = DateTime(2024, 12, 19, 10, 30);
        final firestoreData = {
          'name': 'Deleted Product',
          'category': 'Food',
          'quantity': 1,
          'unit': 'piece',
          'deletedAt': testDate.millisecondsSinceEpoch,
        };

        // Act
        final product = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(product.id, equals('test-id'));
        expect(product.name, equals('Deleted Product'));
        expect(product.deletedAt, equals(testDate));
      });

      test('should handle null values gracefully', () {
        // Arrange
        final firestoreData = {
          'name': 'Test Product',
          'category': 'Food',
          'quantity': 1,
          'unit': 'piece',
        };

        // Act
        final product = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(product.id, equals('test-id'));
        expect(product.name, equals('Test Product'));
        expect(product.janCode, isNull);
        expect(product.scannedAt, isNull);
        expect(product.addedDate, isNull);
        expect(product.expiryDate, isNull);
        expect(product.category, equals('Food'));
        expect(product.imageUrl, isNull);
        expect(product.imageUrls, isNull);
        expect(product.barcode, isNull);
        expect(product.manufacturer, isNull);
        expect(product.quantity, equals(1));
        expect(product.unit, equals('piece'));
      });

      test('should handle empty imageUrls map', () {
        // Arrange
        final firestoreData = {
          'name': 'Test Product',
          'category': 'Food',
          'imageUrls': <String, String>{},
          'quantity': 1,
          'unit': 'piece',
        };

        // Act
        final product = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(product.imageUrls, isNotNull);
        expect(product.imageUrls!.isEmpty, isTrue);
      });
    });

    group('toFirestore', () {
      test('should convert Product to Firestore format correctly', () {
        // Arrange
        final testDate = DateTime(2024, 12, 19, 10, 30);
        final product = Product(
          id: 'test-id',
          janCode: '1234567890123',
          name: 'Test Product',
          scannedAt: testDate,
          addedDate: testDate,
          expiryDate: testDate,
          category: 'Food',
          imageUrl: 'https://example.com/image.jpg',
          imageUrls: {
            ImageStage.veryFresh: 'https://example.com/very-fresh.jpg',
            ImageStage.fresh: 'https://example.com/fresh.jpg',
            ImageStage.warning: 'https://example.com/warning.jpg',
            ImageStage.urgent: 'https://example.com/urgent.jpg',
            ImageStage.expired: 'https://example.com/expired.jpg',
          },
          barcode: '1234567890123',
          manufacturer: 'Test Manufacturer',
          quantity: 2,
          unit: 'pieces',
        );

        // Act
        final firestoreData = product.toFirestore();

        // Assert
        expect(firestoreData['janCode'], equals('1234567890123'));
        expect(firestoreData['name'], equals('Test Product'));
        expect(firestoreData['scannedAt'], equals(testDate.millisecondsSinceEpoch));
        expect(firestoreData['addedDate'], equals(testDate.millisecondsSinceEpoch));
        expect(firestoreData['expiryDate'], equals(testDate.millisecondsSinceEpoch));
        expect(firestoreData['category'], equals('Food'));
        expect(firestoreData['imageUrl'], equals('https://example.com/image.jpg'));
        expect(firestoreData['imageUrls'], isA<Map<String, String>>());
        expect(firestoreData['imageUrls']['veryFresh'], equals('https://example.com/very-fresh.jpg'));
        expect(firestoreData['barcode'], equals('1234567890123'));
        expect(firestoreData['manufacturer'], equals('Test Manufacturer'));
        expect(firestoreData['quantity'], equals(2));
        expect(firestoreData['unit'], equals('pieces'));
      });

      test('should handle null values correctly', () {
        // Arrange
        final product = Product(
          name: 'Test Product',
          category: 'Food',
          quantity: 1,
          unit: 'piece',
        );

        // Act
        final firestoreData = product.toFirestore();

        // Assert
        expect(firestoreData['janCode'], isNull);
        expect(firestoreData['name'], equals('Test Product'));
        expect(firestoreData['scannedAt'], isNull);
        expect(firestoreData['addedDate'], isNull);
        expect(firestoreData['expiryDate'], isNull);
        expect(firestoreData['category'], equals('Food'));
        expect(firestoreData['imageUrl'], isNull);
        expect(firestoreData['imageUrls'], isNull);
        expect(firestoreData['barcode'], isNull);
        expect(firestoreData['manufacturer'], isNull);
        expect(firestoreData['quantity'], equals(1));
        expect(firestoreData['unit'], equals('piece'));
      });
    });

    group('round-trip conversion', () {
      test('should maintain data integrity through toFirestore -> fromFirestore', () {
        // Arrange
        final originalProduct = Product(
          id: 'test-id',
          janCode: '1234567890123',
          name: 'Test Product',
          scannedAt: DateTime(2024, 12, 19, 10, 30),
          addedDate: DateTime(2024, 12, 19, 10, 30),
          expiryDate: DateTime(2024, 12, 19, 10, 30),
          category: 'Food',
          imageUrl: 'https://example.com/image.jpg',
          imageUrls: {
            ImageStage.veryFresh: 'https://example.com/very-fresh.jpg',
            ImageStage.fresh: 'https://example.com/fresh.jpg',
          },
          barcode: '1234567890123',
          manufacturer: 'Test Manufacturer',
          quantity: 2,
          unit: 'pieces',
        );

        // Act
        final firestoreData = originalProduct.toFirestore();
        final reconstructedProduct = Product.fromFirestore('test-id', firestoreData);

        // Assert
        expect(reconstructedProduct.id, equals(originalProduct.id));
        expect(reconstructedProduct.janCode, equals(originalProduct.janCode));
        expect(reconstructedProduct.name, equals(originalProduct.name));
        expect(reconstructedProduct.scannedAt, equals(originalProduct.scannedAt));
        expect(reconstructedProduct.addedDate, equals(originalProduct.addedDate));
        expect(reconstructedProduct.expiryDate, equals(originalProduct.expiryDate));
        expect(reconstructedProduct.category, equals(originalProduct.category));
        expect(reconstructedProduct.imageUrl, equals(originalProduct.imageUrl));
        expect(reconstructedProduct.imageUrls, equals(originalProduct.imageUrls));
        expect(reconstructedProduct.barcode, equals(originalProduct.barcode));
        expect(reconstructedProduct.manufacturer, equals(originalProduct.manufacturer));
        expect(reconstructedProduct.quantity, equals(originalProduct.quantity));
        expect(reconstructedProduct.unit, equals(originalProduct.unit));
      });
    });
  });
}
