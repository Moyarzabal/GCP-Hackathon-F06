import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

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
  AppStateNotifier() : super(AppState());

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
  return AppStateNotifier();
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