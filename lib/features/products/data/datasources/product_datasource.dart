import '../../../../shared/models/product.dart';

abstract class ProductDataSource {
  Future<List<Product>> getAllProducts();
  Future<Product?> getProduct(String id);
  Future<String> addProduct(Product product);
  Future<void> updateProduct(Product product);
  Future<void> deleteProduct(String id);
  Stream<List<Product>> watchProducts();
}