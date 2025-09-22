# 📱 iOS/Androidアプリ化ガイド

## 🎯 概要

現在のFlutter Webアプリを**ネイティブiOS/Androidアプリ**として公開できます！
同じコードベースから各プラットフォーム向けのアプリを生成可能です。

## ✅ メリット（PWA vs ネイティブアプリ）

| 機能 | PWA | ネイティブアプリ |
|------|-----|-----------------|
| **App Store配信** | ❌ | ✅ |
| **プッシュ通知** | △ (制限あり) | ✅ (完全対応) |
| **カメラアクセス** | △ (ブラウザ依存) | ✅ (高速・安定) |
| **オフライン機能** | △ | ✅ |
| **端末ストレージ** | △ (制限あり) | ✅ (無制限) |
| **バックグラウンド処理** | ❌ | ✅ |
| **生体認証** | ❌ | ✅ (Face ID/Touch ID) |
| **ウィジェット** | ❌ | ✅ |
| **パフォーマンス** | 良好 | 最高 |

---

## 🍎 iOS アプリ化手順

### 前提条件

- **Mac** (必須)
- **Xcode 14以上**
- **Apple Developer Program** ($99/年)
- **iOS実機** (テスト用)

### 1. iOS プロジェクトの生成

```bash
# iOSサポートを追加（既存プロジェクトの場合）
flutter create --platforms=ios .

# または最初から
flutter create --platforms=ios,android,web barcode_scanner
```

### 2. iOS固有の設定

#### Info.plist の編集
`ios/Runner/Info.plist`に権限を追加：

```xml
<key>NSCameraUsageDescription</key>
<string>バーコードスキャンのためカメラを使用します</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>商品画像の保存のため写真ライブラリを使用します</string>

<key>NSLocationWhenInUseUsageDescription</key>
<string>近くの店舗情報を表示するため位置情報を使用します</string>

<!-- Face ID使用時 -->
<key>NSFaceIDUsageDescription</key>
<string>セキュアなログインのためFace IDを使用します</string>
```

### 3. Firebase iOS設定

```bash
# 1. Firebase ConsoleでiOSアプリを追加
# 2. GoogleService-Info.plistをダウンロード
# 3. ios/Runner/に配置

# Podfileを更新
cd ios
pod install
```

### 4. iOS向けコード調整

`lib/main.dart`を更新：

```dart
import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // プラットフォーム別初期化
  if (!kIsWeb) {
    if (Platform.isIOS) {
      // iOS固有の初期化
      await _setupiOS();
    } else if (Platform.isAndroid) {
      // Android固有の初期化
      await _setupAndroid();
    }
  }
  
  await FirebaseConfig.initialize();
  runApp(MyApp());
}

Future<void> _setupiOS() async {
  // iOS固有の設定
  // 例: Apple Sign In, プッシュ通知権限など
}
```

### 5. ビルドと実行

```bash
# iOS シミュレーターで実行
flutter run -d iphone

# 実機で実行（要Developer証明書）
flutter run -d <device_id>

# リリースビルド
flutter build ios --release
```

### 6. App Store Connect設定

1. **App Store Connect**にアプリを作成
2. **Bundle ID**を設定（例: com.f06team.fridgemanager）
3. **アプリ情報**を入力
4. **スクリーンショット**を準備（各画面サイズ）
5. **プライバシーポリシー**を作成

### 7. アップロード

```bash
# アーカイブ作成
flutter build ios --release

# Xcodeを開く
open ios/Runner.xcworkspace

# Xcode内で:
# 1. Product → Archive
# 2. Distribute App
# 3. App Store Connect → Upload
```

---

## 🤖 Android アプリ化手順

### 前提条件

- **Android Studio**
- **Google Play Developer Account** ($25 一回のみ)

### 1. Android設定

#### AndroidManifest.xml
`android/app/src/main/AndroidManifest.xml`：

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />

<application
    android:label="冷蔵庫管理AI"
    android:icon="@mipmap/ic_launcher">
    
    <!-- カメラ機能 -->
    <uses-feature
        android:name="android.hardware.camera"
        android:required="true" />
</application>
```

### 2. 署名設定

`android/app/build.gradle`：

```gradle
android {
    defaultConfig {
        applicationId "com.f06team.fridgemanager"
        minSdkVersion 21
        targetSdkVersion 33
        versionCode 1
        versionName "1.0.0"
    }
    
    signingConfigs {
        release {
            keyAlias 'your-key-alias'
            keyPassword 'your-key-password'
            storeFile file('your-keystore.jks')
            storePassword 'your-store-password'
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
            minifyEnabled true
            proguardFiles getDefaultProguardFile('proguard-android.txt'), 'proguard-rules.pro'
        }
    }
}
```

### 3. ビルド

```bash
# APKビルド
flutter build apk --release

