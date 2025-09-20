import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../core/services/category_service.dart';
import '../../../../shared/models/category.dart';

/// ソート方向
enum SortDirection {
  ascending('昇順'),
  descending('降順');

  const SortDirection(this.displayName);
  final String displayName;
}

/// 商品管理の状態を表すクラス
class ProductState {
  final List<Product> filteredProducts;
  final String searchQuery;
  final String selectedCategory;
  final ProductSortType sortType;
  final SortDirection sortDirection;
  final bool isLoading;
  final String? error;

  const ProductState({
    this.filteredProducts = const [],
    this.searchQuery = '',
    this.selectedCategory = 'すべて',
    this.sortType = ProductSortType.expiryDate,
    this.sortDirection = SortDirection.ascending,
    this.isLoading = false,
    this.error,
  });

  ProductState copyWith({
    List<Product>? filteredProducts,
    String? searchQuery,
    String? selectedCategory,
    ProductSortType? sortType,
    SortDirection? sortDirection,
    bool? isLoading,
    String? error,
  }) {
    return ProductState(
      filteredProducts: filteredProducts ?? this.filteredProducts,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategory: selectedCategory ?? this.selectedCategory,
      sortType: sortType ?? this.sortType,
      sortDirection: sortDirection ?? this.sortDirection,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

/// 商品のソートタイプ
enum ProductSortType {
  name('名前順'),
  expiryDate('賞味期限順'),
  addedDate('追加日順'),
  category('カテゴリ順');

  const ProductSortType(this.displayName);
  final String displayName;
}

/// 商品管理状態を管理するStateNotifier
class ProductNotifier extends StateNotifier<ProductState> {
  final Ref _ref;

  ProductNotifier(this._ref) : super(const ProductState()) {
    // 初期フィルタリングは遅延実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyFilters();
    });

    // appStateProviderの変更を監視してフィルタリングを再実行
    _ref.listen(appStateProvider, (previous, next) {
      if (previous?.products != next.products) {
        _applyFilters();
      }
    });
  }

  /// 商品を検索
  void searchProducts(String query) {
    state = state.copyWith(searchQuery: query.toLowerCase());
    _applyFilters();
  }

  /// カテゴリフィルターを設定
  void filterByCategory(String category) {
    state = state.copyWith(selectedCategory: category);
    _applyFilters();
  }

  /// ソートタイプを変更
  void setSortType(ProductSortType sortType) {
    // 同じソートタイプが選択された場合は方向を切り替え
    if (state.sortType == sortType) {
      final newDirection = state.sortDirection == SortDirection.ascending
          ? SortDirection.descending
          : SortDirection.ascending;
      state = state.copyWith(sortDirection: newDirection);
    } else {
      // 異なるソートタイプの場合は昇順で開始
      state = state.copyWith(
        sortType: sortType,
        sortDirection: SortDirection.ascending,
      );
    }
    _applyFilters();
  }

  /// ソート方向を切り替え
  void toggleSortDirection() {
    final newDirection = state.sortDirection == SortDirection.ascending
        ? SortDirection.descending
        : SortDirection.ascending;
    state = state.copyWith(sortDirection: newDirection);
    _applyFilters();
  }

  /// フィルターとソートを適用
  void _applyFilters() {
    try {
      final allProducts = _ref.read(appStateProvider).products;
      var filteredProducts = <Product>[...allProducts];

      // 論理削除フィルターはFirebaseクエリレベルで実行されるため、ここでは不要

      // 検索フィルター
      if (state.searchQuery.isNotEmpty) {
        filteredProducts = filteredProducts.where((product) {
          return product.name.toLowerCase().contains(state.searchQuery) ||
                 product.category.toLowerCase().contains(state.searchQuery) ||
                 (product.janCode?.contains(state.searchQuery) ?? false);
        }).toList();
      }

      // カテゴリフィルター
      if (state.selectedCategory != 'すべて') {
        filteredProducts = filteredProducts.where((product) {
          return product.category == state.selectedCategory;
        }).toList();
      }

      // ソート
      filteredProducts.sort((a, b) {
        int comparison;
        switch (state.sortType) {
          case ProductSortType.name:
            comparison = a.name.compareTo(b.name);
            break;
          case ProductSortType.expiryDate:
            if (a.expiryDate == null && b.expiryDate == null) return 0;
            if (a.expiryDate == null) return 1;
            if (b.expiryDate == null) return -1;
            comparison = a.expiryDate!.compareTo(b.expiryDate!);
            break;
          case ProductSortType.addedDate:
            if (a.addedDate == null && b.addedDate == null) return 0;
            if (a.addedDate == null) return 1;
            if (b.addedDate == null) return -1;
            comparison = a.addedDate!.compareTo(b.addedDate!);
            break;
          case ProductSortType.category:
            final categoryCompare = a.category.compareTo(b.category);
            if (categoryCompare != 0) {
              comparison = categoryCompare;
            } else {
              comparison = a.name.compareTo(b.name);
            }
            break;
        }

        // 降順の場合は比較結果を反転
        return state.sortDirection == SortDirection.descending
            ? -comparison
            : comparison;
      });

      state = state.copyWith(
        filteredProducts: filteredProducts,
        error: null,
      );
    } catch (e, stackTrace) {
      final exception = ValidationException(
        'フィルタリングに失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );

      state = state.copyWith(error: exception.message);
    }
  }

  /// 商品を編集
  Future<Result<void>> editProduct(String productId, Product updatedProduct) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Firebaseで商品を更新
      await _ref.read(appStateProvider.notifier).updateProductInFirebase(updatedProduct);

      // フィルターを再適用
      _applyFilters();

      state = state.copyWith(isLoading: false);
      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = DatabaseException(
        '商品の更新に失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: exception.message,
      );

      return Result.failure(exception);
    }
  }

