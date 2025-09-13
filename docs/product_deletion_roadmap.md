# 商品削除機能 TDD ロードマップ

## 概要
冷蔵庫画面での商品削除機能をTest-Driven Development（TDD）で実装します。長押しで選択モードに入り、複数選択して削除できる機能を提供します。

## 要件
- 冷蔵庫画面で商品を長押しすると選択モードに切り替わる
- 選択モードで商品をタップすると複数選択可能
- 削除ボタンを押すと確認ダイアログが表示される
- 確認後、選択された商品がアプリとFirebaseから削除される

## 実装フェーズ

### Phase 1: テスト設計と基盤準備
- [ ] 商品削除機能のテストケース設計
- [ ] 選択状態管理のためのState設計
- [ ] 削除確認UIの設計

### Phase 2: 状態管理の実装
- [ ] 商品選択状態のStateNotifier実装
- [ ] 選択モードの切り替え機能
- [ ] 複数選択の管理機能

### Phase 3: UI実装
- [ ] 長押しジェスチャーの実装
- [ ] 選択モードUIの実装
- [ ] 削除ボタンの表示制御

### Phase 4: 削除機能の実装
- [ ] Firebase削除機能の実装
- [ ] 削除確認ダイアログの実装
- [ ] 削除後の状態更新

### Phase 5: 統合テストと最適化
- [ ] エンドツーエンドテスト
- [ ] パフォーマンス最適化
- [ ] ユーザビリティの向上

## 詳細実装計画

### 1. テスト設計

#### 1.1 単体テスト
```dart
// 商品選択状態のテスト
test('should enter selection mode on long press')
test('should select multiple products')
test('should exit selection mode')
test('should clear selection')

// 削除機能のテスト
test('should show confirmation dialog')
test('should delete selected products from Firebase')
test('should update local state after deletion')
test('should handle deletion errors')
```

#### 1.2 ウィジェットテスト
```dart
// UI操作のテスト
testWidgets('should show selection UI on long press')
testWidgets('should highlight selected products')
testWidgets('should show delete button when products selected')
testWidgets('should show confirmation dialog on delete')
```

#### 1.3 統合テスト
```dart
// エンドツーエンドテスト
test('should complete full deletion flow')
test('should handle network errors during deletion')
test('should maintain selection state across rebuilds')
```

### 2. 状態管理設計

#### 2.1 選択状態のState
```dart
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
}
```

#### 2.2 選択状態のNotifier
```dart
class ProductSelectionNotifier extends StateNotifier<ProductSelectionState> {
  // 選択モードの切り替え
  void toggleSelectionMode();
  
  // 商品の選択/選択解除
  void toggleProductSelection(String productId);
  
  // 全選択/全解除
  void selectAll();
  void clearSelection();
  
  // 削除実行
  Future<void> deleteSelectedProducts();
}
```

### 3. UI実装

#### 3.1 長押しジェスチャー
```dart
GestureDetector(
  onLongPress: () {
    // 選択モードに切り替え
  },
  child: ProductCard(...),
)
```

#### 3.2 選択モードUI
```dart
// 選択モード時のオーバーレイ
if (isSelectionMode)
  Positioned(
    top: 0,
    left: 0,
    child: Container(
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.3),
        border: Border.all(color: Colors.blue, width: 2),
      ),
      child: Checkbox(
        value: isSelected,
        onChanged: (value) => toggleSelection(productId),
      ),
    ),
  )
```

#### 3.3 削除ボタン
```dart
// 選択された商品がある場合のみ表示
if (selectedProducts.isNotEmpty)
  FloatingActionButton(
    onPressed: () => _showDeleteConfirmation(),
    backgroundColor: Colors.red,
    child: Icon(Icons.delete),
  )
```

### 4. 削除機能実装

#### 4.1 Firebase削除
```dart
// ProductDataSourceに削除メソッド追加
Future<void> deleteProducts(List<String> productIds) async {
  final batch = _firestore.batch();
  for (final id in productIds) {
    batch.delete(_firestore.collection('products').doc(id));
  }
  await batch.commit();
}
```

#### 4.2 削除確認ダイアログ
```dart
Future<bool> _showDeleteConfirmation() async {
  return await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('商品を削除'),
      content: Text('選択された${selectedCount}個の商品を削除しますか？'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: Text('キャンセル'),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, true),
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
          child: Text('削除'),
        ),
      ],
    ),
  ) ?? false;
}
```

### 5. エラーハンドリング

#### 5.1 削除エラーの処理
```dart
try {
  await deleteSelectedProducts();
  // 成功時の処理
} catch (e) {
  // エラー表示
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text('削除に失敗しました: ${e.toString()}'),
      backgroundColor: Colors.red,
    ),
  );
}
```

#### 5.2 部分削除の処理
```dart
// 一部の商品のみ削除成功した場合
if (deletedCount < selectedCount) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text('部分的な削除'),
      content: Text('${deletedCount}個の商品を削除しました。一部の商品は削除できませんでした。'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('OK'),
        ),
      ],
    ),
  );
}
```

## 実装順序

### Step 1: テストケース作成
1. `test/features/products/presentation/providers/product_selection_provider_test.dart`
2. `test/features/products/presentation/widgets/product_selection_test.dart`
3. `integration_test/product_deletion_test.dart`

### Step 2: 状態管理実装
1. `lib/features/products/presentation/providers/product_selection_provider.dart`
2. `lib/features/products/presentation/states/product_selection_state.dart`

### Step 3: UI実装
1. 長押しジェスチャーの追加
2. 選択モードUIの実装
3. 削除ボタンの実装

### Step 4: 削除機能実装
1. Firebase削除機能の実装
2. 削除確認ダイアログの実装
3. エラーハンドリングの実装

### Step 5: 統合とテスト
1. 統合テストの実行
2. パフォーマンステスト
3. ユーザビリティテスト

## 成功基準

- [ ] 長押しで選択モードに切り替わる
- [ ] 複数商品を選択できる
- [ ] 削除確認ダイアログが表示される
- [ ] Firebaseから商品が削除される
- [ ] ローカル状態が更新される
- [ ] エラーが適切に処理される
- [ ] テストが全て通る

## 注意事項

1. **パフォーマンス**: 大量の商品がある場合の選択処理を最適化
2. **ユーザビリティ**: 選択状態が分かりやすいUIを提供
3. **エラーハンドリング**: ネットワークエラーや部分削除の適切な処理
4. **アクセシビリティ**: スクリーンリーダー対応
5. **テストカバレッジ**: 全ての機能がテストでカバーされている

## 関連ファイル

- `lib/features/products/presentation/pages/home_screen.dart` - 冷蔵庫画面
- `lib/features/products/presentation/providers/product_provider.dart` - 商品管理
- `lib/features/products/data/datasources/firestore_product_datasource.dart` - Firebase操作
- `lib/shared/models/product.dart` - 商品モデル
