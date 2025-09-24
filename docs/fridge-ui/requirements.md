### 冷蔵庫 UI 要件定義（スマホ向け 4 段式・ズーム/フォーカス対応）

#### 目的

- 既存のリスト中心 UI に加え、物理配置を反映した直感的な「冷蔵庫ビュー」を提供する。
- 主婦が片手で日常的に使える、無駄のないシンプルで洗練された UI を実現する。

#### 使用技術（本プロジェクト準拠）

- 言語/フレームワーク: Flutter + Dart（Material 3、Riverpod）
- 主要ライブラリ: `flutter_riverpod`（状態管理）、`mobile_scanner`（スキャン）、標準`Hero`/`Animated*`（遷移/アニメ）
- UI 構成: `Stack` + `AspectRatio` + `InteractiveViewer`（ズーム/パン）
- 将来拡張（任意）: Rive アニメーション、`animations`パッケージの Material Motion（FadeThrough/SharedAxis）

#### 画面構成と配置

- エントリ: `HomeScreen` 内の表示モード切替（トグル: リスト / 冷蔵庫）。
- 俯瞰図: `FridgeOverviewWidget`（4 段式 + 両開きドアポケット、タップ可能なセクション）。
- セクション: `FridgeSectionView`（棚/室/ポケット単位の拡大表示、アイテム一覧/操作）。

#### 冷蔵庫レイアウト（家庭用想定）

- 上段: 両開きドア（左/右）にポケット。
- 中央上: 冷蔵室の棚（レベル 0..n）。
- 中央下: 野菜室（引き出し）。
- 下段: 冷凍庫（引き出し）。

#### UI 設計（洗練/シンプルの原則）

- 一目で把握（Glanceable）: セクションごとにアイテム件数/期限警告のバッジ表示。
- 大きなタップ領域: 最低 44dp。重要操作は画面下部に固定（親指到達範囲）。
- 2 タップ以内で到達: 俯瞰 → セクション → 詳細の最短導線。
- カラーセマンティクス: 期限切迫=警告色（既存 ColorScheme の`error`/`tertiary`を使用）。
- 視覚的ヒント: セクションホバー/アクティブ時に僅かなシャドウ/色調変化。
- 最小認知負荷: 文言は短く、アイコン+短ラベル。説明は必要時のみボトムシートで補足。

#### 主要インタラクション/ジェスチャ

- タップ: セクション選択/ズームイン（`InteractiveViewer`の`min/maxScale`調整）。
- ピンチ/パン: 俯瞰図の拡大・移動（初期はパンのみ → 段階的にピンチ導入）。
- 長押し → ドラッグ&ドロップ: `Draggable` + `DragTarget`でセクション間移動（Phase 2）。
- 戻る操作: バックジェスチャ/クローズボタンで俯瞰へ（`WillPopScope`で制御）。

#### 遷移/アニメーション

- リスト ⇄ 冷蔵庫切替: `AnimatedSwitcher`（200–250ms、Fade+Scale の複合）。
- 俯瞰 → セクション: `PageRouteBuilder`または`Hero`でズームイン風の自然遷移。
- アイテム → 詳細: 既存の`ProductCard`と`ProductDetailScreen`間の`Hero`タグ共有。
- マイクロアニメ: `AnimatedContainer`/`AnimatedOpacity`で状態変化を可視化（期限色/選択状態）。

#### コンポーネント設計

- `FridgeOverviewWidget`: 冷蔵庫の枠/段/ポケットを`Stack`と`Positioned`で構成、セクションごとにタップ領域。
- `FridgeCompartmentToggle`: 冷蔵/野菜室/冷凍/ドアのフィルタ（チップ/セグメント）。
- `FridgeSectionView`: セクション内のアイテム一覧（グリッド/ラップ表示、閾値で折りたたみ）。
- `ItemChip`/`ProductPill`: アイテム最小表現（サムネ/名前/期限バッジ、長押しでドラッグ）。

#### 検索/フィルタ（簡潔）

- 俯瞰時: セクション単位の件数と期限警告のみ表示、検索はオフ。
- セクション時: `ProductSearchDelegate`を再利用、カテゴリ/期限フィルタのチップ表示。

#### データモデル変更

- `Product.location` を追加。
  - `compartment`: `refrigerator | vegetable_drawer | freezer | door_left | door_right`
  - `level`: number（0=最上段）
  - `position`: optional `{ x: 0..1, y: 0..1 }`（将来の自由配置に使用）

#### 状態管理（Riverpod）

- `fridgeViewProvider`: 表示モード（list|fridge）、選択セクション、ズーム状態。
- `dragDropProvider`: ドラッグ中アイテム、ドロップ確定で `updateProductLocation` 実行。

#### トリガ/フロー

- 俯瞰図セクションタップ → `FridgeSectionView` へ遷移/切替。
- セクション内カードタップ → `ProductDetailScreen`。
- 長押し開始 → ドラッグ、ドロップ → `Product.location` 更新。

#### アクセシビリティ/主婦向け UX

- 片手操作最適化: 主要操作（戻る/切替/追加）は下部領域に配置。
- 文言: 家事中のながら操作を想定し最短語彙。カタカナ乱用を避ける。
- 視認性: コントラスト AA 相当、期限の色分け+絵文字/アイコンの冗長符号化。
- フィードバック: 重要操作に軽微な Haptics（対応端末）とトースト/スナックの簡潔通知。

#### パフォーマンス/品質

- 60fps 目標。`RepaintBoundary`の活用、不要なリビルドを回避（`const`/`select`）。
- スクロール/ズームの同時操作に配慮してジェスチャ競合を最小化。
- エラーは既存 `InlineErrorWidget` 準拠、例外は`AppException`系へ集約。

#### 受け入れ基準（Phase 1）

- 切替トグルでリスト/冷蔵庫表示を行き来できる。
- 俯瞰図の各セクションがタップ可能で、該当商品のみが表示される。
- 既存の検索/詳細遷移が維持される（回帰なし）。
- タップ/戻るの導線が 2 タップ以内で完結する。

#### 今後の拡張

- Firestore への `location` 永続化、家族共有での表示整合。
- ドラッグ&ドロップ、ピンチズームの最適化、ゴールデン/統合テスト（TDD）。
