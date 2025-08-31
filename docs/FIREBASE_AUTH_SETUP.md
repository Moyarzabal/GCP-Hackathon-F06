# Firebase Authentication セットアップ手順

## 🔐 Firebase Consoleでの設定

### 1. Firebase Consoleにアクセス
```
https://console.firebase.google.com/project/gcp-f06-barcode/authentication
```

### 2. Authentication を有効化
1. 左メニューから「Authentication」をクリック
2. 「始める」ボタンをクリック

### 3. Sign-in providers を設定

#### Email/Password 認証
1. 「Sign-in method」タブをクリック
2. 「メール/パスワード」をクリック
3. 「有効にする」をトグルON
4. 「保存」をクリック

#### Google 認証
1. 「Google」をクリック
2. 「有効にする」をトグルON
3. プロジェクトのサポートメールを入力
4. 「保存」をクリック

#### Apple 認証（オプション）
1. 「Apple」をクリック
2. 「有効にする」をトグルON
3. Service ID、Team ID、Key ID、Private Keyを設定
4. 「保存」をクリック

### 4. Authorized domains を確認
1. 「Settings」タブをクリック
2. 「Authorized domains」セクションで以下が含まれていることを確認：
   - `localhost`
   - `gcp-f06-barcode.firebaseapp.com`
   - `gcp-f06-barcode.web.app`

## 📱 iOSアプリの追加設定

### Google Sign-In用の設定（既に完了済み）
- ✅ GoogleService-Info.plist が ios/Runner/ に配置済み
- ✅ Info.plist に CFBundleURLTypes 設定済み
- ✅ OAuth 2.0 Client ID 設定済み

### Bundle IDの確認
現在のBundle ID: `com.hackathon.f06.barcodeScanner`

## 🔍 トラブルシューティング

### エラー: "CONFIGURATION_NOT_FOUND"
→ Firebase Authenticationが無効になっている

### エラー: "Google sign in failed"
→ OAuth 2.0 Client IDが正しく設定されていない

### エラー: "Network error"
→ ネットワーク接続を確認

## 📝 確認事項

- [ ] Firebase Console で Authentication が有効になっている
- [ ] Email/Password provider が有効
- [ ] Google provider が有効
- [ ] Authorized domains が設定されている
- [ ] iOS Bundle ID が一致している

## 🚀 設定完了後

1. アプリを再起動
2. ログイン画面でメールアドレスとパスワードで新規登録を試す
3. Googleでログインを試す

問題が解決しない場合は、Xcodeのコンソールログを確認してください。