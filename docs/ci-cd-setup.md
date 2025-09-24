# CI/CDセットアップガイド

このドキュメントは、GCP-Hackathon-F06プロジェクトのCI/CD環境構築ガイドです。GitHub ActionsとFirebase Hostingを使用した自動デプロイシステムを構築します。

## 🎯 構築されるCI/CD環境

### デプロイ環境
1. **Production** - `main`ブランチ → 本番環境
2. **Staging** - `develop`ブランチ → ステージング環境
3. **Preview** - プルリクエスト → 一時プレビュー環境
4. **Branch** - その他ブランチ → ブランチ専用プレビュー

### ワークフロー
- **CI Pipeline** - テスト、ビルド、解析
- **Deploy Production** - 本番デプロイ
- **Deploy Preview** - PRプレビューデプロイ
- **Deploy Branch** - ブランチデプロイ

## 🚀 初期セットアップ

### 1. 自動セットアップスクリプト（推奨）

```bash
# GitHub CLI と Firebase CLI がインストール済みであることを確認
gh --version
firebase --version

# 自動セットアップスクリプトを実行
./.github/scripts/setup-secrets.sh

# シークレット設定状況を確認
./.github/scripts/check-secrets.sh
```

### 2. 手動でGitHubシークレット設定

GitHubリポジトリの `Settings` > `Secrets and variables` > `Actions` で以下を設定：

#### 必須シークレット
```
FIREBASE_SERVICE_ACCOUNT    # Firebase サービスアカウントJSON
GEMINI_API_KEY             # Google Gemini API キー
FIREBASE_API_KEY           # Firebase API キー
FIREBASE_AUTH_DOMAIN       # Firebase Auth Domain
FIREBASE_PROJECT_ID        # Firebase プロジェクトID
FIREBASE_STORAGE_BUCKET    # Firebase Storage Bucket
FIREBASE_MESSAGING_SENDER_ID # Firebase Messaging Sender ID
FIREBASE_APP_ID            # Firebase App ID
FIREBASE_MEASUREMENT_ID    # Firebase Analytics ID
```

#### オプションシークレット
```
CODECOV_TOKEN              # コードカバレッジ
SLACK_WEBHOOK_URL         # Slack通知
FIREBASE_IOS_CLIENT_ID    # iOS用
FIREBASE_IOS_BUNDLE_ID    # iOS用
```

### 3. Firebase設定

Firebase CLIでホスティングターゲットを設定：

```bash
# Firebase CLIインストール（未インストールの場合）
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクト初期化（すでに設定済みの場合はスキップ）
firebase init hosting

# ホスティングターゲット設定
firebase target:apply hosting production gcp-f06-barcode
firebase target:apply hosting staging staging-gcp-f06-barcode
```

### 4. GitHub CLI セットアップ

```bash
# GitHub CLIインストール（macOS）
brew install gh

# GitHub CLIインストール（Linux）
curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg | sudo dd of=/usr/share/keyrings/githubcli-archive-keyring.gpg
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | sudo tee /etc/apt/sources.list.d/github-cli.list > /dev/null
sudo apt update
sudo apt install gh

# ログイン
gh auth login
```

### 5. プロジェクトのFirebase設定確認

`.firebaserc` ファイルの確認：
```json
{
  "projects": {
    "default": "gcp-f06-barcode"
  },
  "targets": {
    "gcp-f06-barcode": {
      "hosting": {
        "production": ["gcp-f06-barcode"],
        "staging": ["staging-gcp-f06-barcode"]
      }
    }
  }
}
```

## 📋 ワークフロー詳細

### 改良されたワークフローの特徴

#### 最新バージョン使用
- **Flutter**: 3.29.0（2025年最新安定版）
- **GitHub Actions**: v4（actions/checkout@v4, actions/cache@v4等）
- **Firebase Hosting Action**: FirebaseExtended/action-hosting-deploy@v0

#### パフォーマンス最適化
- **キャッシュ戦略**: Flutter依存関係とビルドアーティファクトのキャッシュ
- **並行実行**: concurrency groupによる効率的なデプロイ管理
- **条件付き実行**: 変更検知による無駄なビルドの回避

#### 高信頼性
- **エラーハンドリング**: continue-on-error による柔軟な処理
- **スモークテスト**: デプロイ後の基本的なヘルスチェック
- **メタデータ追加**: バージョン情報やビルド時刻の記録

