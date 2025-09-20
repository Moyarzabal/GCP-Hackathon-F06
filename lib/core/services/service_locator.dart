import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../features/products/data/datasources/firestore_product_datasource.dart';
import '../../features/products/data/datasources/product_datasource.dart';
import '../../features/products/data/repositories/product_repository_impl.dart';
import '../../features/products/domain/repositories/product_repository.dart';
import '../../features/auth/data/datasources/firebase_auth_datasource.dart';
import '../../features/auth/data/repositories/auth_repository_impl.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';
import '../../features/auth/domain/usecases/sign_in.dart';
import '../../features/auth/domain/usecases/sign_out.dart';
import '../../features/auth/domain/usecases/create_account.dart';

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
    _services[FirebaseAuth] = FirebaseAuth.instance;

    // Register data sources
    _services[ProductDataSource] = FirestoreProductDataSource(
      _services[FirebaseFirestore] as FirebaseFirestore,
    );
    _services[FirebaseAuthDatasource] = FirebaseAuthDatasourceImpl(
      _services[FirebaseAuth] as FirebaseAuth,
    );

    // Register repositories
    _services[ProductRepository] = ProductRepositoryImpl(
      _services[ProductDataSource] as ProductDataSource,
    );
    _services[AuthRepository] = AuthRepositoryImpl(
      _services[FirebaseAuthDatasource] as FirebaseAuthDatasource,
    );

    // Register use cases
    _services[SignIn] = SignIn(_services[AuthRepository] as AuthRepository);
    _services[SignOut] = SignOut(_services[AuthRepository] as AuthRepository);
    _services[CreateAccount] = CreateAccount(_services[AuthRepository] as AuthRepository);

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