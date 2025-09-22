# AI献立提案機能 開発ロードマップ

## 🎯 プロジェクト概要

**機能名**: AI献立提案機能  
**開発期間**: 4週間  
**技術スタック**: Flutter + Google ADK + Vertex AI + Firebase  
**チーム構成**: フロントエンド1名 + AI/バックエンド1名 + インフラ1名

## 📅 開発スケジュール

### Week 1: 基盤構築・AI統合
**目標**: Google ADK環境構築と基本的な献立提案API実装

#### Day 1-2: 環境構築
- [ ] Google ADK環境セットアップ
- [ ] Vertex AI API設定
- [ ] 開発環境のDocker化
- [ ] CI/CDパイプライン構築

#### Day 3-4: AIエージェント開発
- [ ] Google ADKで献立提案エージェント作成
- [ ] Function Callingで冷蔵庫データ連携
- [ ] 基本的な献立生成ロジック実装
- [ ] 賞味期限優先ロジック実装

#### Day 5-7: API開発
- [ ] Cloud Functionsで献立提案API実装
- [ ] Firestoreデータモデル設計・実装
- [ ] 基本的なエラーハンドリング
- [ ] APIテスト・デバッグ

### Week 2: フロントエンド実装
**目標**: 献立提案UIと基本機能の実装

#### Day 8-10: UI基盤
- [ ] 献立提案画面のUI設計
- [ ] メニューカードコンポーネント作成
- [ ] 献立詳細ダイアログ実装
- [ ] 材料表示コンポーネント作成

#### Day 11-12: 状態管理
- [ ] Riverpodで献立状態管理実装
- [ ] API連携のProvider作成
- [ ] エラーハンドリング・ローディング状態
- [ ] データキャッシュ機能

#### Day 13-14: 基本機能統合
- [ ] 献立提案APIとの連携
- [ ] 材料の在庫確認機能
- [ ] 基本的なレシピ表示
- [ ] ユニットテスト実装

### Week 3: 高度な機能実装
**目標**: 買い物リスト・詳細レシピ・ユーザー体験向上

#### Day 15-17: 買い物リスト機能
- [ ] 不足材料の自動検出
- [ ] 買い物リスト生成機能
- [ ] カテゴリ別グループ化
- [ ] チェック機能実装

#### Day 18-19: レシピ詳細機能
- [ ] 詳細レシピ表示ダイアログ
- [ ] 調理手順のステップ表示
- [ ] 調理時間・難易度表示
- [ ] コツ・ポイント表示

#### Day 20-21: UX改善
- [ ] アニメーション・トランジション
- [ ] レスポンシブデザイン対応
- [ ] アクセシビリティ対応
- [ ] パフォーマンス最適化

### Week 4: テスト・最適化・デプロイ
**目標**: 品質保証と本番環境デプロイ

#### Day 22-24: テスト・品質保証
- [ ] 統合テスト実装
- [ ] E2Eテスト（Playwright）実装
- [ ] パフォーマンステスト
- [ ] セキュリティテスト

#### Day 25-26: 最適化
- [ ] AI応答速度最適化
- [ ] キャッシュ戦略最適化
- [ ] データベースクエリ最適化
- [ ] バンドルサイズ最適化

#### Day 27-28: デプロイ・監視
- [ ] 本番環境デプロイ
- [ ] 監視・ログ設定
- [ ] ユーザーフィードバック収集
- [ ] ドキュメント整備

## 🛠️ 技術実装詳細

### 1. Google ADK統合

#### エージェント設計
```yaml
agent_config:
  name: "meal_planning_agent"
  description: "冷蔵庫の食材を基に献立を提案するAIエージェント"
  capabilities:
    - "refrigerator_data_analysis"
    - "meal_plan_generation"
    - "ingredient_optimization"
    - "expiry_date_prioritization"
  
  functions:
    - name: "get_refrigerator_items"
      description: "冷蔵庫の商品データを取得"
      parameters:
        householdId: string
        includeExpired: boolean
      
    - name: "analyze_ingredients"
      description: "食材の賞味期限と量を分析"
      parameters:
        items: Product[]
      
    - name: "generate_meal_plan"
      description: "献立を生成"
      parameters:
        availableIngredients: Ingredient[]
        preferences: UserPreferences
```

#### Function Calling実装
```dart
class MealPlanningAgent {
  final VertexAI _vertexAI;
  final FirestoreService _firestoreService;
  
  Future<MealPlan> suggestMealPlan(String householdId) async {
    // 1. 冷蔵庫データ取得
    final items = await _firestoreService.getRefrigeratorItems(householdId);
    
    // 2. 賞味期限が近い食材を優先
    final prioritizedItems = _prioritizeByExpiry(items);
    
    // 3. AIに献立生成を依頼
    final prompt = _buildMealPlanPrompt(prioritizedItems);
    final response = await _vertexAI.generateContent(prompt);
    
    // 4. 結果をパースしてMealPlanオブジェクトに変換
    return _parseMealPlanResponse(response);
  }
}
```

### 2. データモデル設計

#### Firestoreコレクション
```yaml
collections:
  meal_plans:
    document_id: "plan_{date}_{householdId}"
    fields:
      householdId: string
      date: timestamp
      status: "suggested" | "accepted" | "cooking" | "completed"
      mainDish: MealItem
      sideDish: MealItem
      soup: MealItem
      rice: MealItem
      totalCookingTime: number
      difficulty: "easy" | "medium" | "hard"
      nutritionScore: number
      createdAt: timestamp
      createdBy: string

  meal_items:
    document_id: "item_{mealPlanId}_{category}"
    fields:
      name: string
      category: "main" | "side" | "soup" | "rice"
      ingredients: Ingredient[]
      recipe: Recipe
      cookingTime: number
      difficulty: string
      imageUrl: string

  ingredients:
    document_id: "ingredient_{itemId}_{ingredientName}"
    fields:
      name: string
      quantity: string
      unit: string
      available: boolean
      expiryDate: timestamp
      shoppingRequired: boolean
      productId: string
```

