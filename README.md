# 🍅 冷蔵庫管理AIアプリ - FridgeManager AI

[![Flutter](https://img.shields.io/badge/Flutter-3.35.2-blue.svg)](https://flutter.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20|%20Android-green.svg)]()
[![Firebase](https://img.shields.io/badge/Backend-Firebase-orange.svg)](https://firebase.google.com)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

バーコードスキャンとAIを活用した、楽しく食品ロスを削減する冷蔵庫管理モバイルアプリ

## 📱 概要

食材をキャラクター化し、賞味期限管理を楽しい体験に変える革新的なモバイルアプリケーション。バーコードスキャンで商品情報を自動取得し、AIが賞味期限に応じて食材の感情を表現します（😊→😐→😟→😰→💀）。

### 主な特徴

- 📸 **バーコードスキャン**: カメラで商品を簡単登録
- 🤖 **AI OCR**: 賞味期限を自動読み取り
- 🎨 **キャラクター生成**: 食材を可愛いキャラクターに変換
- 👨‍👩‍👧‍👦 **家族共有**: 世帯単位での食材管理
- 🍳 **レシピ提案**: 期限が近い食材を使ったレシピをAIが提案
- 📊 **履歴管理**: スキャンした商品の履歴を確認
- ⚙️ **設定**: アプリの各種設定をカスタマイズ

## 🏗 システムアーキテクチャ

```
┌─────────────────┐     ┌──────────────────┐
│  Flutter App    │────▶│   Firebase       │
│  (iOS/Android)  │     │   Backend        │
└─────────────────┘     └──────────────────┘
         │                       ▼
         │              ┌────────────────────┐
         │              │ Firebase Services  │
         │              ├────────────────────┤
         │              │ • Cloud Firestore   │
         │              │ • Cloud Storage     │
         │              │ • Cloud Functions   │
         │              └────────────────────┘
         │                       │
         ▼                       ▼
┌──────────────────┐    ┌──────────────────┐
│  External APIs   │    │   AI Services    │
├──────────────────┤    ├──────────────────┤
│ • Open Food Facts│    │ • ML Kit (OCR)   │
│ • Product DBs    │    │ • Vertex AI      │
└──────────────────┘    │ • Gemini API     │
                        └──────────────────┘
```

## 🛠 技術スタック

### モバイルアプリ
- **Framework**: Flutter 3.35.2
- **Platforms**: iOS (13.0+), Android (API 21+)
- **State Management**: Riverpod 2.6.1
- **UI Components**: Material Design 3
- **Animations**: Rive 0.13.17

### バックエンド
- **Database**: Cloud Firestore
- **Storage**: Cloud Storage
- **Functions**: Cloud Functions (Node.js 20)

### AI/ML Services
- **OCR**: Google ML Kit Text Recognition
- **Barcode**: Google ML Kit Barcode Scanning
- **Image Generation**: Vertex AI Imagen
- **Recipe AI**: Google Gemini API
- **Product Info**: Open Food Facts API

## 📦 プロジェクト構造

```
lib/
├── app.dart                    # メインアプリケーション
├── main.dart                   # エントリーポイント
├── core/                       # コア機能
│   ├── config/                # Firebase設定
│   ├── constants/             # 定数定義
│   └── services/              # サービス層
│       ├── firestore_service.dart
│       ├── ocr_service.dart
│       ├── imagen_service.dart
│       └── gemini_service.dart
├── features/                   # 機能別モジュール
│   ├── home/                  # ホーム画面
│   ├── scanner/               # バーコードスキャナー
│   ├── products/              # 商品管理
│   ├── household/             # 世帯管理
│   ├── history/               # 履歴
│   └── settings/              # 設定
└── shared/                     # 共通コンポーネント
    ├── models/                # データモデル
    ├── providers/             # 状態管理
    └── widgets/               # 共通ウィジェット

functions/                      # Cloud Functions
├── index.js                   # 関数定義
└── package.json              # 依存関係
```

## 🚀 セットアップ

### 前提条件

- Flutter SDK 3.35.2以上
- Node.js 20以上
- Firebase CLI
- Googleアカウント

### 1. リポジトリのクローン

```bash
git clone https://github.com/yourusername/GCP-Hackathon-F06.git
cd GCP-Hackathon-F06
```

### 2. 依存関係のインストール

```bash
# Flutter依存関係
flutter pub get

# Cloud Functions依存関係
cd functions
npm install
cd ..
```

### 3. 環境変数の設定

`.env.example`をコピーして`.env`を作成：

```bash
cp .env.example .env
```

以下の環境変数を設定：

```env
# Firebase Configuration
FIREBASE_API_KEY=your_firebase_api_key
FIREBASE_AUTH_DOMAIN=gcp-f06-barcode.firebaseapp.com
FIREBASE_PROJECT_ID=gcp-f06-barcode
FIREBASE_STORAGE_BUCKET=gcp-f06-barcode.appspot.com
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
FIREBASE_APP_ID=your_app_id

# Gemini API
GEMINI_API_KEY=your_gemini_api_key

# Vertex AI
VERTEX_AI_PROJECT=gcp-f06-barcode
VERTEX_AI_LOCATION=asia-northeast1

# FCM Web Push
VAPID_KEY=your_vapid_key
```

### 4. Firebase設定

#### Firestoreの有効化

1. [Firebase Console](https://console.firebase.google.com)にアクセス
2. プロジェクトを選択
3. Firestore Databaseを有効化
4. セキュリティルールを設定：

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // 認証済みユーザーのみアクセス可能
    match /users/{userId} {
      allow read, write: if request.auth != null && 
        request.auth.uid == userId;
    }
    
    // 世帯メンバーのみアクセス可能
    match /households/{householdId} {
      allow read, write: if request.auth != null && 
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

#### 認証の設定

Firebase Console → Authentication → Sign-in methodで以下を有効化：
- メール/パスワード
- Google
- Apple（iOS開発者アカウントが必要）

### 5. APIキーの取得

#### Gemini API
1. [Google AI Studio](https://makersuite.google.com/app/apikey)でAPIキーを生成
2. `lib/core/services/gemini_service.dart`の`_apiKey`を更新

#### Vertex AI
1. GCPコンソールでVertex AIを有効化
2. サービスアカウントキーをダウンロード
3. 環境変数`GOOGLE_APPLICATION_CREDENTIALS`に設定

## 💻 開発

### ローカル実行

```bash
# Webアプリの起動
flutter run -d chrome

# Cloud Functionsのエミュレータ
firebase emulators:start --only functions
```

### ビルド

```bash
# プロダクションビルド
flutter build web --release

# 最適化ビルド
flutter build web --release --web-renderer canvaskit
```

### テスト

```bash
# ユニットテスト
flutter test

# カバレッジ付きテスト
flutter test --coverage
```

## 🚢 デプロイ

### iOS App Storeへのデプロイ

```bash
# ビルド
flutter build ios --release

# Xcodeでアーカイブとアップロード
open ios/Runner.xcworkspace
# Product > Archive を選択
# App Store Connectにアップロード
```

### Google Play Storeへのデプロイ

```bash
# App Bundleをビルド
flutter build appbundle --release

# Google Play Consoleにアップロード
# build/app/outputs/bundle/release/app-release.aab
```

### TestFlight/内部テストへの配布

```bash
# iOS TestFlight
# App Store ConnectでTestFlightを設定
# テスターを招待

# Android 内部テスト
# Google Play Consoleで内部テストトラックを設定
# テスターを招待
```

## 📱 使い方

1. **アカウント作成**
   - メールアドレスまたはGoogleアカウントで登録

2. **世帯の設定**
   - 新規世帯を作成または既存世帯に参加

3. **商品の登録**
   - バーコードスキャンまたは手動入力
   - 賞味期限を設定

4. **管理と通知**
   - ホーム画面で商品一覧を確認
   - 期限が近づくと通知を受信

5. **レシピ提案**
   - 期限が近い食材を使ったレシピをAIが提案

## 🧪 テスト用バーコード

開発・テスト用のJANコード：

| JANコード | 商品名 | カテゴリ |
|-----------|--------|----------|
| 4901777018888 | コカ・コーラ 500ml | 飲料 |
| 4902220770199 | ポカリスエット 500ml | 飲料 |
| 4901005202078 | カップヌードル | 食品 |
| 4901301231123 | ヤクルト | 飲料 |
| 4902102072670 | 午後の紅茶 | 飲料 |
| 4901005200074 | どん兵衛 | 食品 |
| 4901551354313 | カルピスウォーター | 飲料 |
| 4901777018871 | ファンタオレンジ | 飲料 |

## 📈 開発ロードマップ

プロジェクトの詳細な開発計画とスケジュールについては以下をご確認ください：

- **[📋 開発ロードマップ](https://yourusername.github.io/GCP-Hackathon-F06/roadmap.html)** - 6週間の開発計画とチーム体制
- **[📋 詳細要件定義](docs/development-roadmap.md)** - マークダウン版の詳細資料

### 開発フェーズ
- **Phase 1 (Week 1-2)**: 基盤構築 - 環境構築・コア機能実装
- **Phase 2 (Week 3-4)**: AI機能統合 - キャラクター生成・レシピ提案
- **Phase 3 (Week 5-6)**: 最適化・リリース準備

## 📊 パフォーマンス

- **初回読み込み**: < 3秒
- **バーコードスキャン**: リアルタイム
- **OCR処理**: < 2秒
- **API応答時間**: < 1秒

## 🔒 セキュリティ

- Firebase Authentication による認証
- Firestore Security Rules によるアクセス制御
- HTTPS通信の強制
- 環境変数による機密情報管理
- XSS/CSRF対策実装

詳細は[セキュリティガイド](README_SECURITY.md)を参照

## 📈 今後の開発計画

- [ ] オフラインモード対応
- [ ] PWA化
- [ ] 栄養分析機能
- [ ] 買い物リスト連携
- [ ] レシート読み取り機能
- [ ] 食品ロス統計ダッシュボード
- [ ] 多言語対応（英語、中国語）
- [ ] ダークモード

## 🤝 コントリビューション

プルリクエストを歓迎します！大きな変更の場合は、まずissueを開いて変更内容について議論してください。

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

## 📄 ライセンス

このプロジェクトはMITライセンスの下で公開されています。詳細は[LICENSE](LICENSE)ファイルを参照してください。

## 👥 チーム

**F06 Team** - GCP Hackathon 2024

- 開発リード
- UI/UXデザイナー
- バックエンドエンジニア

## 📞 サポート

- **バグ報告**: [GitHub Issues](https://github.com/yourusername/GCP-Hackathon-F06/issues)
- **ドキュメント**: [Wiki](https://github.com/yourusername/GCP-Hackathon-F06/wiki)
- **メール**: support@example.com

## 🙏 謝辞

- Google Cloud Platform
- Firebase Team
- Flutter Community
- Open Food Facts

---

<p align="center">
  Made with ❤️ by F06 Team
</p>


