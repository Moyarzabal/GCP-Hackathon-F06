# 献立画面UI改善 - 詳細実装計画書

## 📋 プロジェクト概要

**目標**: 献立提案画面のユーザビリティとデザイン統一性を向上させる
**期間**: 3-5日間（優先度別に段階実装）
**対象ファイル**: 8ファイル

---

## 🎯 改善要件詳細

### 1. レシピ詳細画面の修正 【優先度: 高】
**問題**: 準備時間の表示でレイアウトがはみ出している
**対象ファイル**: `lib/features/meal_planning/presentation/widgets/meal_detail_dialog.dart`

#### 実装詳細:
```dart
// 削除対象: 準備時間の表示部分
// Before:
Row(
  children: [
    Icon(Icons.access_time),
    Text('準備時間: ${recipe.prepTime}分'),
  ],
),

// After: 削除
```

#### 影響範囲:
- レシピ詳細ダイアログのレイアウト
- 調理時間表示（保持）
- 材料リスト表示（保持）

---

### 2. メニューブロックの境界線追加 【優先度: 高】
**問題**: 主菜・副菜・汁物のブロックが背景と区別しにくい
**対象ファイル**: `lib/features/meal_planning/presentation/widgets/meal_plan_square_card.dart`

#### 実装詳細:
```dart
// 境界線スタイル統一
Container(
  decoration: BoxDecoration(
    color: _baseColor.withOpacity(0.8),
    border: Border.all(
      color: _primaryColor.withOpacity(0.4),
      width: 2,
    ),
    borderRadius: BorderRadius.circular(12),
    boxShadow: [
      BoxShadow(
        color: _primaryColor.withOpacity(0.1),
        blurRadius: 4,
        offset: Offset(0, 2),
      ),
    ],
  ),
  child: // 既存のコンテンツ
)
```

#### カラー定義:
```dart
static const Color _baseColor = Color(0xFFF6EACB);
static const Color _primaryColor = Color(0xFFD4A574);
static const Color _secondaryColor = Color(0xFFB8956A);
static const Color _accentColor = Color(0xFF8B7355);
static const Color _textColor = Color(0xFF5D4E37);
```

---

### 3. 再提案確認ダイアログ 【優先度: 中】
**問題**: 再提案ボタンを押すと即座に実行される
**対象ファイル**: `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart`

#### 実装詳細:
```dart
// 新規メソッド追加
void _showReSuggestConfirmation() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: _baseColor,
      title: Text(
        '献立を再提案しますか？',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Text(
        '現在の献立が新しい提案に置き換わります。',
        style: TextStyle(color: _accentColor),
      ),
      actions: [
        TextButton(
          child: Text('キャンセル', style: TextStyle(color: _accentColor)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text('再提案'),
          onPressed: () {
            Navigator.of(context).pop();
            _suggestMealPlan();
          },
        ),
      ],
    ),
  );
}

// 既存の再提案ボタンのonPressedを変更
IconButton(
  icon: Icon(Icons.refresh),
  onPressed: () => _showReSuggestConfirmation(), // 変更
),
```

---

### 4. 献立決定時の食材削除確認 【優先度: 高】
**問題**: 献立決定時に冷蔵庫から食材が自動削除される
**対象ファイル**: `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart`

