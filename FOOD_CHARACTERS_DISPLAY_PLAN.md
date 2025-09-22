# 食材キャラクター表示機能 開発計画

## 概要
既にFirestoreに登録されている商品データ（compartmentとlevelが指定済み）を基に、各商品を該当するセクション内でランダムな位置に視覚的に配置し、キャラクターとして表示する機能を実装します。

## 現状分析

### 既存データ構造
```dart
// Product model already has:
- compartment: FridgeCompartment (refrigerator/vegetableDrawer/freezer/doorLeft/doorRight)
- level: int (0 = 最上段)
- position: Offset? (x, y座標) // 現在未使用
- imageUrls: Map<ImageStage, String>? // 賞味期限段階別の画像
```

### 必要な実装
- 各compartment/levelの範囲内で商品をランダム配置
- 商品の重なりを防ぐ配置アルゴリズム
- 賞味期限に応じたキャラクター表示

## 開発フェーズ

### Phase 1: 位置計算システムの構築
#### 1.1 セクション内配置計算
- [ ] 各compartment/levelの表示領域定義
  - 冷蔵室: 4段の棚領域
  - 野菜室・冷凍庫: 引き出し内領域
  - ドアポケット: 左右各段の領域
- [ ] 領域内ランダム配置アルゴリズム
  - 利用可能スペースの計算
  - 商品サイズを考慮した配置
  - 重なり防止の衝突検出

#### 1.2 配置状態管理
- [ ] ProductPositionProviderの作成
  - Firestoreから商品データ取得
  - 各商品の表示位置計算・キャッシュ
  - 画面サイズ変更時の再計算

### Phase 2: キャラクター表示ウィジェット
#### 2.1 基本表示コンポーネント
- [ ] `FoodCharacterWidget`の作成
  - Productデータを受け取り表示
  - ImageStageに応じた画像切り替え
  - タップ可能なインタラクティブ要素

#### 2.2 セクション別表示レイヤー
- [ ] `ShelfCharactersLayer` - 棚用
  - 各段(level)ごとの商品表示
  - 奥行き感の表現
- [ ] `DrawerCharactersLayer` - 引き出し用
  - 平面配置での商品表示
  - 引き出しが開いた時のみ表示
- [ ] `DoorCharactersLayer` - ドアポケット用
  - 左右ドアの各段表示

### Phase 3: 既存UIとの統合
#### 3.1 正面ビュー統合
- [ ] `layered_3d_fridge_widget.dart`への組み込み
  - 各セクションにCharacterLayerを追加
  - CustomPaintの上にOverlay表示
  - ドア開閉アニメーションとの連動

#### 3.2 上部ビュー統合
- [ ] `top_view_fridge_widget.dart`への組み込み
  - 引き出し内部にキャラクター表示
  - 引き出しが開いた時の表示制御

### Phase 4: データ連携
#### 4.1 Firestore連携
- [ ] 商品データのリアルタイム取得
  - compartment/levelでフィルタリング
  - 削除済み商品の除外
- [ ] 位置情報の永続化（オプション）
  - 計算した位置をキャッシュ
  - デバイス間での位置同期

#### 4.2 賞味期限連動
- [ ] ImageStageの自動計算
  - 現在日時と賞味期限から算出
  - リアルタイム更新

### Phase 5: インタラクション
#### 5.1 タップ操作
- [ ] 商品詳細表示
- [ ] 編集・削除メニュー

#### 5.2 視覚的フィードバック
- [ ] ホバー/タップ時のハイライト
- [ ] 賞味期限警告アニメーション

## 技術仕様

### ファイル構成
```
lib/features/fridge/
├── presentation/
│   ├── widgets/
│   │   ├── characters/
│   │   │   ├── food_character_widget.dart      # 個別キャラクター
│   │   │   ├── shelf_characters_layer.dart     # 棚レイヤー
│   │   │   ├── drawer_characters_layer.dart    # 引き出しレイヤー
│   │   │   └── door_characters_layer.dart      # ドアレイヤー
│   │   └── (既存のfridge widgets)
│   ├── providers/
│   │   ├── product_position_provider.dart      # 位置計算・管理
│   │   └── (既存providers)
│   └── utils/
│       ├── section_bounds_calculator.dart      # セクション領域計算
│       └── placement_algorithm.dart            # 配置アルゴリズム
└── (既存structure)
```

### 配置アルゴリズム詳細
```dart
// セクション内配置計算例
class PlacementAlgorithm {
  // 1. セクションの境界を取得
  Rect getSectionBounds(FridgeCompartment compartment, int level, Size fridgeSize);

  // 2. 既存商品の位置を考慮してランダム配置
  Offset calculateRandomPosition(
    Product product,
    Rect sectionBounds,
    List<Rect> occupiedSpaces,
  );

  // 3. 衝突検出
  bool hasCollision(Rect newPosition, List<Rect> occupiedSpaces);
}
```

### パフォーマンス考慮事項
- 表示商品数の上限設定（各セクション最大10個など）
- 見えないセクションのレンダリング停止
- 商品画像のキャッシュ
- 位置計算結果のメモリキャッシュ

## 実装優先順位

### Step 1: 最小実装（1-2日）
1. 冷蔵室1段目のみ対応
2. 固定位置での表示（ランダムなし）
3. 基本的なキャラクター表示

### Step 2: 基本機能（3-4日）
1. 全セクション対応
2. ランダム配置実装
3. 重なり防止

### Step 3: 完全実装（5-7日）
1. 賞味期限連動
2. インタラクション
3. アニメーション

## テスト計画

### 必要なテストデータ
- 各compartment/levelに商品を配置したテストデータ
- 様々な商品数でのテスト（0個、1個、多数）
- 賞味期限の異なる商品データ

### テスト項目
- [ ] 各セクションでの正しい表示
- [ ] 商品の重なりがないこと
- [ ] タップ反応の正確性
- [ ] 画面サイズ変更時の再配置

## 成功指標
- 全セクションで商品キャラクターが表示される
- 商品同士が重ならない
- 60fpsのスムーズな表示
- タップで商品詳細が表示される

## リスクと対策

### リスク1: 多数商品時のパフォーマンス
**対策**: セクションごとの表示上限設定

### リスク2: 様々な画面サイズでの配置崩れ
**対策**: レスポンシブな配置計算

### リスク3: 商品画像が存在しない
**対策**: デフォルトキャラクター画像の用意