### 1. CI Pipeline (`ci.yml`)
**トリガー**: プッシュ・プルリクエスト
- 静的解析（Flutter analyze, dart format）
- ユニットテスト + カバレッジ
- マルチプラットフォームビルド（Web/iOS/Android）
- パフォーマンステスト（Lighthouse）
- 結果通知（Slack連携）

### 2. Production Deploy (`deploy-production.yml`)
**トリガー**: `main`ブランチへのプッシュ、手動実行
- **事前チェック**: テスト実行（スキップ可能）
- **最適化ビルド**: アセット圧縮、HTML minify
- **本番デプロイ**: Firebase Hosting live チャンネル
- **デプロイ後確認**: スモークテスト実行
- **通知**: Slack通知（オプション）

### 3. Preview Deploy (`deploy-preview.yml`)
**トリガー**: プルリクエスト作成・更新
- **変更検知**: 関連ファイルの変更のみデプロイ実行
- **高速ビルド**: キャッシュ最適化
- **プレビュー作成**: 7日間の一時プレビュー環境
- **PR統合**: 自動コメント更新、テストチェックリスト
- **スキップ通知**: 不要な場合の理由説明

### 4. Branch Deploy (`deploy-branch.yml`)
**トリガー**: フィーチャーブランチプッシュ
- **ブランチ名正規化**: Firebase チャンネル名に適した形式に変換
- **開発環境**: 開発用API エンドポイント使用
- **GitHub統合**: デプロイメント状態とURL記録
- **サマリー**: GitHub Step Summary での結果表示
- **長期保持**: 30日間の保持期間

## 🛠 開発ワークフロー

### 新機能開発
```bash
# feature ブランチ作成
git checkout -b feature/new-feature

# 開発・コミット
git add .
git commit -m "feat: 新機能実装"

# プッシュ（自動的にブランチデプロイ実行）
git push origin feature/new-feature
```

### プルリクエスト作成
```bash
# プルリクエスト作成 → プレビューデプロイ自動実行
# PRコメントにプレビューURL表示
```

### 本番デプロイ
```bash
# main ブランチにマージ → 本番デプロイ自動実行
git checkout main
git merge feature/new-feature
git push origin main
```

## 🔧 トラブルシューティング

### デプロイ失敗の場合

1. **GitHub Actions タブでログ確認**
2. **Firebase Service Account権限確認**
   ```bash
   # 権限確認
   firebase projects:list
   ```
3. **環境変数・シークレット設定確認**

### ビルドエラーの場合

1. **ローカルでのビルドテスト**
   ```bash
   flutter clean
   flutter pub get
   flutter build web
   ```

2. **Flutter バージョン確認**
   ```bash
   flutter --version
   # CI: 3.24.0 stable
   ```

### Firebase設定エラー

1. **プロジェクト確認**
   ```bash
   firebase projects:list
   firebase use --list
   ```

2. **ホスティングターゲット再設定**
   ```bash
   firebase target:clear hosting production
   firebase target:apply hosting production gcp-f06-barcode
   ```

## 📊 モニタリング

### CI/CD状況確認
- GitHub Actions タブ
- Firebase Console > Hosting
- Slack通知（設定時）

### デプロイ環境URL
- **Production**: `https://gcp-f06-barcode.web.app`
- **Staging**: `https://staging-gcp-f06-barcode.web.app`
- **Preview**: PR作成時にコメント表示
- **Branch**: `https://gcp-f06-barcode--branch-{ブランチ名}-{ハッシュ}.web.app`

## ⚡ パフォーマンス最適化

### キャッシュ設定
- 静的アセット: 1年間キャッシュ
- index.html: キャッシュなし
- staging環境: 1時間キャッシュ

### ビルド最適化
- `--tree-shake-icons`: 使用しないアイコン除去（production）
- `--split-per-abi`: APKサイズ最適化（Android）
- `--web-renderer html`: Web互換性向上

## 🔐 セキュリティ

1. **シークレット管理**: GitHub Secretsで暗号化
2. **環境分離**: 本番・開発環境完全分離
3. **権限制御**: Firebase IAM最小権限
4. **コード解析**: 自動セキュリティチェック

## 📚 参考リンク

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Firebase Hosting GitHub Action](https://github.com/FirebaseExtended/action-hosting-deploy)
- [Flutter CI/CD Guide](https://docs.flutter.dev/deployment/ci)
- [Firebase CLI Reference](https://firebase.google.com/docs/cli)