# セキュリティ設定ガイド

## 🔐 重要なセキュリティ情報

このプロジェクトでは、以下のセキュリティ対策を実施してください。

## 1. 環境変数の設定

`.env.example`をコピーして`.env`ファイルを作成し、実際の値を設定してください：

```bash
cp .env.example .env
```

**注意**: `.env`ファイルは絶対にGitにコミットしないでください。

## 2. APIキーの管理

### Gemini APIキー
1. [Google AI Studio](https://makersuite.google.com/app/apikey)でAPIキーを取得
2. `lib/core/services/gemini_service.dart`の`_apiKey`を環境変数から読み込むように変更

### Firebase設定
1. Firebase Consoleでプロジェクト設定を確認
2. `lib/core/config/firebase_config.dart`の値を確認・更新

### Vertex AI認証
1. サービスアカウントキーをダウンロード
2. `gcp-credentials.json`として保存（.gitignoreに含まれています）
3. 環境変数`GOOGLE_APPLICATION_CREDENTIALS`を設定

## 3. Firebaseセキュリティルール

Firestoreのセキュリティルールを設定：

```javascript
// firestore.rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // ユーザーは自分のデータのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // 世帯メンバーのみアクセス可能
    match /households/{householdId} {
      allow read: if request.auth != null && 
        request.auth.uid in resource.data.members;
      allow write: if request.auth != null && 
        request.auth.uid in resource.data.members;
    }
    
    // アイテムは世帯メンバーのみアクセス可能
    match /items/{itemId} {
      allow read, write: if request.auth != null && 
        exists(/databases/$(database)/documents/households/$(resource.data.householdId)) &&
        request.auth.uid in get(/databases/$(database)/documents/households/$(resource.data.householdId)).data.members;
    }
  }
}
```

## 4. Cloud Functionsのセキュリティ

Cloud Functionsには認証チェックが実装済み：
- `context.auth`で認証状態を確認
- 認証されていないリクエストは拒否

## 5. 本番環境へのデプロイ前チェックリスト

- [ ] すべてのAPIキーが環境変数から読み込まれている
- [ ] デバッグログが無効化されている
- [ ] Firebaseセキュリティルールが適用されている
- [ ] Cloud Functionsの認証が有効
- [ ] CORSが適切に設定されている
- [ ] HTTPSが強制されている
- [ ] 個人情報が暗号化されている

## 6. 定期的なセキュリティ監査

- Firebase Consoleでセキュリティアラートを確認
- 依存関係の脆弱性をチェック：`flutter pub outdated`
- Cloud Functionsのログを監視

## 7. インシデント対応

セキュリティインシデントが発生した場合：
1. 影響を受けたAPIキーを即座に無効化
2. 新しいキーを生成して更新
3. アクセスログを確認
4. 必要に応じてユーザーに通知

## お問い合わせ

セキュリティに関する問題を発見した場合は、公開せずに開発チームに直接連絡してください。