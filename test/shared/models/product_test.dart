import 'package:flutter_test/flutter_test.dart';
import 'package:barcode_scanner/shared/models/product.dart';

void main() {
  group('Product', () {
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

    test('should convert to Firestore format correctly', () {
      // Act
      final result = testProduct.toFirestore();

      // Assert
      expect(result, isA<Map<String, dynamic>>());
      expect(result['janCode'], testProduct.janCode);
      expect(result['name'], testProduct.name);
      expect(result['category'], testProduct.category);
      expect(result['scannedAt'], testProduct.scannedAt!.millisecondsSinceEpoch);
      expect(result['addedDate'], testProduct.addedDate!.millisecondsSinceEpoch);
      expect(result['expiryDate'], testProduct.expiryDate!.millisecondsSinceEpoch);
      expect(result['quantity'], testProduct.quantity);
      expect(result['unit'], testProduct.unit);
    });

    test('should create Product from Firestore data correctly', () {
      // Arrange
      final firestoreData = {
        'janCode': '4901777018888',
        'name': 'コカ・コーラ 500ml',
        'category': '飲料',
        'scannedAt': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'addedDate': DateTime(2024, 1, 1).millisecondsSinceEpoch,
        'expiryDate': DateTime(2024, 12, 31).millisecondsSinceEpoch,
        'quantity': 1,
        'unit': 'piece',
      };

      // Act
      final result = Product.fromFirestore('test-id', firestoreData);

      // Assert
      expect(result.id, 'test-id');
      expect(result.janCode, '4901777018888');
      expect(result.name, 'コカ・コーラ 500ml');
      expect(result.category, '飲料');
      expect(result.scannedAt, DateTime(2024, 1, 1));
      expect(result.addedDate, DateTime(2024, 1, 1));
      expect(result.expiryDate, DateTime(2024, 12, 31));
      expect(result.quantity, 1);
      expect(result.unit, 'piece');
    });

    test('should handle null values in Firestore data', () {
      // Arrange
      final firestoreData = <String, dynamic>{
        'name': 'テスト商品',
        'category': 'テスト',
      };

      // Act
      final result = Product.fromFirestore('test-id', firestoreData);

      // Assert
      expect(result.id, 'test-id');
      expect(result.name, 'テスト商品');
      expect(result.category, 'テスト');
      expect(result.janCode, isNull);
      expect(result.scannedAt, isNull);
      expect(result.addedDate, isNull);
      expect(result.expiryDate, isNull);
      expect(result.quantity, 1);
      expect(result.unit, 'piece');
    });

    test('should create copy with updated values', () {
      // Act
      final result = testProduct.copyWith(
        name: '更新された商品',
        quantity: 2,
      );

      // Assert
      expect(result.id, testProduct.id);
      expect(result.name, '更新された商品');
      expect(result.quantity, 2);
      expect(result.janCode, testProduct.janCode);
      expect(result.category, testProduct.category);
    });

    test('should calculate days until expiry correctly', () {
      // Arrange
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final productExpiresTomorrow = testProduct.copyWith(expiryDate: tomorrow);

      // Act
      final days = productExpiresTomorrow.daysUntilExpiry;

      // Assert
      expect(days, 1);
    });

    test('should return correct emotion state based on expiry', () {
      final testCases = [
        (10, '😊'), // More than 7 days
        (5, '😐'),  // 3-7 days
        (2, '😟'),  // 1-3 days
        (1, '😰'),  // Exactly 1 day
        (0, '💀'),  // Expired (0 or negative days)
      ];

      for (final (days, expectedEmoji) in testCases) {
        // Arrange
        final expiryDate = DateTime.now().add(Duration(days: days));
        final product = testProduct.copyWith(expiryDate: expiryDate);

        // Act & Assert
        expect(product.emotionState, expectedEmoji, 
               reason: 'Failed for $days days remaining');
      }
    });

    test('should handle null expiry date', () {
      // Arrange
      final productWithoutExpiry = Product(
        name: 'テスト商品',
        category: 'テスト',
        expiryDate: null,
      );

      // Act & Assert
      expect(productWithoutExpiry.daysUntilExpiry, 999);
      expect(productWithoutExpiry.emotionState, '😊');
    });
  });
}