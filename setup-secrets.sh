#!/bin/bash

# GitHub Secrets設定スクリプト
# 実行前に確認: gh auth status

REPO="Moyarzabal/GCP-Hackathon-F06"

echo "🔐 GitHub Secrets設定を開始します..."
echo "Repository: $REPO"
echo ""

# .envファイルから値を読み込む
if [ -f .env ]; then
    source .env
    echo "✅ .envファイルを読み込みました"
else
    echo "❌ .envファイルが見つかりません"
    exit 1
fi

# 1. Firebase/GCP基本設定
echo "📦 Firebase/GCP設定を追加中..."

gh secret set FIREBASE_API_KEY --body "$FIREBASE_API_KEY" --repo $REPO
gh secret set FIREBASE_AUTH_DOMAIN --body "$FIREBASE_AUTH_DOMAIN" --repo $REPO
gh secret set FIREBASE_PROJECT_ID --body "$FIREBASE_PROJECT_ID" --repo $REPO
gh secret set FIREBASE_STORAGE_BUCKET --body "$FIREBASE_STORAGE_BUCKET" --repo $REPO
gh secret set FIREBASE_MESSAGING_SENDER_ID --body "$FIREBASE_MESSAGING_SENDER_ID" --repo $REPO
gh secret set FIREBASE_APP_ID --body "$FIREBASE_APP_ID" --repo $REPO

gh secret set GCP_PROJECT_ID --body "$GCP_PROJECT_ID" --repo $REPO
gh secret set GCP_PROJECT_NUMBER --body "$GCP_PROJECT_NUMBER" --repo $REPO
gh secret set GCP_REGION --body "$GCP_REGION" --repo $REPO

# 2. API Keys
echo "🔑 APIキーを追加中..."

gh secret set GEMINI_API_KEY --body "$GEMINI_API_KEY" --repo $REPO

# 3. サービスアカウント（手動で設定が必要）
echo ""
echo "⚠️  以下のSecretsは手動で設定が必要です:"
echo ""
echo "1. FIREBASE_SERVICE_ACCOUNT_PROD"
echo "   - Firebase Console > プロジェクト設定 > サービスアカウント"
echo "   - '新しい秘密鍵を生成'をクリック"
echo "   - ダウンロードしたJSONファイルの内容を設定"
echo "   コマンド例:"
echo "   gh secret set FIREBASE_SERVICE_ACCOUNT_PROD < path/to/service-account.json --repo $REPO"
echo ""
echo "2. FIREBASE_SERVICE_ACCOUNT_STAGING"
echo "   - 本番と同じ手順（別環境の場合）"
echo "   - または本番と同じ値を使用"
echo ""

# 4. 設定確認
echo "📋 設定済みのSecretsを確認中..."
gh secret list --repo $REPO

echo ""
echo "✅ 基本的なSecretsの設定が完了しました！"
echo ""
echo "次のステップ:"
echo "1. Firebase サービスアカウントキーをダウンロード"
echo "2. 以下のコマンドで設定:"
echo "   gh secret set FIREBASE_SERVICE_ACCOUNT_PROD < service-account.json --repo $REPO"
echo "3. CI/CDワークフローを実行してテスト"