import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';
import '../../features/products/data/datasources/product_datasource.dart';
import '../../features/products/data/providers/product_data_source_provider.dart';
import '../../core/errors/result.dart';

/// アプリケーションの基本状態を管理するプロバイダー
class AppState {
  final List<Product> products;
  final bool isLoading;
  final String? error;
  final int selectedBottomNavIndex;

  AppState({
    this.products = const [],
    this.isLoading = false,
    this.error,
    this.selectedBottomNavIndex = 0,
  });

  AppState copyWith({
    List<Product>? products,
    bool? isLoading,
    String? error,
    int? selectedBottomNavIndex,
  }) {
    return AppState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      selectedBottomNavIndex: selectedBottomNavIndex ?? this.selectedBottomNavIndex,
    );
  }
}

/// アプリケーション状態のStateNotifier
class AppStateNotifier extends StateNotifier<AppState> {
  final ProductDataSource? _dataSource;
  StreamSubscription<List<Product>>? _productsSubscription;

  AppStateNotifier([this._dataSource]) : super(AppState());

  /// 商品を追加
  void addProduct(Product product) {
    final updatedProducts = [product, ...state.products];
    state = state.copyWith(products: updatedProducts);
  }

  /// 商品を更新
  void updateProduct(Product updatedProduct) {
    final updatedProducts = state.products.map((product) {
      return product.id == updatedProduct.id ? updatedProduct : product;
    }).toList();
    state = state.copyWith(products: updatedProducts);
  }

  /// 商品を削除
  void removeProduct(String productId) {
    final updatedProducts = state.products.where((product) => product.id != productId).toList();
    state = state.copyWith(products: updatedProducts);
  }

  /// ボトムナビゲーションのインデックスを変更
  void setBottomNavIndex(int index) {
    state = state.copyWith(selectedBottomNavIndex: index);
  }

  /// ローディング状態を設定
  void setLoading(bool isLoading) {
    state = state.copyWith(isLoading: isLoading);
  }