  /// 商品を削除
  Future<Result<void>> deleteProduct(String productId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      // Firebaseから商品を削除
      await _ref.read(appStateProvider.notifier).deleteProductFromFirebase(productId);

      // フィルターを再適用
      _applyFilters();

      state = state.copyWith(isLoading: false);
      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = DatabaseException(
        '商品の削除に失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: exception.message,
      );

      return Result.failure(exception);
    }
  }

  /// 選択された商品を一括削除
  Future<Result<void>> deleteSelectedProducts(List<String> productIds) async {
    print('🗑️ ProductProvider.deleteSelectedProducts: 開始');
    print('   削除対象商品数: ${productIds.length}');
    print('   削除対象商品ID: $productIds');

    if (productIds.isEmpty) {
      print('❌ 削除対象商品がありません');
      return Result.success(null);
    }

    try {
      state = state.copyWith(isLoading: true, error: null);

      // Firebaseから選択された商品を一括削除
      print('🔄 AppStateProvider.deleteProductsFromFirebaseを呼び出し');
      await _ref.read(appStateProvider.notifier).deleteProductsFromFirebase(productIds);
      print('✅ AppStateProvider.deleteProductsFromFirebase完了');

      // フィルターを再適用
      print('🔄 フィルターを再適用');
      _applyFilters();
      print('✅ フィルター再適用完了');

      state = state.copyWith(isLoading: false);
      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = DatabaseException(
        '商品の一括削除に失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );

      state = state.copyWith(
        isLoading: false,
        error: exception.message,
      );

      return Result.failure(exception);
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// フィルターをリセット
  void resetFilters() {
    state = const ProductState();
    _applyFilters();
  }

  /// 利用可能なカテゴリを取得
  List<String> getAvailableCategories() {
    return ['すべて', ..._defaultCategories];
  }
}

/// 商品管理プロバイダー
final productProvider = StateNotifierProvider<ProductNotifier, ProductState>((ref) {
  final notifier = ProductNotifier(ref);

  // 商品リストが変更されたらフィルターを再適用（遅延実行）
  ref.listen(appStateProvider, (previous, next) {
    if (previous?.products != next.products) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        notifier._applyFilters();
      });
    }
  });

  return notifier;
});

/// フィルターされた商品リストを取得するプロバイダー
final filteredProductsProvider = Provider<List<Product>>((ref) {
  return ref.watch(productProvider).filteredProducts;
});


/// デフォルトカテゴリ一覧（商品追加時と同じ）
const List<String> _defaultCategories = [
  '野菜',
  '果物',
  '肉類',
  '魚介類',
  '乳製品',
  '穀物',
  '飲料',
  '食品',
  '調味料',
  '冷凍食品',
  'その他'
];

/// 利用可能なカテゴリを取得するプロバイダー
final availableCategoriesProvider = FutureProvider<List<String>>((ref) async {
  try {
    final appState = ref.watch(appStateProvider);
    final householdId = appState.currentHouseholdId;

    if (householdId == null) {
      // 世帯IDが取得できない場合はデフォルトカテゴリを返す
      return ['すべて', ..._defaultCategories];
    }

    final categoryService = CategoryService();
    final categories = await categoryService.getCategories(householdId);

    return ['すべて', ...categories.map((c) => c.name).toList()];
  } catch (e) {
    print('Error getting categories: $e');
    // エラーの場合はデフォルトカテゴリを返す
    return ['すべて', ..._defaultCategories];
  }
});