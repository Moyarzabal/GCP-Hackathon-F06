# 🚀 デプロイメントガイド

## デプロイオプションの比較

### 1. Firebase Hosting（推奨: フロントエンド）
**メリット:**
- ✅ 高速なCDN配信
- ✅ 自動SSL証明書
- ✅ 簡単なデプロイ（1コマンド）
- ✅ 無料枠が豊富
- ✅ Firebase統合が簡単

**デメリット:**
- ❌ 静的ホスティングのみ
- ❌ サーバーサイド処理不可

### 2. Cloud Run（推奨: バックエンド/API）
**メリット:**
- ✅ サーバーサイドレンダリング可能
- ✅ 自動スケーリング
- ✅ コンテナベースで柔軟
- ✅ Vertex AI直接連携
- ✅ 高度なカスタマイズ可能

**デメリット:**
- ❌ 初期設定が複雑
- ❌ コールドスタート遅延
- ❌ 料金が若干高い

## 推奨アーキテクチャ 🏗️

```
┌─────────────────┐     ┌──────────────────┐
│  Flutter Web    │────▶│ Firebase Hosting │ (静的ファイル配信)
│   (Frontend)    │     └──────────────────┘
└─────────────────┘              │
                                 ▼
                    ┌────────────────────────┐
                    │   Cloud Functions      │ (軽量API)
                    │  - 通知処理            │
                    │  - 定期ジョブ          │
                    └────────────────────────┘
                                 │
                                 ▼
                    ┌────────────────────────┐
                    │     Cloud Run          │ (重い処理)
                    │  - Vertex AI連携       │
                    │  - 画像生成            │
                    │  - 大量データ処理     │
                    └────────────────────────┘
```

---

## Option 1: Firebase Hosting デプロイ（シンプル・推奨）

### 準備
```bash
# Firebase CLIインストール（済み）
npm install -g firebase-tools

# ログイン
firebase login

# プロジェクト初期化（済み）
firebase init
```

### デプロイ手順
```bash
# 1. Flutter Webビルド
flutter build web --release

# 2. Firebase Hostingにデプロイ
firebase deploy --only hosting

# 3. Cloud Functionsもデプロイ
firebase deploy --only functions

# または全部一度に
firebase deploy
```

### アクセスURL
```
https://gcp-f06-barcode.web.app
https://gcp-f06-barcode.firebaseapp.com
```

---

## Option 2: Cloud Run デプロイ（高度な制御）

### Dockerfileの準備
```dockerfile
# Dockerfile
FROM nginx:alpine

# Flutter webビルドをコピー
COPY build/web /usr/share/nginx/html

# nginx設定をコピー
COPY nginx.conf /etc/nginx/nginx.conf

EXPOSE 8080
CMD ["nginx", "-g", "daemon off;"]
```

### Cloud Runへのデプロイ
```bash
# 1. Flutter Webビルド
flutter build web --release

# 2. Docker イメージビルド
docker build -t asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest .

# 3. イメージをプッシュ
docker push asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest

# 4. Cloud Runにデプロイ
gcloud run deploy barcode-scanner-web \
  --image=asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --port=8080 \
  --memory=512Mi \
  --cpu=1
```

---

## Option 3: ハイブリッドデプロイ（最適解）🎯

### 構成
- **Firebase Hosting**: Flutter Web（フロントエンド）
- **Cloud Functions**: 軽量API、定期ジョブ
- **Cloud Run**: Vertex AI連携、重い処理

### セットアップ手順

#### 1. Firebase Hostingデプロイ
```bash
# Flutter Webをビルド
flutter build web --release

# Firebase Hostingにデプロイ
firebase deploy --only hosting
```

#### 2. Cloud Functionsデプロイ
```bash
cd functions
npm install
cd ..
firebase deploy --only functions
```

#### 3. Cloud Run API（Vertex AI用）
```bash
# Cloud Run用の別プロジェクト作成
mkdir cloud-run-api
cd cloud-run-api

# package.json作成
npm init -y
npm install express @google-cloud/aiplatform cors body-parser

# server.jsを作成（Vertex AI処理）
# Dockerfileを作成
# デプロイ
```

