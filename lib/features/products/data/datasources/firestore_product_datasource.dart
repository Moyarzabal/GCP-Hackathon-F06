import 'package:cloud_firestore/cloud_firestore.dart';
import 'product_datasource.dart';
import '../../../../shared/models/product.dart';
import '../../../../core/utils/logger.dart';

class FirestoreProductDataSource implements ProductDataSource {
  final FirebaseFirestore _firestore;
  static const String _collection = 'products';

  FirestoreProductDataSource(this._firestore);

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      Logger.debug('Fetching all products from Firestore');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('deletedAt', isNull: true) // 論理削除されていない商品のみ取得
          .orderBy('addedDate', descending: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();

      Logger.debug('Successfully fetched ${products.length} products');
      return products;
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while fetching products', e, e.stackTrace);
      throw Exception('Failed to get products: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while fetching products', e, stackTrace);
      throw Exception('Failed to get products: $e');
    }
  }

  @override
  Future<List<Product>> getAllProductsIncludingDeleted() async {
    try {
      Logger.debug('Fetching all products including deleted from Firestore');
      final querySnapshot = await _firestore
          .collection(_collection)
          .orderBy('addedDate', descending: true)
          .get();

      final products = querySnapshot.docs
          .map((doc) => Product.fromFirestore(doc.id, doc.data()))
          .toList();

      Logger.debug('Successfully fetched ${products.length} products (including deleted)');
      return products;
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while fetching all products including deleted', e, e.stackTrace);
      throw Exception('Failed to get all products including deleted: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while fetching all products including deleted', e, stackTrace);
      throw Exception('Failed to get all products including deleted: $e');
    }
  }

  @override
  Future<Product?> getProduct(String id) async {
    try {
      Logger.debug('Fetching product with id: $id');
      final doc = await _firestore.collection(_collection).doc(id).get();

      if (!doc.exists || doc.data() == null) {
        Logger.debug('Product with id $id not found');
        return null;
      }

      final product = Product.fromFirestore(doc.id, doc.data()!);
      Logger.debug('Successfully fetched product: ${product.name}');
      return product;
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while fetching product $id', e, e.stackTrace);
      throw Exception('Failed to get product: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while fetching product $id', e, stackTrace);
      throw Exception('Failed to get product: $e');
    }
  }

  @override
  Future<String> addProduct(Product product) async {
    try {
      Logger.debug('Adding product: ${product.name}');
      final data = product.toFirestore();
      data['addedDate'] = FieldValue.serverTimestamp();

      final docRef = await _firestore.collection(_collection).add(data);
      Logger.debug('Successfully added product with id: ${docRef.id}');
      return docRef.id;
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while adding product', e, e.stackTrace);
      throw Exception('Failed to add product: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while adding product', e, stackTrace);
      throw Exception('Failed to add product: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    if (product.id == null) {
      throw ArgumentError('Product ID is required for update');
    }

    try {
      Logger.debug('Updating product: ${product.name} (${product.id})');
      await _firestore
          .collection(_collection)
          .doc(product.id)
          .update(product.toFirestore());
      Logger.debug('Successfully updated product: ${product.id}');
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while updating product ${product.id}', e, e.stackTrace);
      throw Exception('Failed to update product: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while updating product ${product.id}', e, stackTrace);
      throw Exception('Failed to update product: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      Logger.debug('Soft deleting product with id: $id');
      final now = DateTime.now();
      await _firestore.collection(_collection).doc(id).update({
        'deletedAt': now.millisecondsSinceEpoch
      });
      Logger.debug('Successfully soft deleted product: $id');
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while soft deleting product $id', e, e.stackTrace);
      throw Exception('Failed to delete product: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while soft deleting product $id', e, stackTrace);
      throw Exception('Failed to delete product: $e');
    }
  }

  /// 複数商品を一括論理削除
  Future<void> deleteProducts(List<String> productIds) async {
    print('🗑️ FirestoreProductDataSource.deleteProducts: 開始');
    print('   削除対象商品数: ${productIds.length}');
    print('   削除対象商品ID: $productIds');

    if (productIds.isEmpty) {
      print('❌ 削除対象商品がありません');
      Logger.debug('No products to delete');
      return;
    }

    try {
      Logger.debug('Soft deleting ${productIds.length} products: $productIds');
      print('🔄 Firestore batch操作で一括論理削除を実行');

      // Firestore batch操作を使用して一括論理削除
      final batch = _firestore.batch();
      final now = DateTime.now();
      for (final id in productIds) {
        print('   商品ID $id にdeletedAt=${now.millisecondsSinceEpoch}を設定');
        batch.update(
          _firestore.collection(_collection).doc(id),
          {'deletedAt': now.millisecondsSinceEpoch}
        );
      }

      print('🔄 Firestore batch操作をコミット');
      await batch.commit();
      print('✅ Firestore batch操作完了');
      Logger.debug('Successfully soft deleted ${productIds.length} products');
    } on FirebaseException catch (e) {
      Logger.error('Firebase error while soft deleting products', e, e.stackTrace);
      throw Exception('Failed to delete products: ${e.message}');
    } catch (e, stackTrace) {
      Logger.error('Unexpected error while soft deleting products', e, stackTrace);
      throw Exception('Failed to delete products: $e');
    }
  }

  @override
  Stream<List<Product>> watchProducts() {
    try {
      Logger.debug('Starting to watch products stream');
      return _firestore
          .collection(_collection)
          .where('deletedAt', isNull: true) // 論理削除されていない商品のみ取得
          .orderBy('addedDate', descending: true)
          .snapshots()
          .map((snapshot) {
            final products = snapshot.docs
                .map((doc) => Product.fromFirestore(doc.id, doc.data()))
                .toList();
            Logger.debug('Products stream updated: ${products.length} products');
            return products;
          });
    } catch (e, stackTrace) {
      Logger.error('Error while setting up products stream', e, stackTrace);
      throw Exception('Failed to watch products: $e');
    }
  }
}