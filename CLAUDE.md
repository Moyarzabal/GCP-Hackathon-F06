# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter iOS/Android native application** (with Web support) for refrigerator management with barcode scanning and AI features. The app is primarily targeted for **iOS App Store** and Google Play Store distribution, focusing on food waste reduction through gamified expiry date tracking.

**Primary Platform**: iOS (App Store)  
**Secondary Platform**: Android (Google Play)  
**Tertiary Platform**: Web (Firebase Hosting)

## Common Development Commands

### iOS Development (Primary Focus)
```bash
# Add iOS support if not exists
flutter create --platforms=ios .

# Run on iOS Simulator
flutter run -d iphone

# Run on physical iOS device
flutter run -d <device_id>

# Build iOS app for release
flutter build ios --release

# Build IPA for App Store
flutter build ipa

# Open in Xcode
open ios/Runner.xcworkspace

# Fix iOS issues
cd ios && pod install && cd ..
```

### Android Development
```bash
# Add Android support if not exists
flutter create --platforms=android .

# Run on Android emulator
flutter run -d android

# Build APK
flutter build apk --release

# Build App Bundle for Play Store
flutter build appbundle --release
```

### Web Development (Existing)
```bash
# Run in development mode (web)
flutter run -d chrome

# Build for production
flutter build web

# Deploy to Firebase Hosting
firebase deploy --only hosting
```

### Cross-Platform Testing
```bash
# List all available devices
flutter devices

# Run on all available devices
flutter run -d all

# Run tests
flutter test

# Integration tests
flutter test integration_test
```

## iOS-Specific Configuration

### Required iOS Permissions (Info.plist)
```xml
<key>NSCameraUsageDescription</key>
<string>バーコードスキャンと賞味期限の撮影のためカメラを使用します</string>

<key>NSPhotoLibraryUsageDescription</key>
<string>商品画像の保存と読み込みのため写真ライブラリを使用します</string>

<key>NSFaceIDUsageDescription</key>
<string>セキュアなログインのためFace IDを使用します</string>

<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
```

### iOS Build Settings
- **Minimum iOS Version**: 12.0
- **Swift Version**: 5.0
- **Bundle Identifier**: com.f06team.fridgemanager
- **Team ID**: (Set in Xcode with Apple Developer account)

## Android-Specific Configuration

### Required Android Permissions (AndroidManifest.xml)
```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.VIBRATE" />
<uses-permission android:name="android.permission.USE_BIOMETRIC" />
```

### Android Build Settings
- **Minimum SDK**: 21 (Android 5.0)
- **Target SDK**: 34 (Android 14)
- **Package Name**: com.f06team.fridgemanager

## Architecture & Code Structure

### Platform-Aware Architecture
```
lib/
├── app.dart                    # Main application widget & navigation
├── main.dart                   # Entry point with platform detection
├── core/                       # Foundation layer
│   ├── constants/             # App-wide constants (colors, themes)
│   ├── config/                # Firebase & platform-specific configs
│   ├── services/              # Service integrations
│   └── platform/              # Platform-specific implementations
│       ├── ios/              # iOS-specific code
│       ├── android/          # Android-specific code
│       └── web/              # Web-specific code
├── features/                   # Feature modules (vertical slices)
│   ├── auth/                  # Authentication (biometric for mobile)
│   ├── home/                  # Home screen with product list
│   ├── scanner/               # Barcode scanning (optimized for mobile)
│   ├── products/              # Product management
│   ├── household/             # Family sharing
│   ├── history/               # Scan history
│   └── settings/              # App settings (platform-specific)
└── shared/                     # Cross-feature shared code
    ├── models/                # Domain models
    ├── widgets/               # Reusable UI components
    │   ├── adaptive/         # Platform-adaptive widgets
    │   └── common/           # Common widgets
    ├── utils/                 # Helper functions
    └── providers/             # State management (Riverpod)
```

### Key Platform Differences

| Feature | iOS | Android | Web |
|---------|-----|---------|-----|
| **UI Style** | Cupertino (iOS-like) | Material Design | Material Design |
| **Navigation** | iOS tab bar | Bottom navigation | Bottom navigation |
| **Camera** | Native (fast) | Native (fast) | WebRTC (slower) |
| **Storage** | Core Data/SQLite | SQLite | IndexedDB |
| **Auth** | Face ID/Touch ID | Fingerprint | Email/Social |
| **Notifications** | APNS | FCM | Web Push |

## Current Features & Implementation Status

### ✅ Implemented (All Platforms)
- Firebase Authentication (Google/Apple/Email)
- Cloud Firestore data persistence
- ML Kit barcode scanning
- Open Food Facts API integration
- Gemini API for recipe suggestions
- Family sharing functionality

### 🚧 iOS-Specific Features (Priority)
- [ ] Face ID/Touch ID authentication
- [ ] iOS Widget for expiry dates
- [ ] Apple Watch companion app
- [ ] Siri Shortcuts integration
- [ ] iOS-style UI with Cupertino widgets
- [ ] Background fetch for notifications

### 🚧 Android-Specific Features
- [ ] Material You dynamic theming
- [ ] Android widgets
- [ ] Google Assistant integration
- [ ] Wear OS support

## Firebase Configuration (Multi-Platform)

