#!/bin/bash

# GitHub CLIを使ったシークレット設定確認スクリプト

set -e

echo "🔍 GitHub Secretsの確認を開始します..."

# 必要なシークレット一覧
REQUIRED_SECRETS=(
    "FIREBASE_SERVICE_ACCOUNT"
    "GEMINI_API_KEY"
    "FIREBASE_API_KEY"
    "FIREBASE_AUTH_DOMAIN"
    "FIREBASE_PROJECT_ID"
    "FIREBASE_STORAGE_BUCKET"
    "FIREBASE_MESSAGING_SENDER_ID"
    "FIREBASE_APP_ID"
    "FIREBASE_MEASUREMENT_ID"
)

OPTIONAL_SECRETS=(
    "CODECOV_TOKEN"
    "SLACK_WEBHOOK_URL"
    "FIREBASE_IOS_CLIENT_ID"
    "FIREBASE_IOS_BUNDLE_ID"
    "WEBPAGETEST_API_KEY"
)

# 色の設定
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# GitHub CLIの確認
if ! command -v gh &> /dev/null; then
    echo -e "${RED}❌ GitHub CLI (gh) がインストールされていません${NC}"
    echo "インストール方法: https://cli.github.com/"
    exit 1
fi

# ログイン確認
if ! gh auth status &> /dev/null; then
    echo -e "${RED}❌ GitHub CLIにログインしていません${NC}"
    echo "ログイン方法: gh auth login"
    exit 1
fi

echo -e "${GREEN}✅ GitHub CLI認証確認完了${NC}"

# 既存のシークレット一覧を取得
echo "📋 現在のシークレット一覧を取得中..."
EXISTING_SECRETS=$(gh secret list --json name -q '.[].name')

# 必須シークレットの確認
echo ""
echo "🔑 必須シークレットの確認:"
MISSING_REQUIRED=0

for secret in "${REQUIRED_SECRETS[@]}"; do
    if echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
        echo -e "  ${GREEN}✅ $secret${NC}"
    else
        echo -e "  ${RED}❌ $secret (未設定)${NC}"
        MISSING_REQUIRED=1
    fi
done

# オプションシークレットの確認
echo ""
echo "🔧 オプションシークレットの確認:"
for secret in "${OPTIONAL_SECRETS[@]}"; do
    if echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
        echo -e "  ${GREEN}✅ $secret${NC}"
    else
        echo -e "  ${YELLOW}⚠️  $secret (オプション・未設定)${NC}"
    fi
done

# 環境別シークレットの確認
echo ""
echo "🌍 環境別シークレットの確認:"

# Production環境の確認
echo "  Production環境:"
PROD_SECRETS=$(gh secret list --env production 2>/dev/null || echo "")
if [ -n "$PROD_SECRETS" ]; then
    echo -e "    ${GREEN}✅ Production環境のシークレット設定あり${NC}"
else
    echo -e "    ${YELLOW}⚠️  Production環境のシークレット未設定${NC}"
fi

# Staging環境の確認
echo "  Staging環境:"
STAGING_SECRETS=$(gh secret list --env staging 2>/dev/null || echo "")
if [ -n "$STAGING_SECRETS" ]; then
    echo -e "    ${GREEN}✅ Staging環境のシークレット設定あり${NC}"
else
    echo -e "    ${YELLOW}⚠️  Staging環境のシークレット未設定${NC}"
fi

# 結果サマリー
echo ""
echo "📊 確認結果サマリー:"

if [ $MISSING_REQUIRED -eq 0 ]; then
    echo -e "${GREEN}🎉 必須シークレットは全て設定済みです！${NC}"
    echo ""
    echo "🚀 CI/CDパイプラインが正常に動作するはずです。"
else
    echo -e "${RED}⚠️  未設定の必須シークレットがあります${NC}"
    echo ""
    echo "🔧 未設定のシークレットを設定するコマンド例:"
    echo ""
    for secret in "${REQUIRED_SECRETS[@]}"; do
        if ! echo "$EXISTING_SECRETS" | grep -q "^$secret$"; then
            echo "  gh secret set $secret"
        fi
    done
    echo ""
    echo "または、GitHubのWebページで設定:"
    echo "  Settings > Secrets and variables > Actions > New repository secret"
fi

# Firebase Service Accountの特別チェック
echo ""
echo "🔥 Firebase Service Accountの詳細確認:"
if echo "$EXISTING_SECRETS" | grep -q "^FIREBASE_SERVICE_ACCOUNT$"; then
    echo -e "  ${GREEN}✅ FIREBASE_SERVICE_ACCOUNT設定済み${NC}"
    echo "  💡 内容が正しいJSONフォーマットか確認してください"
else
    echo -e "  ${RED}❌ FIREBASE_SERVICE_ACCOUNT未設定${NC}"
    echo ""
    echo "  🔧 Firebase Service Accountの設定方法:"
    echo "    1. Firebase Console > Project Settings > Service Accounts"
    echo "    2. 'Generate new private key' をクリック"
    echo "    3. ダウンロードしたJSONファイルの内容をminifyしてシークレットに設定"
    echo "    4. コマンド例: gh secret set FIREBASE_SERVICE_ACCOUNT < service-account.json"
fi

echo ""
echo "✨ シークレット確認完了！"