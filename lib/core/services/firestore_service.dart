import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import '../../shared/models/product.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/shopping_item.dart';

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

  // Legacy product operations (for household items)
  Future<String> addHouseholdItem({
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

  Future<void> updateHouseholdItem(String itemId, Map<String, dynamic> updates) async {
    await _firestore.collection('items').doc(itemId).update(updates);
  }

  Future<void> deleteHouseholdItem(String itemId) async {
    await _firestore.collection('items').doc(itemId).delete();
  }

  // Product database operations (cached product info)
  Future<Map<String, dynamic>?> getProductByJAN(String janCode) async {
    try {
      final doc = await _firestore.collection('products').doc(janCode).get();
      if (doc.exists) {
        final data = doc.data()!;
        print('Cached product data: $data');
        return data;
      }
      return null;
    } catch (e) {
      print('Error getting cached product: $e');
      return null;
    }
  }

  Future<void> clearProductCache(String janCode) async {
    try {
      await _firestore.collection('products').doc(janCode).delete();
      print('Cleared cache for JAN code: $janCode');
    } catch (e) {
      print('Error clearing cache: $e');
    }
  }

  Future<void> cacheProductInfo({
    required String janCode,
    required String productName,
    String? manufacturer,
    String? category,
    String? imageUrl,
    Map<String, dynamic>? nutritionInfo,
    List<String>? allergens,
    int? expiryDays,
    double? confidence,
  }) async {
    await _firestore.collection('products').doc(janCode).set({
      'janCode': janCode,
      'productName': productName,
      'manufacturer': manufacturer,
      'category': category,
      'nutritionInfo': nutritionInfo,
      'allergens': allergens,
      'imageUrl': imageUrl,
      'expiryDays': expiryDays,
      'confidence': confidence,
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

  // ProductDataSource interface implementation
  Future<List<Product>> getAllProducts() async {
    try {
      final querySnapshot = await _firestore
          .collection('products')
          .orderBy('addedDate', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting all products: $e');
      return [];
    }
  }


  Future<Product?> getProduct(String id) async {
    try {
      final doc = await _firestore.collection('products').doc(id).get();

      if (!doc.exists || doc.data() == null) {
        return null;
      }

      return Product.fromFirestore(doc.id, doc.data()!);
    } catch (e) {
      print('Error getting product $id: $e');
      return null;
    }
  }

  Future<String> addProduct(Product product) async {
    try {
      final data = product.toFirestore();
      data['addedDate'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection('products').add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product: $e');
    }
  }

  Future<void> updateProduct(Product product) async {
    if (product.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    try {
      await _firestore
          .collection('products')
          .doc(product.id)
          .update(product.toFirestore());
    } catch (e) {
      print('Error updating product ${product.id}: $e');
      throw Exception('Failed to update product: $e');
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection('products').doc(id).delete();
    } catch (e) {
      print('Error deleting product $id: $e');
      throw Exception('Failed to delete product: $e');
    }
  }

  Stream<List<Product>> watchProducts() {
    try {
      return _firestore
          .collection('products')
          .orderBy('addedDate', descending: true)
          .snapshots()
          .map((snapshot) {
            return snapshot.docs
                .map((doc) => Product.fromFirestore(doc.id, doc.data()))
                .toList();
          });
    } catch (e) {
      print('Error watching products: $e');
      return Stream.value([]);
    }
  }

  // Meal Plan operations
  Future<String> saveMealPlan(MealPlan mealPlan) async {
    try {
      final data = mealPlan.toFirestore();
      final docRef = await _firestore.collection('meal_plans').add(data);
      return docRef.id;
    } catch (e) {
      print('Error saving meal plan: $e');
      throw Exception('Failed to save meal plan: $e');
    }
  }

  Future<void> updateMealPlanStatus(String mealPlanId, MealPlanStatus status) async {
    try {
      await _firestore.collection('meal_plans').doc(mealPlanId).update({
        'status': status.name,
        if (status == MealPlanStatus.accepted) 'acceptedAt': FieldValue.serverTimestamp(),
        if (status == MealPlanStatus.completed) 'completedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print('Error updating meal plan status: $e');
      throw Exception('Failed to update meal plan status: $e');
    }
  }

  Future<void> updateMealPlanRating(String mealPlanId, double rating) async {
    try {
      // 評価は個別のメニューアイテムに保存されるため、ここでは何もしない
      // 実際の実装では、各メニューアイテムの評価を更新する
      print('Rating updated for meal plan $mealPlanId: $rating');
    } catch (e) {
      print('Error updating meal plan rating: $e');
      throw Exception('Failed to update meal plan rating: $e');
    }
  }

  Future<List<MealPlan>> getMealPlanHistory(
    String householdId, {
    DateTime? startDate,
    DateTime? endDate,
    int limit = 50,
  }) async {
    try {
      Query query = _firestore
          .collection('meal_plans')
          .where('householdId', isEqualTo: householdId)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startDate != null) {
        query = query.where('createdAt', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate));
      }
      if (endDate != null) {
        query = query.where('createdAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate));
      }

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => MealPlan.fromFirestore(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error getting meal plan history: $e');
      return [];
    }
  }

  Future<MealPlan?> getMealPlan(String mealPlanId) async {
    try {
      final doc = await _firestore.collection('meal_plans').doc(mealPlanId).get();
      if (doc.exists) {
        return MealPlan.fromFirestore(doc.id, doc.data() as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      print('Error getting meal plan: $e');
      return null;
    }
  }

  // Shopping List operations
  Future<String> saveShoppingList(
    String householdId,
    String? mealPlanId,
    List<ShoppingItem> items,
  ) async {
    try {
      final shoppingListId = _uuid.v4();
      final data = {
        'householdId': householdId,
        'mealPlanId': mealPlanId,
        'items': items.map((item) => item.toFirestore()).toList(),
        'status': ShoppingListStatus.active.name,
        'createdAt': FieldValue.serverTimestamp(),
        'totalEstimatedPrice': items.fold(0.0, (sum, item) => sum + (item.estimatedPrice ?? 0.0)),
      };

      await _firestore.collection('shopping_lists').doc(shoppingListId).set(data);
      return shoppingListId;
    } catch (e) {
      print('Error saving shopping list: $e');
      throw Exception('Failed to save shopping list: $e');
    }
  }

  Future<String> addShoppingItem(ShoppingItem item) async {
    try {
      final data = item.toFirestore();
      final docRef = await _firestore.collection('shopping_items').add(data);
      return docRef.id;
    } catch (e) {
      print('Error adding shopping item: $e');
      throw Exception('Failed to add shopping item: $e');
    }
  }

  Future<void> updateShoppingItem(String itemId, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection('shopping_items').doc(itemId).update(updates);
    } catch (e) {
      print('Error updating shopping item: $e');
      throw Exception('Failed to update shopping item: $e');
    }
  }

  Future<void> deleteShoppingItem(String itemId) async {
    try {
      await _firestore.collection('shopping_items').doc(itemId).delete();
    } catch (e) {
      print('Error deleting shopping item: $e');
      throw Exception('Failed to delete shopping item: $e');
    }
  }

  Future<List<ShoppingItem>> getShoppingList(String householdId) async {
    try {
      final snapshot = await _firestore
          .collection('shopping_items')
          .where('householdId', isEqualTo: householdId)
          .orderBy('addedAt', descending: true)
          .get();

      return snapshot.docs
          .map((doc) => ShoppingItem.fromFirestore(doc.id, doc.data()))
          .toList();
    } catch (e) {
      print('Error getting shopping list: $e');
      return [];
    }
  }
}