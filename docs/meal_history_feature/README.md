# 献立履歴機能 - 実装ガイド

## 📋 プロジェクト概要

**目標**: 献立提案画面に献立履歴機能を追加し、過去の献立を確認・再利用できる機能を実装する

**期間**: 5-7日間（段階的実装）

**複雑度**: ⭐⭐⭐☆☆ (中程度)

## 🎯 機能要件

### 主要機能
1. **献立履歴表示** - 過去の献立を時系列で一覧表示
2. **フィルタリング** - 状態・期間・難易度による絞り込み
3. **検索機能** - 料理名・材料名による検索
4. **過去献立再利用** - 履歴から献立を選択して再提案
5. **材料照合** - 現在の冷蔵庫食材との照合と不足材料表示

### UI/UX要件
- 既存のクリーム色基調デザインとの統一
- 直感的な操作性
- 適切なローディング・エラー表示
- レスポンシブデザイン

## 🏗️ 実装アーキテクチャ

### 既存基盤の活用
```yaml
existing_infrastructure:
  data_model: "MealPlan - 完全実装済み"
  state_management: "MealPlanHistoryNotifier - 実装済み"
  database: "Firestore meal_plans collection - 設定済み"
  api: "getMealPlanHistory method - 実装済み"
```

### 新規実装ファイル
```
lib/features/meal_planning/presentation/
├── pages/
│   └── meal_plan_history_screen.dart          # メイン履歴画面
└── widgets/
    ├── meal_history_item_card.dart            # 履歴アイテムカード
    ├── meal_history_filter_bar.dart           # フィルターバー
    └── meal_reuse_confirmation_dialog.dart    # 再利用確認ダイアログ
```

### 修正対象ファイル
```
lib/features/meal_planning/presentation/pages/meal_plan_screen.dart
- _showMealPlanHistory メソッドの実装 (Line 1127-1134)
```

## 📋 実装計画

### Phase 1: 基本履歴表示 【1-2日】
- [x] 献立履歴画面作成
- [x] 履歴アイテムカード作成
- [x] 既存画面との連携
- [x] 基本的な一覧表示機能

### Phase 2: フィルタリング・検索 【1-2日】
- [ ] 状態フィルター実装
- [ ] 日付フィルター実装
- [ ] 検索機能実装
- [ ] フィルター組み合わせ対応

### Phase 3: 再利用機能 【2-3日】
- [ ] 再利用確認ダイアログ作成
- [ ] 食材分析ロジック実装
- [ ] 不足材料表示機能
- [ ] 買い物リスト連携
- [ ] 献立設定機能

### Phase 4: 最適化・テスト 【1日】
- [ ] パフォーマンス最適化
- [ ] エラーハンドリング強化
- [ ] 統合テスト実施
- [ ] UI/UX調整

## 🎨 デザインシステム

### カラーパレット
```dart
static const Color _baseColor = Color(0xFFF6EACB);     // クリーム色
static const Color _primaryColor = Color(0xFFD4A574);   // 温かいベージュ
static const Color _secondaryColor = Color(0xFFB8956A); // 深いベージュ
static const Color _accentColor = Color(0xFF8B7355);    // ブラウン
static const Color _textColor = Color(0xFF5D4E37);      // ダークブラウン
```

### コンポーネントスタイル
- **カード**: 角丸12px、軽い影、境界線
- **ボタン**: 既存スタイルと統一
- **フィルターチップ**: Material Design準拠
- **アイコン**: Material Icons使用

## 🔧 技術仕様

### 状態管理
```dart
// 既存のプロバイダーを活用
final mealPlanHistoryProvider = StateNotifierProvider<MealPlanHistoryNotifier, AsyncValue<List<MealPlan>>>;

// 使用例
final historyAsync = ref.watch(mealPlanHistoryProvider);
await ref.read(mealPlanHistoryProvider.notifier).loadMealPlanHistory(householdId);
```

### データベース
```yaml
firestore_collection: "meal_plans"
required_indexes:
  - "householdId + createdAt (desc)"
  - "householdId + status + createdAt (desc)"
query_patterns:
  - "時系列取得"
  - "状態別フィルタリング"
  - "期間指定取得"
```

### パフォーマンス最適化
- **ページング**: 20件ずつ読み込み
- **無限スクロール**: スクロール80%で追加読み込み
- **キャッシュ**: 最新50件をローカル保持
- **画像遅延読み込み**: サムネイル画像の最適化

## 🧪 テスト戦略

### 単体テスト
```dart
// MealPlanHistoryScreen のテスト
test/features/meal_planning/presentation/pages/meal_plan_history_screen_test.dart

// MealHistoryItemCard のテスト
test/features/meal_planning/presentation/widgets/meal_history_item_card_test.dart
```

### 統合テスト
```dart
// 完全フローのテスト
integration_test/meal_history_flow_test.dart
```

