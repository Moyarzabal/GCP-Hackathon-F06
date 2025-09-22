import '../../../../shared/models/product.dart';

abstract class ProductDataSource {
  Future<List<Product>> getAllProducts();
  Future<List<Product>> getAllProductsIncludingDeleted(); // 履歴画面用（削除済み含む）
  Future<Product?> getProduct(String id);
  Future<String> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Stream<List<Product>> watchProducts();
}