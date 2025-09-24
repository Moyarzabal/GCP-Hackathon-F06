#!/bin/bash

# GitHub CLIを使ったシークレット一括設定スクリプト

set -e

echo "🔧 Firebase プロジェクトからGitHub Secretsを設定します..."

# 色の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) がインストールされていません${NC}"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# Firebase CLIの確認
if ! command -v firebase &> /dev/null; then
    echo -e "${RED}❌ Firebase CLI がインストールされていません${NC}"
    echo "インストール方法: npm install -g firebase-tools"
    exit 1
fi

# ログイン確認
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLIにログインしていません${NC}"
    echo "ログイン方法: gh auth login"
    exit 1
fi

if ! firebase login:list | grep -q "@"; then
    echo -e "${RED}❌ Firebase CLIにログインしていません${NC}"
    echo "ログイン方法: firebase login"
    exit 1
fi

echo -e "${GREEN}✅ CLI認証確認完了${NC}"

# Firebaseプロジェクト情報取得
echo -e "${BLUE}🔍 Firebase プロジェクト情報を取得中...${NC}"

# .firebasercからプロジェクトIDを取得
if [ ! -f ".firebaserc" ]; then
    echo -e "${RED}❌ .firebaserc が見つかりません${NC}"
    echo "firebase init を実行してプロジェクトを初期化してください"
    exit 1
fi

PROJECT_ID=$(grep -o '"default": "[^"]*"' .firebaserc | cut -d'"' -f4)

if [ -z "$PROJECT_ID" ]; then
    echo -e "${RED}❌ Firebase プロジェクトIDが見つかりません${NC}"
    exit 1
fi

echo "Firebase Project ID: $PROJECT_ID"

# Firebase設定の取得
echo -e "${BLUE}🔧 Firebase設定を取得中...${NC}"

# Firebaseプロジェクト設定を取得
firebase projects:list --json > /tmp/firebase_projects.json
WEB_CONFIG=$(firebase apps:sdkconfig web --project "$PROJECT_ID" --json 2>/dev/null || echo "{}")

# 設定値の抽出（JSONから）
API_KEY=$(echo "$WEB_CONFIG" | grep -o '"apiKey": "[^"]*"' | cut -d'"' -f4 || echo "")
AUTH_DOMAIN=$(echo "$WEB_CONFIG" | grep -o '"authDomain": "[^"]*"' | cut -d'"' -f4 || echo "")
STORAGE_BUCKET=$(echo "$WEB_CONFIG" | grep -o '"storageBucket": "[^"]*"' | cut -d'"' -f4 || echo "")
MESSAGING_SENDER_ID=$(echo "$WEB_CONFIG" | grep -o '"messagingSenderId": "[^"]*"' | cut -d'"' -f4 || echo "")
APP_ID=$(echo "$WEB_CONFIG" | grep -o '"appId": "[^"]*"' | cut -d'"' -f4 || echo "")
MEASUREMENT_ID=$(echo "$WEB_CONFIG" | grep -o '"measurementId": "[^"]*"' | cut -d'"' -f4 || echo "")

# 手動入力が必要な値
echo ""
echo -e "${YELLOW}📝 以下の値を手動で入力してください:${NC}"

read -p "Gemini API Key: " GEMINI_API_KEY
read -p "Firebase iOS Client ID (オプション): " IOS_CLIENT_ID
read -p "Firebase iOS Bundle ID (オプション): " IOS_BUNDLE_ID
read -p "Codecov Token (オプション): " CODECOV_TOKEN
read -p "Slack Webhook URL (オプション): " SLACK_WEBHOOK

# Service Account Keyの確認
echo ""
echo -e "${BLUE}🔑 Firebase Service Account設定${NC}"
if [ -f "firebase-service-account.json" ]; then
    echo "firebase-service-account.json が見つかりました"
    SERVICE_ACCOUNT_JSON=$(cat firebase-service-account.json)
else
    echo -e "${YELLOW}⚠️  firebase-service-account.json が見つかりません${NC}"
    echo "Firebase Console > Project Settings > Service Accounts から"
    echo "新しいプライベートキーを生成してダウンロードし、"
    echo "このディレクトリに firebase-service-account.json として保存してください"
    echo ""
    read -p "Service Account JSONファイルのパス: " SERVICE_ACCOUNT_PATH
    if [ -f "$SERVICE_ACCOUNT_PATH" ]; then
        SERVICE_ACCOUNT_JSON=$(cat "$SERVICE_ACCOUNT_PATH")
    else
        echo -e "${RED}❌ Service Account JSONファイルが見つかりません${NC}"
        exit 1
    fi
fi

# シークレットの設定
echo ""
echo -e "${BLUE}🚀 GitHub Secretsを設定中...${NC}"

# 必須シークレット
[ -n "$GEMINI_API_KEY" ] && echo "$GEMINI_API_KEY" | gh secret set GEMINI_API_KEY
[ -n "$API_KEY" ] && echo "$API_KEY" | gh secret set FIREBASE_API_KEY
[ -n "$AUTH_DOMAIN" ] && echo "$AUTH_DOMAIN" | gh secret set FIREBASE_AUTH_DOMAIN
[ -n "$PROJECT_ID" ] && echo "$PROJECT_ID" | gh secret set FIREBASE_PROJECT_ID
[ -n "$STORAGE_BUCKET" ] && echo "$STORAGE_BUCKET" | gh secret set FIREBASE_STORAGE_BUCKET
[ -n "$MESSAGING_SENDER_ID" ] && echo "$MESSAGING_SENDER_ID" | gh secret set FIREBASE_MESSAGING_SENDER_ID
[ -n "$APP_ID" ] && echo "$APP_ID" | gh secret set FIREBASE_APP_ID
[ -n "$MEASUREMENT_ID" ] && echo "$MEASUREMENT_ID" | gh secret set FIREBASE_MEASUREMENT_ID
[ -n "$SERVICE_ACCOUNT_JSON" ] && echo "$SERVICE_ACCOUNT_JSON" | gh secret set FIREBASE_SERVICE_ACCOUNT

# オプションシークレット
[ -n "$IOS_CLIENT_ID" ] && echo "$IOS_CLIENT_ID" | gh secret set FIREBASE_IOS_CLIENT_ID
[ -n "$IOS_BUNDLE_ID" ] && echo "$IOS_BUNDLE_ID" | gh secret set FIREBASE_IOS_BUNDLE_ID
[ -n "$CODECOV_TOKEN" ] && echo "$CODECOV_TOKEN" | gh secret set CODECOV_TOKEN
[ -n "$SLACK_WEBHOOK" ] && echo "$SLACK_WEBHOOK" | gh secret set SLACK_WEBHOOK_URL

echo ""
echo -e "${GREEN}✅ シークレット設定完了！${NC}"

# 設定確認
echo ""
echo -e "${BLUE}🔍 設定されたシークレットを確認中...${NC}"
.github/scripts/check-secrets.sh

echo ""
echo -e "${GREEN}🎉 セットアップ完了！${NC}"
echo "これでCI/CDパイプラインが正常に動作するはずです。"
echo ""
echo "次のステップ:"
echo "1. このブランチをプッシュ: git push origin feature/cicd-pipeline"
echo "2. プルリクエストを作成して動作確認"
echo "3. mainブランチにマージして本番デプロイテスト"