# App Bundle（推奨）
flutter build appbundle --release
```

---

## 📦 必要な変更点

### 1. パッケージの調整

`pubspec.yaml`を更新：

```yaml
dependencies:
  # 既存のパッケージに加えて
  
  # iOS/Android対応版
  permission_handler: ^11.0.0  # 権限管理
  local_auth: ^2.1.0           # 生体認証
  flutter_local_notifications: ^17.0.0  # ローカル通知
  path_provider: ^2.1.0        # ファイルパス
  sqflite: ^2.3.0              # ローカルDB
  connectivity_plus: ^5.0.0    # ネットワーク状態
  device_info_plus: ^10.0.0    # デバイス情報
```

### 2. プラットフォーム別UI調整

```dart
import 'package:flutter/cupertino.dart';

Widget build(BuildContext context) {
  if (Platform.isIOS) {
    // iOS風UI (Cupertino)
    return CupertinoPageScaffold(
      navigationBar: CupertinoNavigationBar(
        middle: Text('冷蔵庫管理'),
      ),
      child: content,
    );
  } else {
    // Android風UI (Material)
    return Scaffold(
      appBar: AppBar(
        title: Text('冷蔵庫管理'),
      ),
      body: content,
    );
  }
}
```

### 3. カメラ最適化

Web版の`mobile_scanner`をネイティブ版に最適化：

```dart
// ネイティブアプリでの高速スキャン
MobileScanner(
  controller: MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.ean13, BarcodeFormat.ean8],
    // iOS/Android専用オプション
    detectionTimeoutMs: Platform.isIOS ? 300 : 500,
  ),
);
```

---

## 🚀 推奨リリース戦略

### フェーズ1: テスト配信（1-2週間）
- **iOS**: TestFlight でベータテスト
- **Android**: Google Play Console 内部テスト

### フェーズ2: 限定公開（2-4週間）
- **iOS**: TestFlight 外部テスト（最大10,000人）
- **Android**: クローズドベータ

### フェーズ3: 正式リリース
- **iOS**: App Store公開
- **Android**: Google Play公開

---

## 💰 コスト

| 項目 | iOS | Android |
|------|-----|---------|
| **開発者登録** | $99/年 | $25（一回のみ） |
| **審査期間** | 1-7日 | 2-3時間 |
| **手数料** | 売上の15-30% | 売上の15-30% |
| **最小OS** | iOS 12.0+ | Android 5.0+ |

---

## 📊 アプリストア最適化（ASO）

### アプリ名
- **メイン**: 冷蔵庫管理AI
- **サブ**: バーコードで簡単食材管理

### キーワード
```
冷蔵庫管理, バーコードスキャン, 賞味期限, 
食材管理, フードロス, レシピ提案, 家族共有, 
AI, OCR, 在庫管理
```

### カテゴリ
- **iOS**: ライフスタイル / フード＆ドリンク
- **Android**: ライフスタイル / ツール

### スクリーンショット構成
1. **ホーム画面**: キャラクター表示
2. **バーコードスキャン**: 実際のスキャン画面
3. **賞味期限管理**: カレンダービュー
4. **レシピ提案**: AI提案画面
5. **家族共有**: 世帯管理画面

---

## 🔧 トラブルシューティング

### iOS ビルドエラー

```bash
# Podfile.lockを削除して再インストール
cd ios
rm Podfile.lock
pod install --repo-update
```

### Android ビルドエラー

```bash
# クリーンビルド
flutter clean
flutter pub get
cd android
./gradlew clean
cd ..
flutter build apk
```

---

## 📝 App Store審査対策

### 必須項目
- ✅ プライバシーポリシー（URL必須）
- ✅ 利用規約
- ✅ お問い合わせ先
- ✅ デモアカウント（審査用）

### 審査でリジェクトされやすい点
- カメラ権限の説明が不十分
- クラッシュやバグ
- コンテンツが不十分
- 外部リンクの決済誘導

### 対策
```dart
// 権限リクエスト前に説明を表示
Future<bool> requestCameraPermission() async {
  if (Platform.isIOS) {
    // 説明ダイアログを表示
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text('カメラへのアクセス'),
        content: Text('バーコードをスキャンするためカメラへのアクセスが必要です'),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              await Permission.camera.request();
            },
            child: Text('許可'),
          ),
        ],
      ),
    );
  }
}
```

---

## 🎯 次のステップ

1. **Macを準備**（iOS開発に必須）
2. **Apple Developer Program登録**
3. **プロジェクトをiOS/Android対応に変換**
4. **TestFlightでベータテスト**
5. **App Store/Google Play申請**

---

## 📞 サポート

iOSアプリ化で困ったら：
- [Flutter iOS公式ドキュメント](https://docs.flutter.dev/deployment/ios)
- [App Store審査ガイドライン](https://developer.apple.com/app-store/review/guidelines/)
- [Google Play公開ガイド](https://support.google.com/googleplay/android-developer/answer/9859348)