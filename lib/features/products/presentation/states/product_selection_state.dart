/// 商品選択状態を表すクラス
class ProductSelectionState {
  final bool isSelectionMode;
  final Set<String> selectedProductIds;
  final bool isDeleting;
  final String? error;

  const ProductSelectionState({
    this.isSelectionMode = false,
    this.selectedProductIds = const {},
    this.isDeleting = false,
    this.error,
  });

  /// 指定された商品が選択されているかどうかを確認
  bool isSelected(String productId) {
    return selectedProductIds.contains(productId);
  }

  /// 選択された商品の数を取得
  int get selectedCount => selectedProductIds.length;

  /// 状態をコピーして新しいインスタンスを作成
  ProductSelectionState copyWith({
    bool? isSelectionMode,
    Set<String>? selectedProductIds,
    bool? isDeleting,
    String? error,
  }) {
    return ProductSelectionState(
      isSelectionMode: isSelectionMode ?? this.isSelectionMode,
      selectedProductIds: selectedProductIds ?? this.selectedProductIds,
      isDeleting: isDeleting ?? this.isDeleting,
      error: error,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductSelectionState &&
        other.isSelectionMode == isSelectionMode &&
        other.selectedProductIds == selectedProductIds &&
        other.isDeleting == isDeleting &&
        other.error == error;
  }

  @override
  int get hashCode {
    return Object.hash(
      isSelectionMode,
      selectedProductIds,
      isDeleting,
      error,
    );
  }

  @override
  String toString() {
    return 'ProductSelectionState('
        'isSelectionMode: $isSelectionMode, '
        'selectedProductIds: $selectedProductIds, '
        'isDeleting: $isDeleting, '
        'error: $error'
        ')';
  }
}
