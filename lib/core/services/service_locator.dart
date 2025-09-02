import 'package:cloud_firestore/cloud_firestore.dart';
import '../../features/products/data/datasources/firestore_product_datasource.dart';
import '../../features/products/data/datasources/product_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';

class ServiceLocator {
  static final ServiceLocator _instance = ServiceLocator._internal();
  static ServiceLocator get instance => _instance;
  ServiceLocator._internal();

  final Map<Type, dynamic> _services = {};
  bool _initialized = false;

  /// Initialize all services
  void init() {
    if (_initialized) return;

    // Register Firebase services
    _services[FirebaseFirestore] = FirebaseFirestore.instance;

    // Register data sources
    _services[ProductDataSource] = FirestoreProductDataSource(
      _services[FirebaseFirestore] as FirebaseFirestore,
    );

    // Register repositories
    _services[ProductRepository] = ProductRepositoryImpl(
      _services[ProductDataSource] as ProductDataSource,
    );

    _initialized = true;
  }

  /// Get a service by type
  T get<T>() {
    if (!_initialized) {
      throw StateError('ServiceLocator not initialized. Call init() first.');
    }
    
    final service = _services[T];
    if (service == null) {
      throw ArgumentError('Service of type $T not registered');
    }
    return service as T;
  }

  /// Register a service (for testing)
  void register<T>(T service) {
    _services[T] = service;
  }

  /// Reset all services (for testing)
  void reset() {
    _services.clear();
    _initialized = false;
  }
}