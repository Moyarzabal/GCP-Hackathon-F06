# 環境変数とシークレット設定ガイド

## 必要なGitHub Secrets

### Firebase関連
以下のシークレットをGitHub Repository Settingsで設定してください：

```
FIREBASE_SERVICE_ACCOUNT
GEMINI_API_KEY
FIREBASE_API_KEY
FIREBASE_AUTH_DOMAIN
FIREBASE_PROJECT_ID
FIREBASE_STORAGE_BUCKET
FIREBASE_MESSAGING_SENDER_ID
FIREBASE_APP_ID
FIREBASE_MEASUREMENT_ID
FIREBASE_IOS_CLIENT_ID
FIREBASE_IOS_BUNDLE_ID
```

### オプション設定
```
CODECOV_TOKEN          # コードカバレッジレポート用
SLACK_WEBHOOK_URL      # Slack通知用
```

## 設定方法

### 1. GitHubリポジトリでシークレット設定
1. GitHubリポジトリページで `Settings` > `Secrets and variables` > `Actions` に移動
2. `New repository secret` をクリック
3. 各シークレットを設定

### 2. Firebase Service Account設定
```bash
# Firebase CLIでサービスアカウントキーを生成
firebase login
firebase projects:list

# サービスアカウントキーを取得（JSON形式）
# このJSONをminify化してGitHubシークレットとして設定
```

### 3. 環境別設定

#### Production環境
- ブランチ: `main`
- Firebase Hosting: `production` target
- 環境変数: `ENVIRONMENT=production`

#### Staging環境
- ブランチ: `develop`
- Firebase Hosting: `staging` target
- 環境変数: `ENVIRONMENT=staging`

#### Preview環境
- プルリクエスト時
- Firebase Hosting: 一時的なプレビューURL
- 環境変数: `ENVIRONMENT=preview`

#### Branch環境
- `main`以外のブランチプッシュ時
- Firebase Hosting: `branch-{ブランチ名}` チャンネル
- 環境変数: `ENVIRONMENT=development`

## セキュリティ注意事項

1. **本番環境のAPIキーは絶対にコミットしない**
2. **`.env`ファイルは`.gitignore`に追加済み**
3. **環境変数は実行時にのみ作成される**
4. **シークレットはGitHubによって暗号化される**

## トラブルシューティング

### デプロイが失敗する場合
1. シークレットが正しく設定されているか確認
2. Firebase プロジェクトIDが正しいか確認
3. サービスアカウントの権限が適切か確認

### ビルドエラーが発生する場合
1. Flutter バージョンの確認
2. 依存関係の更新: `flutter pub get`
3. キャッシュクリア: `flutter clean`

## 環境変数の使用例

```dart
// lib/core/config/environment.dart
class Environment {
  static const String environment = String.fromEnvironment(
    'ENVIRONMENT',
    defaultValue: 'development',
  );

  static const String branch = String.fromEnvironment(
    'BRANCH',
    defaultValue: 'unknown',
  );

  static bool get isProduction => environment == 'production';
  static bool get isStaging => environment == 'staging';
  static bool get isDevelopment => environment == 'development';
}
```