### 3. API設計

#### Cloud Functions
```javascript
// functions/meal-planning.js
const { onCall } = require('firebase-functions/v2/https');
const { VertexAI } = require('@google-cloud/vertexai');

const vertexAI = new VertexAI({
  project: process.env.GOOGLE_CLOUD_PROJECT,
  location: 'us-central1'
});

exports.suggestMealPlan = onCall(async (request) => {
  const { householdId, preferences } = request.data;
  
  try {
    // 1. 冷蔵庫データ取得
    const items = await getRefrigeratorItems(householdId);
    
    // 2. AI献立生成
    const mealPlan = await generateMealPlanWithAI(items, preferences);
    
    // 3. Firestoreに保存
    await saveMealPlan(householdId, mealPlan);
    
    return { success: true, mealPlan };
  } catch (error) {
    console.error('Error generating meal plan:', error);
    throw new functions.https.HttpsError('internal', error.message);
  }
});
```

### 4. フロントエンド実装

#### 状態管理（Riverpod）
```dart
// lib/features/meal_planning/presentation/providers/meal_plan_provider.dart
@riverpod
class MealPlanNotifier extends _$MealPlanNotifier {
  @override
  Future<MealPlan?> build() async {
    return null;
  }
  
  Future<void> suggestMealPlan(String householdId) async {
    state = const AsyncValue.loading();
    
    try {
      final mealPlan = await ref.read(mealPlanServiceProvider).suggestMealPlan(householdId);
      state = AsyncValue.data(mealPlan);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
}
```

#### UI実装
```dart
// lib/features/meal_planning/presentation/pages/meal_plan_screen.dart
class MealPlanScreen extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mealPlanAsync = ref.watch(mealPlanProvider);
    
    return Scaffold(
      appBar: AppBar(title: Text('本日の献立')),
      body: mealPlanAsync.when(
        data: (mealPlan) => mealPlan != null 
          ? MealPlanContent(mealPlan: mealPlan)
          : EmptyMealPlanView(),
        loading: () => LoadingView(),
        error: (error, stack) => ErrorView(error: error),
      ),
    );
  }
}
```

## 🧪 テスト戦略

### 1. 単体テスト
- **AIエージェントテスト**: 献立生成ロジックのテスト
- **APIテスト**: Cloud Functionsのテスト
- **UIテスト**: ウィジェットテスト

### 2. 統合テスト
- **E2Eテスト**: Playwrightを使用したフルフロー
- **API統合テスト**: フロントエンド-バックエンド連携
- **データベーステスト**: Firestore操作のテスト

### 3. パフォーマンステスト
- **AI応答時間**: 3秒以内の応答時間確保
- **メモリ使用量**: モバイルアプリのメモリ効率
- **ネットワーク効率**: API呼び出しの最適化

## 📊 品質指標

### 1. 機能品質
- **献立提案精度**: ユーザー満足度80%以上
- **材料活用率**: 冷蔵庫食材の70%以上を活用
- **API可用性**: 99.9%以上

### 2. パフォーマンス
- **応答時間**: 献立提案3秒以内
- **メモリ使用量**: 100MB以下
- **バッテリー消費**: 最小限

### 3. ユーザビリティ
- **直感的操作**: 3タップ以内で詳細表示
- **アクセシビリティ**: WCAG 2.1 AA準拠
- **多言語対応**: 日本語・英語対応

## 🚀 デプロイ戦略

### 1. 段階的デプロイ
- **Phase 1**: 内部テスト（開発チーム）
- **Phase 2**: ベータテスト（限定的ユーザー）
- **Phase 3**: 本番リリース（全ユーザー）

### 2. 監視・ログ
- **アプリケーション監視**: Firebase Performance
- **エラー監視**: Firebase Crashlytics
- **ユーザー行動分析**: Firebase Analytics
- **AI性能監視**: Vertex AI Monitoring

### 3. ロールバック戦略
- **機能フラグ**: 新機能の段階的有効化
- **A/Bテスト**: 複数バージョンの比較
- **緊急ロールバック**: 問題発生時の即座な復旧

## 📈 今後の拡張計画

### Phase 2 (3ヶ月後)
- **栄養バランス分析**: カロリー・栄養素の詳細分析
- **アレルギー対応**: アレルギー情報に基づく献立調整
- **家族の好み学習**: 過去の選択から好みを学習

### Phase 3 (6ヶ月後)
- **音声対応**: 音声での献立提案・操作
- **AR機能**: 食材のAR表示・調理ガイド
- **ソーシャル機能**: 家族間での献立共有・評価

## 🔒 セキュリティ・コンプライアンス

### 1. データ保護
- **暗号化**: 機密データのAES-256暗号化
- **アクセス制御**: 家族単位でのデータ分離
- **データ保持**: 自動削除ポリシー

### 2. AI倫理
- **バイアス対策**: 多様性を考慮した献立提案
- **透明性**: AI判断プロセスの説明可能性
- **プライバシー**: 個人データの最小化

### 3. コンプライアンス
- **GDPR**: 欧州一般データ保護規則準拠
- **CCPA**: カリフォルニア消費者プライバシー法準拠
- **個人情報保護法**: 日本の個人情報保護法準拠

