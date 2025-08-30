# バーコードスキャナー MVP デプロイ手順

## 🚀 概要
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

## 📝 Firebase Hostingへのデプロイ手順

### 1. Firebaseにログイン
```bash
firebase login
```

### 2. Firebaseプロジェクトを作成（まだの場合）
1. [Firebase Console](https://console.firebase.google.com/)にアクセス
2. 新しいプロジェクトを作成
3. プロジェクトIDをメモ

### 3. .firebaserc ファイルを更新
```bash
cd /Users/fukku_maple/Documents/GCP-Hackathon-F06
```

`.firebaserc`ファイルの`your-firebase-project-id`を実際のプロジェクトIDに置き換え：
```json
{
  "projects": {
    "default": "実際のプロジェクトID"
  }
}
```

### 4. デプロイ実行
```bash
# プロジェクトディレクトリから
firebase deploy --only hosting
```

### 5. デプロイ完了
デプロイが成功すると、以下のようなURLが表示されます：
```
https://[your-project-id].web.app
```

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