  /// エラーメッセージを設定
  void setError(String? error) {
    state = state.copyWith(error: error);
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// 商品の画像を更新
  void updateProductImage(String productId, String imageUrl) {
    print('🔄 updateProductImage called: productId=$productId, imageUrl=$imageUrl');
    print('📦 Current products count: ${state.products.length}');
    
    final updatedProducts = state.products.map((product) {
      if (product.id == productId) {
        print('✅ Found product to update: ${product.name}');
        print('    Old imageUrl: ${product.imageUrl}');
        print('    New imageUrl: $imageUrl');
        return product.copyWith(imageUrl: imageUrl);
      }
      return product;
    }).toList();
    
    print('📦 Updated products count: ${updatedProducts.length}');
    state = state.copyWith(products: updatedProducts);
    print('✅ updateProductImage completed');
  }

  /// Firebaseから商品を読み込み
  Future<void> loadProductsFromFirebase() async {
    if (_dataSource == null) {
      setError('Firebase data source is not available');
      return;
    }

    try {
      setLoading(true);
      clearError();

      print('🔄 loadProductsFromFirebase: 開始');
      final products = await _dataSource!.getAllProducts();
      print('✅ loadProductsFromFirebase: ${products.length}個の商品を読み込み');
      
      // 各商品のimageUrlsを確認
      for (var product in products) {
        print('   商品ID: ${product.id}, 名前: ${product.name}');
        print('   imageUrl: ${product.imageUrl}');
        print('   imageUrls: ${product.imageUrls?.length ?? 0}個の段階');
        if (product.imageUrls != null) {
          for (var entry in product.imageUrls!.entries) {
            print('     ${entry.key.name}: ${entry.value}');
          }
        }
      }
      
      state = state.copyWith(products: products, isLoading: false);
    } catch (e) {
      print('❌ loadProductsFromFirebase エラー: $e');
      setError('Failed to load products from Firebase: $e');
      setLoading(false);
    }
  }

  /// Firebaseに商品を追加
  Future<Product> addProductToFirebase(Product product) async {
    if (_dataSource == null) {
      setError('Firebase data source is not available');
      throw Exception('Firebase data source is not available');
    }

    try {
      setLoading(true);
      clearError();

      final productId = await _dataSource!.addProduct(product);
      final productWithId = product.copyWith(id: productId);
      
      // ローカル状態も更新
      addProduct(productWithId);
      setLoading(false);
      
      return productWithId;
    } catch (e) {
      setError('Failed to add product to Firebase: $e');
      setLoading(false);
      rethrow;
    }
  }

  /// Firebaseで商品を更新
  Future<void> updateProductInFirebase(Product product) async {
    if (_dataSource == null) {
      setError('Firebase data source is not available');
      return;
    }

    if (product.id == null) {
      setError('Product ID is required for update');
      return;
    }

    try {
      setLoading(true);
      clearError();

      await _dataSource!.updateProduct(product);
      
      // ローカル状態も更新
      updateProduct(product);
      setLoading(false);
    } catch (e) {
      setError('Failed to update product in Firebase: $e');
      setLoading(false);
    }
  }

  /// Firebaseから商品を削除
  Future<void> deleteProductFromFirebase(String productId) async {
    if (_dataSource == null) {
      setError('Firebase data source is not available');
      return;
    }

    try {
      setLoading(true);
      clearError();

      await _dataSource!.deleteProduct(productId);
      
      // ローカル状態も更新
      removeProduct(productId);
      setLoading(false);
    } catch (e) {
      setError('Failed to delete product from Firebase: $e');
      setLoading(false);
    }
  }

  /// Firebaseの商品ストリームを監視
  void watchProductsFromFirebase() {
    if (_dataSource == null) {
      setError('Firebase data source is not available');
      return;
    }

    try {
      _productsSubscription?.cancel();
      _productsSubscription = _dataSource!.watchProducts().listen(
        (products) {
          state = state.copyWith(products: products);
        },
        onError: (error) {
          setError('Failed to watch products from Firebase: $error');
        },
      );
    } catch (e) {
      setError('Failed to start watching products from Firebase: $e');
    }
  }

  /// リソースをクリーンアップ
  @override
  void dispose() {
    _productsSubscription?.cancel();
    super.dispose();
  }

  /// 商品の複数段階画像を更新
  void updateProductMultiStageImages(String productId, Map<ImageStage, String> imageUrls) {
    print('🔄 updateProductMultiStageImages called: productId=$productId');
    print('📦 Current products count: ${state.products.length}');
    print('🖼️ Image URLs count: ${imageUrls.length}');

    final updatedProducts = state.products.map((product) {
      if (product.id == productId) {
        print('✅ Found product to update: ${product.name}');
        print('    Old imageUrls: ${product.imageUrls?.length ?? 0} stages');
        print('    New imageUrls: ${imageUrls.length} stages');

        // 既存のimageUrlも保持（後方互換性のため）
        final currentImageUrl = product.imageUrl;

        return product.copyWith(
          imageUrls: imageUrls,
          imageUrl: currentImageUrl, // 既存のimageUrlを保持
        );
      }
      return product;
    }).toList();

    print('📦 Updated products count: ${updatedProducts.length}');
    state = state.copyWith(products: updatedProducts);
    print('✅ updateProductMultiStageImages completed');
  }
}

/// アプリケーション状態プロバイダー
final appStateProvider = StateNotifierProvider<AppStateNotifier, AppState>((ref) {
  // FirebaseDataSourceを注入（利用可能な場合）
  final dataSource = ref.watch(productDataSourceProvider);
  return AppStateNotifier(dataSource);
});

/// 商品リストを取得する便利プロバイダー
final productsProvider = Provider<List<Product>>((ref) {
  return ref.watch(appStateProvider).products;
});

/// 期限切れ間近の商品を取得するプロバイダー
final expiringProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((product) => product.daysUntilExpiry <= 3).toList();
});

/// 期限切れの商品を取得するプロバイダー
final expiredProductsProvider = Provider<List<Product>>((ref) {
  final products = ref.watch(productsProvider);
  return products.where((product) => product.daysUntilExpiry <= 0).toList();
});