```dart
// lib/core/config/firebase_config.dart
class FirebaseConfig {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return webOptions;
    } else if (Platform.isIOS) {
      return iosOptions;
    } else if (Platform.isAndroid) {
      return androidOptions;
    }
    throw UnsupportedError('Unsupported platform');
  }
  
  static const FirebaseOptions iosOptions = FirebaseOptions(
    apiKey: 'ios-api-key',
    appId: 'ios-app-id',
    messagingSenderId: 'sender-id',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.appspot.com',
    iosBundleId: 'com.f06team.fridgemanager',
  );
  
  static const FirebaseOptions androidOptions = FirebaseOptions(
    apiKey: 'android-api-key',
    appId: 'android-app-id',
    messagingSenderId: 'sender-id',
    projectId: 'gcp-f06-barcode',
    storageBucket: 'gcp-f06-barcode.appspot.com',
  );
}
```

## Dependencies (Updated for Mobile)

Key packages from `pubspec.yaml`:
```yaml
dependencies:
  # Core
  flutter:
    sdk: flutter
  
  # Platform Detection
  universal_platform: ^1.1.0
  
  # Firebase (all platforms)
  firebase_core: ^3.15.2
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.1
  firebase_storage: ^12.3.7
  firebase_messaging: ^15.1.5
  
  # State Management
  flutter_riverpod: ^2.6.1
  
  # Camera & ML (optimized for mobile)
  mobile_scanner: ^7.0.1
  google_mlkit_text_recognition: ^0.15.0
  google_mlkit_barcode_scanning: ^0.14.0
  
  # iOS Specific
  cupertino_icons: ^1.0.8
  
  # Biometric Auth
  local_auth: ^2.3.0
  
  # Local Storage
  sqflite: ^2.4.2
  path_provider: ^2.1.5
  
  # Permissions
  permission_handler: ^11.3.1
  
  # Platform UI
  flutter_platform_widgets: ^7.0.1
```

## Development Methodology (Mobile-First)

### Mobile-First Development
1. **Design for mobile first** (iOS priority)
2. **Test on real devices** regularly
3. **Optimize for performance** (60fps animations)
4. **Handle offline scenarios**
5. **Implement platform-specific UI**

### Testing Strategy
```bash
# iOS Testing
flutter test --platform=ios

# Android Testing  
flutter test --platform=android

# Integration Testing on Device
flutter drive --target=test_driver/app.dart

# Widget Testing
flutter test test/widgets/

# Golden Testing (UI screenshots)
flutter test --update-goldens
```

### App Store Deployment Checklist
- [ ] App icons (all sizes)
- [ ] Launch screens
- [ ] Screenshots (iPhone & iPad)
- [ ] App Store description (日本語/English)
- [ ] Privacy policy URL
- [ ] Terms of service
- [ ] TestFlight beta testing
- [ ] App Store review guidelines compliance

### Google Play Deployment Checklist
- [ ] App icons
- [ ] Feature graphic
- [ ] Screenshots (phone & tablet)
- [ ] Play Store listing (日本語/English)
- [ ] Content rating questionnaire
- [ ] Target audience declaration
- [ ] Data safety form
- [ ] Internal testing track

## Available Subagents (Updated for Mobile)

### 🤖 Configured Subagents

1. **ios-app-developer** - iOS開発専門家
   - Swift/Objective-C bridge実装
   - iOS固有機能の実装
   - App Store最適化
   - TestFlight配信管理

2. **android-app-developer** - Android開発専門家
   - Kotlin/Java実装
   - Material Design 3対応
   - Google Play最適化
   - Play Console管理

3. **flutter-mobile-optimizer** - モバイル最適化
   - パフォーマンスチューニング
   - バッテリー消費最適化
   - オフライン対応実装
   - プラットフォーム別UI実装

4. **app-store-publisher** - ストア公開支援
   - ASO (App Store Optimization)
   - スクリーンショット生成
   - メタデータ管理
   - 審査対策アドバイス

5. **mobile-test-engineer** - モバイルテスト
   - デバイステスト自動化
   - UI/UXテスト
   - パフォーマンステスト
   - クラッシュ分析

6. **firebase-mobile-specialist** - Firebase Mobile SDK
   - Crashlytics設定
   - Performance Monitoring
   - Remote Config
   - A/Bテスト設定

## Testing Barcode Values

Supported JANs for testing (works on all platforms):
- 4901777018888: コカ・コーラ 500ml
- 4902220770199: ポカリスエット 500ml
- 4901005202078: カップヌードル
- 4901301231123: ヤクルト
- 4902102072670: 午後の紅茶
- 4901005200074: どん兵衛
- 4901551354313: カルピスウォーター
- 4901777018871: ファンタオレンジ

## Platform-Specific Features Priority

### iOS (Highest Priority)
1. Face ID/Touch ID ログイン
2. ウィジェット（ホーム画面に賞味期限表示）
3. Siriショートカット（「賞味期限チェック」）
4. Apple Watchアプリ
5. iCloudバックアップ

### Android (Secondary)
1. 指紋認証ログイン
2. ウィジェット対応
3. Googleアシスタント連携
4. Wear OS対応
5. Google Drive バックアップ

### Web (Maintenance Only)
- 既存機能の保守
- バグ修正のみ
- 新機能はモバイル優先