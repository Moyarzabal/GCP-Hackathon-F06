# Firebase統合ロードマップ

## 概要
現在のアプリは商品データをメモリ内のみで管理しており、アプリ再起動時にデータが失われる問題があります。Firebase Firestoreを使用してデータの永続化を実現します。

## 現状分析

### 現在のデータ管理
- **保存場所**: メモリ内（`AppStateNotifier`）
- **問題点**: アプリ再起動時に全データが消失
- **Firebase設定**: 既存だが未使用

### 既存のFirebase設定
- ✅ Firebase Core初期化済み
- ✅ FirestoreService クラス存在
- ✅ FirestoreProductDataSource 存在
- ❌ 実際の商品保存で未使用

## 要件定義

### 機能要件
1. **商品データの永続化**
   - スキャンした商品をFirebase Firestoreに保存
   - アプリ起動時にFirebaseからデータを読み込み
   - 商品の更新・削除をFirebaseに同期

2. **リアルタイム同期**
   - 複数デバイス間でのデータ共有
   - オフライン対応（ローカルキャッシュ）

3. **データ構造**
   - 既存の`Product`モデルを維持
   - 複数段階画像（`imageUrls`）の保存対応
   - メーカー情報の保存対応

### 非機能要件
1. **パフォーマンス**
   - 初回読み込み時間 < 3秒
   - 商品追加・更新の応答時間 < 1秒

2. **信頼性**
   - オフライン時のローカル保存
   - ネットワーク復旧時の自動同期

3. **セキュリティ**
   - Firestoreセキュリティルールの設定
   - 認証なしでの読み書き制限

## 実装ロードマップ

### Phase 1: 基盤整備（1-2日）

#### 1.1 Productモデルの拡張
- [ ] `Product.fromFirestore()` メソッドの実装
- [ ] `Product.toFirestore()` メソッドの実装
- [ ] 複数段階画像のFirestore保存対応
- [ ] メーカー情報の保存対応

#### 1.2 FirestoreServiceの更新
- [ ] 既存の`FirestoreService`を商品管理用に拡張
- [ ] 商品CRUD操作の実装
- [ ] エラーハンドリングの強化

#### 1.3 データソース層の統合
- [ ] `FirestoreProductDataSource`の完全実装
- [ ] 既存の`ProductDataSource`インターフェースとの統合
- [ ] リポジトリ層でのFirebase使用

### Phase 2: 状態管理の統合（1-2日）

#### 2.1 AppStateNotifierの更新
- [ ] Firebaseとの同期機能追加
- [ ] 初期データ読み込み機能
- [ ] オフライン対応の実装

#### 2.2 プロバイダーの更新
- [ ] `productsProvider`のFirebase連携
- [ ] リアルタイム更新の実装
- [ ] エラー状態の管理

#### 2.3 初期化処理
- [ ] アプリ起動時のFirebaseデータ読み込み
- [ ] ローディング状態の管理
- [ ] エラーハンドリング

### Phase 3: UI統合（1日）

#### 3.1 既存画面の更新
- [ ] 商品追加時のFirebase保存
- [ ] 商品編集時のFirebase更新
- [ ] 商品削除時のFirebase削除

#### 3.2 エラーハンドリング
- [ ] ネットワークエラーの表示
- [ ] オフライン状態の表示
- [ ] リトライ機能の実装

### Phase 4: 最適化・テスト（1日）

#### 4.1 パフォーマンス最適化
- [ ] ページネーションの実装
- [ ] キャッシュ戦略の最適化
- [ ] 画像の遅延読み込み

#### 4.2 テスト・検証
- [ ] 単体テストの追加
- [ ] 統合テストの実装
- [ ] ユーザーテストの実施

## 技術仕様

### Firestoreコレクション構造
```
products/
├── {productId}/
│   ├── id: string
│   ├── janCode: string?
│   ├── name: string
│   ├── manufacturer: string?
│   ├── category: string
│   ├── expiryDate: timestamp
│   ├── addedDate: timestamp
│   ├── scannedAt: timestamp?
│   ├── imageUrl: string? (後方互換性)
│   ├── imageUrls: map<string, string> (複数段階画像)
│   ├── barcode: string?
│   ├── quantity: number
│   └── unit: string
```

### セキュリティルール
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /products/{productId} {
      allow read, write: if true; // 開発用（本番では認証必須）
    }
  }
}
```

## リスク管理

### 技術的リスク
1. **データ移行**: 既存のメモリデータの移行
2. **パフォーマンス**: 大量データでの読み込み時間
3. **オフライン対応**: ネットワーク断絶時の動作

### 対策
1. **段階的移行**: 既存機能を維持しながら段階的に移行
2. **キャッシュ戦略**: ローカルキャッシュとFirebaseの併用
3. **フォールバック**: オフライン時のローカル保存

## 成功指標

### 機能指標
- [ ] 商品データの永続化が正常に動作
- [ ] アプリ再起動後もデータが保持される
- [ ] 複数デバイス間でデータが同期される

### パフォーマンス指標
- [ ] 初回読み込み時間 < 3秒
- [ ] 商品操作の応答時間 < 1秒
- [ ] オフライン時の動作が正常

## 次のステップ

1. **Phase 1の開始**: Productモデルの拡張から着手
2. **既存機能の確認**: 現在の商品管理機能の動作確認
3. **Firebase設定の検証**: 既存のFirebase設定の動作確認

---

**作成日**: 2024年12月19日  
**更新日**: 2024年12月19日  
**担当者**: AI Assistant