#### 実装詳細:
```dart
// 新規メソッド追加
void _showMealDecisionConfirmation(MealPlan mealPlan) {
  // 使用する食材を抽出
  final ingredients = <String>[];
  ingredients.addAll(mealPlan.mainDish.ingredients.map((i) => i.name));
  ingredients.addAll(mealPlan.sideDish.ingredients.map((i) => i.name));
  ingredients.addAll(mealPlan.soup.ingredients.map((i) => i.name));

  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: _baseColor,
      title: Text(
        'この献立で決定しますか？',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.bold,
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '以下の食材を冷蔵庫から削除します：',
            style: TextStyle(color: _accentColor),
          ),
          SizedBox(height: 8),
          Container(
            height: 150,
            child: ListView.builder(
              itemCount: ingredients.length,
              itemBuilder: (context, index) => Padding(
                padding: EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Icon(Icons.remove_circle_outline, 
                         color: _accentColor, size: 16),
                    SizedBox(width: 8),
                    Text(ingredients[index], 
                         style: TextStyle(color: _textColor)),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('キャンセル', style: TextStyle(color: _accentColor)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text('決定'),
          onPressed: () {
            Navigator.of(context).pop();
            _executeMealDecision(mealPlan);
          },
        ),
      ],
    ),
  );
}

// 食材削除実行メソッド
Future<void> _executeMealDecision(MealPlan mealPlan) async {
  try {
    // 食材削除ロジック実装
    final appState = ref.read(appStateProvider);
    final ingredients = <String>[];
    ingredients.addAll(mealPlan.mainDish.ingredients.map((i) => i.name));
    ingredients.addAll(mealPlan.sideDish.ingredients.map((i) => i.name));
    ingredients.addAll(mealPlan.soup.ingredients.map((i) => i.name));

    // 冷蔵庫の商品から該当食材を削除
    for (final ingredientName in ingredients) {
      final matchingProducts = appState.products.where(
        (product) => product.name.contains(ingredientName) ||
                    ingredientName.contains(product.name)
      ).toList();

      for (final product in matchingProducts) {
        if (product.id != null) {
          await ref.read(appStateProvider.notifier)
                    .deleteProductFromFirebase(product.id!);
        }
      }
    }

    // 成功メッセージ表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('献立が決定されました。食材を削除しました。'),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    // エラーメッセージ表示
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('食材削除に失敗しました: $e'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### 5. 献立テーマの削除 【優先度: 低】
**問題**: 献立まとめ欄の献立テーマが適切に生成されていない
**対象ファイル**: `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart`

#### 実装詳細:
```dart
// 献立まとめ部分の修正
// Before:
Column(
  children: [
    Text('テーマ: ${mealPlan.theme}'), // 削除
    Text('総カロリー: ${mealPlan.totalCalories}kcal'),
    Text('調理時間: ${mealPlan.totalCookingTime}分'),
  ],
)

// After:
Column(
  children: [
    Text('総カロリー: ${mealPlan.totalCalories}kcal'),
    Text('調理時間: ${mealPlan.totalCookingTime}分'),
  ],
)
```

---

### 6. 「もう一品」画面の改善 【優先度: 中】
**問題**: レイアウト崩れ、デザート選択の不適切さ
**対象ファイル**: `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart`

#### 実装詳細:
```dart
// _suggestAdditionalDishメソッドの完全書き換え
void _suggestAdditionalDish() {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: _baseColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: Text(
        'もう一品追加',
        style: TextStyle(
          color: _textColor,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
        textAlign: TextAlign.center,
      ),
      content: Container(
        width: double.maxFinite,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'どのような料理を追加しますか？',
              style: TextStyle(color: _accentColor, fontSize: 14),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 16),
            _buildDishOption(
              title: '副菜',
              subtitle: '野菜やサラダなど',
              icon: Icons.eco,
              onTap: () => _addAdditionalDish('副菜'),
            ),
            SizedBox(height: 8),
            _buildDishOption(
              title: '汁物',
              subtitle: 'スープや味噌汁など',
              icon: Icons.local_drink,
              onTap: () => _addAdditionalDish('汁物'),
            ),
            SizedBox(height: 8),
            _buildDishOption(
              title: 'おつまみ',
              subtitle: '簡単な一品料理',
              icon: Icons.local_bar,
              onTap: () => _addAdditionalDish('おつまみ'),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          child: Text('キャンセル', style: TextStyle(color: _accentColor)),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ],
    ),
  );
}

// 料理オプションWidget
Widget _buildDishOption({
  required String title,
  required String subtitle,
  required IconData icon,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(8),
    child: Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _primaryColor.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _primaryColor.withOpacity(0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: _accentColor, size: 24),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    color: _textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: _accentColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Icon(Icons.arrow_forward_ios, 
               color: _accentColor, size: 16),
        ],
      ),
    ),
  );
}

