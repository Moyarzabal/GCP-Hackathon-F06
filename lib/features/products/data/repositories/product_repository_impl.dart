import '../../domain/repositories/product_repository.dart';
import '../datasources/product_datasource.dart';
import '../../../../shared/models/product.dart';

class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;

  ProductRepositoryImpl(this._dataSource);

  @override
  Future<List<Product>> getAllProducts() async {
    try {
      return await _dataSource.getAllProducts();
    } catch (e) {
      throw Exception('Failed to get products from repository: $e');
    }
  }

  @override
  Future<Product?> getProduct(String id) async {
    try {
      return await _dataSource.getProduct(id);
    } catch (e) {
      throw Exception('Failed to get product from repository: $e');
    }
  }

  @override
  Future<String> addProduct(Product product) async {
    try {
      return await _dataSource.addProduct(product);
    } catch (e) {
      throw Exception('Failed to add product to repository: $e');
    }
  }

  @override
  Future<void> updateProduct(Product product) async {
    try {
      await _dataSource.updateProduct(product);
    } catch (e) {
      throw Exception('Failed to update product in repository: $e');
    }
  }

  @override
  Future<void> deleteProduct(String id) async {
    try {
      await _dataSource.deleteProduct(id);
    } catch (e) {
      throw Exception('Failed to delete product from repository: $e');
    }
  }

  @override
  Stream<List<Product>> watchProducts() {
    try {
      return _dataSource.watchProducts();
    } catch (e) {
      throw Exception('Failed to watch products from repository: $e');
    }
  }
}