### テストシナリオ
1. 履歴表示フロー
2. フィルタリングフロー
3. 検索フロー
4. 再利用フロー
5. エラーハンドリング

## 📊 成功指標

### 定量的指標
- ✅ 初期表示時間 < 2秒
- ✅ 検索レスポンス時間 < 1秒
- ✅ スクロール性能 60fps維持
- ✅ メモリ使用量増加 < 50MB
- ✅ クラッシュ率 < 0.1%

### 定性的指標
- ✅ 既存UIとの統一性
- ✅ 直感的な操作性
- ✅ 適切なフィードバック
- ✅ エラー処理の適切性

## 🚀 実装手順

### 1. 環境準備
```bash
# プロジェクトディレクトリに移動
cd /Users/takenakashun/Desktop/GCP-hackathon/GCP-Hackathon-F06

# 依存関係確認
flutter pub get

# 既存テスト実行
flutter test
```

### 2. 基本画面作成
1. `meal_plan_history_screen.dart` 作成
2. `meal_history_item_card.dart` 作成
3. 既存画面の修正
4. 基本動作確認

### 3. フィルタリング機能
1. フィルターバー実装
2. 検索ダイアログ実装
3. フィルターロジック実装
4. 機能テスト

### 4. 再利用機能
1. 確認ダイアログ作成
2. 食材分析ロジック実装
3. 買い物リスト連携
4. 統合テスト

### 5. 最終調整
1. パフォーマンス測定
2. エラーハンドリング確認
3. UI/UX調整
4. 最終テスト

## 🔍 トラブルシューティング

### よくある問題

#### 1. Firestore クエリエラー
```dart
// 問題: インデックス未作成
// 解決: Firebase Console でインデックス作成

// 必要なインデックス
Collection: meal_plans
Fields: householdId (Ascending), createdAt (Descending)
```

#### 2. 状態管理エラー
```dart
// 問題: プロバイダーの初期化エラー
// 解決: 適切な初期化順序の確認

@override
void initState() {
  super.initState();
  WidgetsBinding.instance.addPostFrameCallback((_) {
    _loadHistory();
  });
}
```

#### 3. UI レンダリング問題
```dart
// 問題: ListView の高さ制約
// 解決: Expanded でラップ

Expanded(
  child: ListView.builder(
    // ...
  ),
)
```

## 📚 参考資料

### 既存実装
- [MealPlan Model](../../../lib/shared/models/meal_plan.dart)
- [MealPlanProvider](../../../lib/features/meal_planning/presentation/providers/meal_plan_provider.dart)
- [FirestoreService](../../../lib/core/services/firestore_service.dart)

### Flutter ドキュメント
- [ListView.builder](https://api.flutter.dev/flutter/widgets/ListView/ListView.builder.html)
- [FilterChip](https://api.flutter.dev/flutter/material/FilterChip-class.html)
- [SearchDelegate](https://api.flutter.dev/flutter/material/SearchDelegate-class.html)

### 設計パターン
- [Riverpod State Management](https://riverpod.dev/)
- [Material Design](https://material.io/design)

## 🎉 完成イメージ

### 履歴画面
```
┌─────────────────────────────────┐
│ ← 献立履歴              🔍      │
├─────────────────────────────────┤
│ [すべて] [完了済み] [承認済み]    │
├─────────────────────────────────┤
│ 🍽️ ハンバーグ定食      ✅ 🔄   │
│    今日 • 45分 • ⭐簡単         │
├─────────────────────────────────┤
│ 🍽️ 鮭の塩焼き定食      ✅ 🔄   │
│    昨日 • 30分 • ⭐簡単         │
├─────────────────────────────────┤
│ 🍽️ カレーライス        ✅ 🔄   │
│    3日前 • 60分 • ⭐⭐普通      │
└─────────────────────────────────┘
```

### 再利用確認ダイアログ
```
┌─────────────────────────────────┐
│ この献立を再利用しますか？        │
├─────────────────────────────────┤
│ ハンバーグ定食                   │
│                                │
│ ✅ 利用可能な材料               │
│ • 玉ねぎ 1個                    │
│ • 卵 2個                       │
│                                │
│ 🛒 不足している材料             │
│ • 牛ひき肉 300g                │
│ • パン粉 適量                   │
├─────────────────────────────────┤
│      [キャンセル] [買い物リスト] [再利用] │
└─────────────────────────────────┘
```

## 🏁 次のステップ

実装完了後の拡張可能性：

1. **評価・レビュー機能** - 献立の評価とコメント
2. **お気に入り機能** - よく使う献立のブックマーク
3. **カレンダー表示** - 月間カレンダーでの献立表示
4. **統計機能** - 調理頻度や栄養バランスの分析
5. **共有機能** - 家族間での献立共有
6. **AI学習** - 利用パターンに基づく推薦改善

---

**実装担当者**: Claude AI Assistant  
**作成日**: 2025-01-19  
**バージョン**: 1.0