// 追加料理生成メソッド
Future<void> _addAdditionalDish(String dishType) async {
  Navigator.of(context).pop();
  
  // ローディング表示
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      backgroundColor: _baseColor,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircularProgressIndicator(color: _primaryColor),
          SizedBox(height: 16),
          Text(
            '${dishType}を考えています...',
            style: TextStyle(color: _textColor),
          ),
        ],
      ),
    ),
  );

  try {
    // AI呼び出しで追加料理を生成
    final additionalDish = await ref.read(aiMealPlanningServiceProvider)
        .generateAdditionalDish(dishType);
    
    Navigator.of(context).pop(); // ローディング閉じる
    
    if (additionalDish != null) {
      // 現在の献立に追加
      final currentMealPlan = ref.read(mealPlanProvider).value;
      if (currentMealPlan != null) {
        // 献立更新ロジック実装
        _updateMealPlanWithAdditionalDish(currentMealPlan, additionalDish);
      }
    }
  } catch (e) {
    Navigator.of(context).pop(); // ローディング閉じる
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('料理の提案に失敗しました'),
        backgroundColor: Colors.red,
      ),
    );
  }
}
```

---

### 7. メニュー詳細画面のクリーム色対応 【優先度: 中】
**問題**: メニュー詳細画面がクリーム色基調と合っていない
**対象ファイル**: `lib/features/meal_planning/presentation/widgets/meal_detail_dialog.dart`

#### 実装詳細:
```dart
class MealDetailDialog extends StatelessWidget {
  // カラー定義を追加
  static const Color _baseColor = Color(0xFFF6EACB);
  static const Color _primaryColor = Color(0xFFD4A574);
  static const Color _secondaryColor = Color(0xFFB8956A);
  static const Color _accentColor = Color(0xFF8B7355);
  static const Color _textColor = Color(0xFF5D4E37);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: _baseColor, // 変更
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: _baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ヘッダー部分
            Container(
              padding: EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _primaryColor.withOpacity(0.2),
                borderRadius: BorderRadius.vertical(
                  top: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      mealItem.name,
                      style: TextStyle(
                        color: _textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close, color: _accentColor),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            
            // コンテンツ部分
            Flexible(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 画像表示
                    if (mealItem.imageUrl != null)
                      Container(
                        height: 200,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _primaryColor.withOpacity(0.3),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            mealItem.imageUrl!,
                            fit: BoxFit.cover,
                          ),
                        ),
                      ),
                    
                    SizedBox(height: 16),
                    
                    // 説明
                    _buildSection(
                      title: '説明',
                      icon: Icons.description,
                      content: Text(
                        mealItem.description,
                        style: TextStyle(color: _textColor),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // 材料
                    _buildSection(
                      title: '材料',
                      icon: Icons.shopping_basket,
                      content: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: mealItem.ingredients.map((ingredient) =>
                          Padding(
                            padding: EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              children: [
                                Container(
                                  width: 6,
                                  height: 6,
                                  decoration: BoxDecoration(
                                    color: _accentColor,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                                SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '${ingredient.name} ${ingredient.amount}',
                                    style: TextStyle(color: _textColor),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ),
                    ),
                    
                    SizedBox(height: 16),
                    
                    // レシピ手順
                    if (mealItem.recipe != null)
                      _buildSection(
                        title: '作り方',
                        icon: Icons.list_alt,
                        content: Column(
                          children: mealItem.recipe!.steps.asMap().entries.map(
                            (entry) => Padding(
                              padding: EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                      color: _primaryColor,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Center(
                                      child: Text(
                                        '${entry.key + 1}',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      entry.value.instruction,
                                      style: TextStyle(color: _textColor),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ).toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required IconData icon,
    required Widget content,
  }) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _baseColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: _primaryColor.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: _accentColor, size: 20),
              SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: _textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          content,
        ],
      ),
    );
  }
}
```

---

### 8. 買い物リストボタンの追加 【優先度: 中】
**問題**: 買い物リストへのアクセスが不便
**対象ファイル**: `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart`

#### 実装詳細:
```dart
class _MealPlanScreenState extends ConsumerState<MealPlanScreen> {
  final ScrollController _scrollController = ScrollController();
  GlobalKey _shoppingListKey = GlobalKey(); // 追加

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('献立提案'),
        backgroundColor: _baseColor,
        actions: [
          // 買い物リストボタン追加
          IconButton(
            icon: Icon(
              Icons.shopping_cart,
              color: _accentColor,
            ),
            tooltip: '買い物リストへ',
            onPressed: _scrollToShoppingList,
          ),
          // 再提案ボタン
          IconButton(
            icon: Icon(
              Icons.refresh,
              color: _accentColor,
            ),
            tooltip: '再提案',
            onPressed: _showReSuggestConfirmation,
          ),
        ],
      ),
      body: SingleChildScrollView(
        controller: _scrollController,
        child: Column(
          children: [
            // 献立表示部分
            // ... 既存のコンテンツ
            
            // 買い物リスト部分
            Container(
              key: _shoppingListKey, // キー設定
              child: // 買い物リストWidget
            ),
          ],
        ),
      ),
    );
  }

  // スクロール機能実装
  void _scrollToShoppingList() {
    final RenderBox? renderBox = _shoppingListKey.currentContext
        ?.findRenderObject() as RenderBox?;
    
    if (renderBox != null) {
      final position = renderBox.localToGlobal(Offset.zero);
      final screenHeight = MediaQuery.of(context).size.height;
      
      _scrollController.animateTo(
        position.dy - (screenHeight * 0.1), // 上部に少し余白
        duration: Duration(milliseconds: 800),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
```

---

## 📁 ファイル構成

### 修正対象ファイル:
1. `lib/features/meal_planning/presentation/pages/meal_plan_screen.dart` - メイン画面
2. `lib/features/meal_planning/presentation/widgets/meal_plan_square_card.dart` - メニューカード
3. `lib/features/meal_planning/presentation/widgets/meal_detail_dialog.dart` - 詳細ダイアログ
4. `lib/core/services/ai_meal_planning_service.dart` - AI追加料理生成
5. `lib/shared/models/meal_plan.dart` - データモデル（必要に応じて）

### 新規作成ファイル:
6. `docs/meal_ui_improvement/current_implementation.yaml` - 現在の実装状況
7. `docs/meal_ui_improvement/modification_plan.yaml` - 修正計画
8. `docs/meal_ui_improvement/updated_implementation.yaml` - 更新後の実装

---

## 🚀 実装スケジュール

### Day 1: 緊急修正
- [ ] レシピ詳細画面の準備時間削除
- [ ] メニューブロックの境界線追加
- [ ] 献立決定時の確認ダイアログ

### Day 2: 確認機能
- [ ] 再提案確認ダイアログ
- [ ] 食材削除ロジック実装
- [ ] エラーハンドリング

### Day 3: UI統一
- [ ] メニュー詳細画面のクリーム色対応
- [ ] 「もう一品」画面の改善
- [ ] 買い物リストボタン追加

### Day 4: 細部調整
- [ ] 献立テーマ削除
- [ ] スクロール機能実装
- [ ] 全体のデザイン統一確認

### Day 5: テスト・調整
- [ ] 統合テスト
- [ ] UI/UXテスト
- [ ] パフォーマンス確認

---

## 🧪 テスト計画

### 単体テスト:
- [ ] 確認ダイアログの表示・動作
- [ ] 食材削除ロジック
- [ ] スクロール機能

### 統合テスト:
- [ ] 献立提案から決定までの一連の流れ
- [ ] エラー時の適切な処理
- [ ] デザインの一貫性

### UIテスト:
- [ ] レスポンシブデザイン
- [ ] アクセシビリティ
- [ ] ユーザビリティ

---

## 📊 成功指標

### 定量的指標:
- [ ] レイアウト崩れの解消（0件）
- [ ] ユーザー操作の確認ステップ追加（2箇所）
- [ ] デザイン統一率（100%）

### 定性的指標:
- [ ] ユーザビリティの向上
- [ ] 視覚的な一貫性の確保
- [ ] 操作の安全性向上

---

## 🔧 技術的考慮事項

### パフォーマンス:
- 画像の遅延読み込み
- スクロール性能の最適化
- ダイアログ表示の軽量化

### アクセシビリティ:
- スクリーンリーダー対応
- キーボードナビゲーション
- 色覚異常への配慮

### 保守性:
- コンポーネントの再利用性
- カラーパレットの一元管理
- コードの可読性向上

---

## 📝 備考

- ADKサーバーが正常動作していることを前提とする
- 既存の画像生成機能は維持する
- 段階的リリースを想定し、優先度順に実装する
- ユーザーフィードバックを収集しながら調整する
