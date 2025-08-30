# GCP-Hackathon-F06

## バーコードスキャナー MVP

超ミニマムMVPのバーコードスキャナーアプリが開発完了しました！
Firebase Hostingにデプロイする準備が整っています。

## ✅ 完成した機能
- バーコードをスキャンしてJANコードを取得
- ハードコードされた商品データから商品名を表示
- Flutter Webで動作
- カメラ権限の設定済み

## 📁 プロジェクト構造
```
GCP-Hackathon-F06/            # プロジェクトルート（Flutterアプリ）
├── lib/main.dart              # メインアプリケーション
├── build/web/                 # ビルド済みWebアプリ
├── web/index.html             # Web設定（カメラ権限含む）
├── firebase.json              # Firebase設定
├── .firebaserc                # Firebaseプロジェクト設定
└── pubspec.yaml               # Flutter依存関係
```

## 🌐 ローカルテスト
現在、ローカルサーバーが起動中です：
```bash
http://localhost:8080
```

## 🚀 デプロイ状況

### 現在稼働中のURL
- **Firebase Hosting**: https://gcp-f06-barcode.web.app (デプロイ済み✅)
- **プロジェクトID**: gcp-f06-barcode

## 📝 デプロイ方法

### オプション1: Firebase Hosting（デプロイ済み）

#### デプロイ手順
```bash
# 1. Firebaseにログイン
firebase login

# 2. デプロイ実行
firebase deploy --only hosting
```

#### 更新時
```bash
# 1. Flutterアプリをビルド
flutter build web

# 2. デプロイ
firebase deploy --only hosting
```

### オプション2: Cloud Run（将来の拡張用）

Cloud Runを使用することで、将来的なバックエンドAPI統合が容易になります。

#### 前提条件
- [Google Cloud CLI](https://cloud.google.com/sdk/docs/install)
- [Docker Desktop](https://www.docker.com/products/docker-desktop/)

#### 初回セットアップ
```bash
# 1. Google Cloudにログイン
gcloud auth login

# 2. プロジェクトを設定
gcloud config set project gcp-f06-barcode

# 3. 必要なAPIを有効化
gcloud services enable artifactregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable run.googleapis.com

# 4. Artifact Registryリポジトリを作成
gcloud artifacts repositories create barcode-scanner \
  --repository-format=docker \
  --location=asia-northeast1 \
  --description="Barcode Scanner Flutter Web App"
```

#### デプロイ手順
```bash
# 1. Dockerイメージをビルド
docker build -t asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest .

# 2. Docker認証設定
gcloud auth configure-docker asia-northeast1-docker.pkg.dev

# 3. イメージをプッシュ
docker push asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest

# 4. Cloud Runにデプロイ
gcloud run deploy barcode-scanner-web \
  --image=asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest \
  --platform=managed \
  --region=asia-northeast1 \
  --allow-unauthenticated \
  --port=8080 \
  --memory=256Mi \
  --cpu=1
```

#### 更新時の手順
```bash
# 1. Flutterアプリをビルド
flutter build web

# 2. Dockerイメージを再ビルド＆プッシュ
docker build -t asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest .
docker push asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest

# 3. Cloud Runを更新
gcloud run deploy barcode-scanner-web \
  --image=asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest \
  --region=asia-northeast1
```

## 📊 デプロイ方法の比較

| 項目 | Firebase Hosting | Cloud Run |
|------|-----------------|-----------|
| URL | https://gcp-f06-barcode.web.app | https://barcode-scanner-web-[HASH]-an.a.run.app |
| 料金 | 無料枠が大きい | 従量課金（最小インスタンス0可） |
| CDN | 自動配備 | Cloud CDN設定必要 |
| バックエンド統合 | Cloud Functions連携 | 同一コンテナで実装可能 |
| スケーリング | 自動 | 自動（設定可能） |
| カスタムドメイン | 簡単 | 可能 |
| 推奨用途 | 静的サイト・MVP | API統合・マイクロサービス |

## 🔧 トラブルシューティング

### カメラが動作しない場合
- HTTPSでアクセスしているか確認
- ブラウザのカメラ権限を許可

### 商品が認識されない場合
現在、以下のJANコードのみ対応：
- 4901777018888: コカ・コーラ 500ml
- 4902220770199: ポカリスエット 500ml
- 4901005202078: カップヌードル
- 4901301231123: ヤクルト
- 4902102072670: 午後の紅茶
- 4901005200074: どん兵衛
- 4901551354313: カルピスウォーター
- 4901777018871: ファンタオレンジ

## 🎯 次のステップ
1. Firestore連携で商品データをクラウド管理
2. Firebase Authでユーザー認証
3. Open Food Facts APIで商品情報を自動取得
4. UI/UXの改善

## 📱 動作確認済み環境
- Chrome (最新版)
- Safari (iOS 14以降)
- Edge (最新版)

## 🛠️ 技術スタック
- Flutter Web
- mobile_scanner パッケージ
- Firebase Hosting
- Firebase Core

---
開発完了！デプロイの準備ができています 🎉


