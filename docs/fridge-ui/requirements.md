### 冷蔵庫UI 要件定義（スマホ向け 4段式・ズーム/フォーカス対応）

#### 目的
- 既存のリスト中心UIに加え、物理配置を反映した直感的な「冷蔵庫ビュー」を提供する。

#### 画面構成と配置
- エントリ: `HomeScreen` 内に表示モード切替（トグル: リスト / 冷蔵庫）。
- 俯瞰図: `FridgeOverviewWidget`（4段式 + 両開きドアポケット）。
- セクション: `FridgeSectionView`（棚/室/ポケット単位の拡大表示）。

#### 冷蔵庫レイアウト（家庭用想定）
- 上段: 両開きドア（左/右）にポケット。
- 中央上: 冷蔵室の棚（レベル0..n）。
- 中央下: 野菜室（引き出し）。
- 下段: 冷凍庫（引き出し）。

#### 主要機能
- タップでセクション選択/ズーム。
- ピンチズーム/パン（段階導入）。
- セクション内のアイテム一覧、検索/フィルタ、並べ替え。
- アイテムタップで詳細/編集（現行 `ProductDetailScreen` を再利用）。
- ドラッグ&ドロップで位置変更（段階導入）。

#### データモデル変更
- `Product.location` を追加。
  - `compartment`: `refrigerator | vegetable_drawer | freezer | door_left | door_right`
  - `level`: number（0=最上段）
  - `position`: optional `{ x: 0..1, y: 0..1 }`

#### 状態管理（Riverpod）
- `fridgeViewProvider`: 表示モード、選択セクション、ズーム状態。
- `dragDropProvider`: ドラッグ中アイテム、ドロップ確定で `updateProductLocation` 実行。

#### トリガ/フロー
- 俯瞰図セクションタップ → `FridgeSectionView` へ遷移/切替。
- セクション内カードタップ → `ProductDetailScreen`。
- 長押し開始 → ドラッグ、ドロップ → `Product.location` 更新。

#### 非機能要件
- 60fps目標、44dp以上のタップ領域。
- エラーは既存 `InlineErrorWidget` 準拠、ロギング強化。

#### 受け入れ基準（Phase 1）
- 切替トグルでリスト/冷蔵庫表示を行き来できる。
- 俯瞰図の各セクションがタップ可能で、該当商品のみが表示される。
- 既存の検索/詳細遷移が維持される。

#### 今後の拡張
- Firestoreへの `location` 永続化、家族共有での表示整合。
- ジェスチャ最適化、ゴールデン/統合テスト追加。


