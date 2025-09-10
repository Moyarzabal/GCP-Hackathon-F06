import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/product.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final Uuid _uuid = const Uuid();

  // Household operations
  Future<String> createHousehold(String name, String userId) async {
    try {
      final householdId = _uuid.v4();
      await _firestore.collection('households').doc(householdId).set({
        'householdId': householdId,
        'name': name,
        'members': [userId],
        'createdAt': FieldValue.serverTimestamp(),
        'settings': {
          'notificationDays': 3,
          'enableNotifications': true,
        },
      });

      await _firestore.collection('users').doc(userId).update({
        'householdId': householdId,
        'role': 'owner',
      });

      return householdId;
    } catch (e) {
      print('Error creating household: $e');
      // Return a mock household ID for development
      return 'mock-household-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  Future<void> joinHousehold(String householdId, String userId) async {
    await _firestore.collection('households').doc(householdId).update({
      'members': FieldValue.arrayUnion([userId]),
    });

    await _firestore.collection('users').doc(userId).update({
      'householdId': householdId,
      'role': 'member',
    });
  }

  Stream<QuerySnapshot> getHouseholdProducts(String householdId) {
    try {
      return _firestore
          .collection('items')
          .where('householdId', isEqualTo: householdId)
          .orderBy('expiryDate')
          .snapshots();
    } catch (e) {
      print('Error getting household products: $e');
      // Return an empty stream for development
      return Stream.empty();
    }
  }

  // Product operations
  Future<String> addProduct({
    required String householdId,
    required String productName,
    required String category,
    required DateTime expiryDate,
    required String userId,
    String? janCode,
    String? barcode,
    int quantity = 1,
    String unit = 'piece',
    double? price,
    String? imageUrl,
  }) async {
    final itemId = _uuid.v4();
    final product = Product(
      id: itemId,
      name: productName,
      category: category,
      expiryDate: expiryDate,
      quantity: quantity,
      unit: unit,
      addedDate: DateTime.now(),
      barcode: barcode,
      imageUrl: imageUrl,
    );

    await _firestore.collection('items').doc(itemId).set({
      'itemId': itemId,
      'householdId': householdId,
      'productName': productName,
      'janCode': janCode,
      'category': category,
      'quantity': quantity,
      'unit': unit,
      'expiryDate': Timestamp.fromDate(expiryDate),
      'status': product.emotionState,
      'barcode': barcode,
      'price': price,
      'imageUrl': imageUrl,
      'addedBy': userId,
      'addedDate': FieldValue.serverTimestamp(),
    });

    return itemId;
  }

  Future<void> updateProduct(String itemId, Map<String, dynamic> updates) async {
    await _firestore.collection('items').doc(itemId).update(updates);
  }

  Future<void> deleteProduct(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  // Product database operations (cached product info)
  Future<Map<String, dynamic>?> getProductByJAN(String janCode) async {
    final doc = await _firestore.collection('products').doc(janCode).get();
    return doc.exists ? doc.data() : null;
  }

  Future<void> cacheProductInfo({
    required String janCode,
    required String productName,
    String? manufacturer,
    String? category,
    String? imageUrl,
    Map<String, dynamic>? nutritionInfo,
    List<String>? allergens,
  }) async {
    await _firestore.collection('products').doc(janCode).set({
      'janCode': janCode,
      'productName': productName,
      'manufacturer': manufacturer,
      'category': category,
      'nutritionInfo': nutritionInfo,
      'allergens': allergens,
      'imageUrl': imageUrl,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  // History operations
  Future<void> addScanHistory({
    required String userId,
    required String janCode,
    required String productName,
    String? imageUrl,
  }) async {
    await _firestore.collection('scanHistory').add({
      'userId': userId,
      'janCode': janCode,
      'productName': productName,
      'imageUrl': imageUrl,
      'scannedAt': FieldValue.serverTimestamp(),
    });
  }

  Stream<QuerySnapshot> getUserScanHistory(String userId) {
    return _firestore
        .collection('scanHistory')
        .where('userId', isEqualTo: userId)
        .orderBy('scannedAt', descending: true)
        .limit(50)
        .snapshots();
  }

  // Notifications settings
  Future<void> updateNotificationSettings(
    String householdId,
    int notificationDays,
    bool enableNotifications,
  ) async {
    await _firestore.collection('households').doc(householdId).update({
      'settings.notificationDays': notificationDays,
      'settings.enableNotifications': enableNotifications,
    });
  }

  // Get products expiring soon
  Stream<QuerySnapshot> getExpiringProducts(String householdId, int daysAhead) {
    final futureDate = DateTime.now().add(Duration(days: daysAhead));
    return _firestore
        .collection('items')
        .where('householdId', isEqualTo: householdId)
        .where('expiryDate', isLessThanOrEqualTo: Timestamp.fromDate(futureDate))
        .where('expiryDate', isGreaterThanOrEqualTo: Timestamp.fromDate(DateTime.now()))
        .orderBy('expiryDate')
        .snapshots();
  }
}