import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../states/product_selection_state.dart';
import 'product_provider.dart';
import '../../../../core/errors/result.dart';
import '../../../../core/errors/app_exception.dart';

/// 商品選択状態を管理するStateNotifier
class ProductSelectionNotifier extends StateNotifier<ProductSelectionState> {
  final Ref _ref;

  ProductSelectionNotifier(this._ref) : super(const ProductSelectionState());

  /// 選択モードの切り替え
  void toggleSelectionMode() {
    if (state.isSelectionMode) {
      // 選択モードを終了し、選択をクリア
      state = state.copyWith(
        isSelectionMode: false,
        selectedProductIds: const {},
        error: null,
      );
    } else {
      // 選択モードを開始
      state = state.copyWith(
        isSelectionMode: true,
        selectedProductIds: const {},
        error: null,
      );
    }
  }

  /// 商品の選択/選択解除
  void toggleProductSelection(String productId) {
    if (!state.isSelectionMode) {
      // 選択モードでない場合は何もしない
      return;
    }

    final newSelectedIds = Set<String>.from(state.selectedProductIds);
    if (newSelectedIds.contains(productId)) {
      newSelectedIds.remove(productId);
    } else {
      newSelectedIds.add(productId);
    }

    state = state.copyWith(selectedProductIds: newSelectedIds);
  }

  /// 全商品を選択
  void selectAll(List<String> productIds) {
    if (!state.isSelectionMode) {
      // 選択モードでない場合は何もしない
      return;
    }

    state = state.copyWith(selectedProductIds: productIds.toSet());
  }

  /// 選択をクリア
  void clearSelection() {
    state = state.copyWith(selectedProductIds: const {});
  }

  /// 選択された商品を削除
  Future<Result<void>> deleteSelectedProducts() async {
    print('🗑️ ProductSelectionNotifier.deleteSelectedProducts: 開始');
    print('   選択された商品数: ${state.selectedProductIds.length}');
    print('   選択された商品ID: ${state.selectedProductIds}');

    if (state.selectedProductIds.isEmpty) {
      print('❌ 削除する商品が選択されていません');
      return Result.failure(
        ValidationException('削除する商品が選択されていません'),
      );
    }

    try {
      state = state.copyWith(isDeleting: true, error: null);

      // ProductProviderの一括削除機能を使用
      final productNotifier = _ref.read(productProvider.notifier);
      print('🔄 ProductProvider.deleteSelectedProductsを呼び出し');
      final result = await productNotifier.deleteSelectedProducts(
        state.selectedProductIds.toList(),
      );

      print('✅ ProductProvider.deleteSelectedProducts完了: ${result.isSuccess}');

      if (result.isSuccess) {
        // 削除成功時は選択をクリアし、選択モードを終了
        state = state.copyWith(
          isSelectionMode: false,
          selectedProductIds: const {},
          isDeleting: false,
          error: null,
        );
        return Result.success(null);
      } else {
        // 削除失敗時はエラーを設定
        state = state.copyWith(
          isDeleting: false,
          error: result.exception?.message ?? '削除に失敗しました',
        );
        return result;
      }
    } catch (e) {
      state = state.copyWith(
        isDeleting: false,
        error: '削除中にエラーが発生しました: $e',
      );
      return Result.failure(
        DatabaseException('削除中にエラーが発生しました', details: e.toString()),
      );
    }
  }

  /// 削除状態を設定
  void setDeleting(bool isDeleting) {
    state = state.copyWith(isDeleting: isDeleting);
  }

  /// エラーメッセージを設定
  void setError(String error) {
    state = state.copyWith(error: error);
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// 商品選択プロバイダー
final productSelectionProvider =
    StateNotifierProvider<ProductSelectionNotifier, ProductSelectionState>(
        (ref) {
  return ProductSelectionNotifier(ref);
});