### firebase.jsonの設定
```json
{
  "hosting": {
    "public": "build/web",
    "ignore": ["firebase.json", "**/.*", "**/node_modules/**"],
    "rewrites": [
      {
        "source": "/api/vertex/**",
        "run": {
          "serviceId": "vertex-ai-service",
          "region": "asia-northeast1"
        }
      },
      {
        "source": "/api/**",
        "function": "api"
      },
      {
        "source": "**",
        "destination": "/index.html"
      }
    ]
  }
}
```

---

## 推奨: まずはFirebase Hostingでスタート 🚀

```bash
# 簡単3ステップでデプロイ
flutter build web --release
firebase deploy --only hosting
firebase deploy --only functions
```

**理由:**
1. 設定が簡単
2. 無料枠で十分
3. 後からCloud Run追加可能
4. Firebase統合がスムーズ

---

## パフォーマンス最適化

### 1. ビルド最適化
```bash
# 最適化ビルド
flutter build web --release --web-renderer canvaskit --dart-define=FLUTTER_WEB_USE_SKIA=true

# Tree shaking有効
flutter build web --release --tree-shake-icons
```

### 2. Firebase Hosting設定
```json
// firebase.json
{
  "hosting": {
    "headers": [
      {
        "source": "**/*.@(js|css)",
        "headers": [{
          "key": "Cache-Control",
          "value": "max-age=31536000"
        }]
      }
    ]
  }
}
```

### 3. 圧縮設定
```json
{
  "hosting": {
    "headers": [
      {
        "source": "**",
        "headers": [{
          "key": "Content-Encoding",
          "value": "gzip"
        }]
      }
    ]
  }
}
```

---

## 環境変数の設定

### Firebase Functions
```bash
# 環境変数設定
firebase functions:config:set gemini.key="YOUR_API_KEY"
firebase functions:config:set vertex.project="gcp-f06-barcode"

# 確認
firebase functions:config:get
```

### Cloud Run
```bash
# 環境変数付きでデプロイ
gcloud run deploy barcode-scanner-web \
  --set-env-vars="GEMINI_API_KEY=YOUR_KEY" \
  --set-env-vars="GCP_PROJECT=gcp-f06-barcode"
```

---

## モニタリング

### Firebase Console
- https://console.firebase.google.com/project/gcp-f06-barcode/hosting

### Cloud Run Console  
- https://console.cloud.google.com/run

### ログ確認
```bash
# Firebase Functions
firebase functions:log

# Cloud Run
gcloud run logs read --service=barcode-scanner-web
```

---

## トラブルシューティング

### CORS エラー
```javascript
// Cloud Functions
exports.api = functions.https.onRequest((req, res) => {
  res.set('Access-Control-Allow-Origin', '*');
  res.set('Access-Control-Allow-Methods', 'GET, POST');
  // ...
});
```

### 404 エラー
```json
// firebase.json
{
  "hosting": {
    "rewrites": [{
      "source": "**",
      "destination": "/index.html"
    }]
  }
}
```

### ビルドエラー
```bash
# クリーンビルド
flutter clean
flutter pub get
flutter build web --release
```

---

## コスト見積もり

### Firebase Hosting（月額）
- **無料枠**: 10GB転送、1GBストレージ
- **想定コスト**: $0（小規模なら無料枠内）

### Cloud Functions（月額）
- **無料枠**: 200万回実行、40万GB秒
- **想定コスト**: $0-10（通常利用）

### Cloud Run（月額）
- **無料枠**: 200万リクエスト
- **想定コスト**: $10-50（Vertex AI利用時）

---

## 次のステップ

1. **Firebase Hostingでまずデプロイ** ✅
2. パフォーマンス測定
3. 必要に応じてCloud Run追加
4. CI/CD設定（GitHub Actions）
5. カスタムドメイン設定