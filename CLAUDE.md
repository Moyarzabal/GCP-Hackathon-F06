# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a **Flutter iOS/Android native application** for refrigerator management with barcode scanning and AI features. The app is primarily targeted for **iOS App Store** and Google Play Store distribution, focusing on food waste reduction through gamified expiry date tracking with character-based visualization.

**Primary Platform**: iOS (App Store)
**Secondary Platform**: Android (Google Play)
**Web Support**: Deprecated (maintenance only)

### Key Features
- 📸 **Barcode Scanning**: ML Kit barcode scanner for product registration
- 🤖 **AI OCR**: Automatic expiry date reading with ML Kit text recognition
- 🎨 **3D Fridge Visualization**: Interactive 3D refrigerator UI with layered sections
- 🍳 **AI Meal Planning**: Gemini-powered recipe suggestions based on expiring items
- 👨‍👩‍👧‍👦 **Household Management**: Multi-user family sharing functionality
- 📊 **Product Management**: Complete CRUD operations with Firestore backend
- 🛒 **Shopping List**: Smart shopping list generation based on consumption patterns

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

### Current Project Architecture
```
lib/
├── app.dart                    # Main application with adaptive navigation
├── main.dart                   # Entry point with Firebase initialization
├── core/                       # Foundation layer
│   ├── constants/             # App colors, themes, constants
│   ├── config/                # Firebase configuration
│   ├── errors/                # Error handling & global exception management
│   ├── platform/              # Platform detection utilities
│   ├── security/              # API key management & secure storage
│   ├── services/              # Core service integrations
│   │   ├── firestore_service.dart
│   │   ├── auth_service.dart
│   │   ├── gemini_service.dart
│   │   ├── ocr_service.dart
│   │   ├── imagen_service.dart
│   │   └── multi_agent_meal_planning_service.dart
│   └── utils/                 # Logging & helper utilities
├── features/                   # Feature modules (vertical slices)
│   ├── auth/                  # Firebase authentication
│   ├── home/                  # Home screen with 3D fridge view
│   ├── fridge/                # 3D refrigerator visualization
│   │   ├── providers/         # Fridge state management
│   │   └── widgets/           # 3D fridge components
│   │       ├── layered_3d_fridge_widget.dart
│   │       ├── tesla_style_fridge_widget.dart
│   │       ├── realistic_fridge_widget.dart
│   │       └── futuristic_3d_fridge_widget.dart
│   ├── scanner/               # ML Kit barcode scanner
│   ├── products/              # Product CRUD operations
│   ├── meal_planning/         # AI-powered meal planning
│   │   ├── providers/         # Meal plan state management
│   │   └── widgets/           # Meal plan UI components
│   ├── household/             # Family sharing functionality
│   ├── history/               # Scan & usage history
│   └── settings/              # App configuration
├── shared/                     # Cross-feature shared code
│   ├── models/                # Domain models
│   │   ├── product.dart
│   │   ├── meal_plan.dart
│   │   ├── shopping_item.dart
│   │   └── category.dart
│   ├── providers/             # Global state management (Riverpod)
│   ├── widgets/               # Reusable UI components
│   │   ├── adaptive/         # Platform-adaptive widgets
│   │   └── common/           # Common widgets
│   └── utils/                 # Helper functions
├── routes/                     # App routing configuration
└── simple/                     # Legacy/simple UI components
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

### ✅ Implemented Features
- **Authentication**: Firebase Auth with Google/Apple/Email login
- **Database**: Cloud Firestore for product & user data persistence
- **Barcode Scanning**: ML Kit barcode scanning with mobile_scanner
- **OCR**: ML Kit text recognition for expiry date extraction
- **Product Database**: Open Food Facts API integration
- **AI Services**: Google Gemini API for recipe & meal planning
- **3D Visualization**: Multiple 3D fridge UI styles (Tesla, Realistic, Futuristic)
- **Meal Planning**: AI-powered meal suggestions with shopping lists
- **Family Sharing**: Household management with multi-user support
- **Product Management**: Complete CRUD with expiry tracking
- **History Tracking**: Scan history and product usage analytics
- **Error Handling**: Global error management with secure logging
- **Security**: Secure API key management with encrypted storage

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

## Dependencies (Current Implementation)

Key packages from `pubspec.yaml`:
```yaml
dependencies:
  # Core Framework
  flutter:
    sdk: flutter
  cupertino_icons: ^1.0.8
  material_design_icons_flutter: ^7.0.7296

  # Firebase Stack
  firebase_core: ^3.15.2
  firebase_auth: ^5.3.3
  cloud_firestore: ^5.5.1
  firebase_storage: ^12.3.7

  # State Management
  flutter_riverpod: ^2.6.1

  # Camera & ML Kit
  mobile_scanner: ^7.0.1

  # HTTP & API Integration
  http: ^1.2.2
  dio: ^5.4.0

  # Google AI Services
  google_generative_ai: ^0.4.0

  # Utilities
  intl: ^0.19.0
  uuid: ^4.5.1
  path_provider: ^2.1.5
  shared_preferences: ^2.3.3
  url_launcher: ^6.3.1
  flutter_dotenv: ^5.1.0
  equatable: ^2.0.5

  # Platform & Device Info
  universal_platform: ^1.1.0
  device_info_plus: ^10.1.2

  # Local Database
  sqflite: ^2.4.0

  # Security & Permissions
  permission_handler: ^11.3.1
  flutter_secure_storage: ^9.2.2
  crypto: ^3.0.5

  # UI Components
  table_calendar: ^3.1.3

  # Logging
  logging: ^1.2.0

dev_dependencies:
  flutter_test:
    sdk: flutter
  flutter_lints: ^5.0.0

  # Testing
  mockito: ^5.4.4
  build_runner: ^2.4.9
  fake_cloud_firestore: ^3.0.3
  firebase_auth_mocks: ^0.14.1

  # Integration Testing
  integration_test:
    sdk: flutter
  flutter_driver:
    sdk: flutter
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

## Specialized Development Areas

### 🎨 3D Fridge Visualization
The app features multiple 3D refrigerator visualization styles:
- **Tesla Style**: Modern, minimalist 3D fridge with clean lines
- **Realistic Style**: Photorealistic refrigerator rendering
- **Futuristic Style**: Sci-fi inspired 3D visualization
- **Layered 3D**: Interactive layered fridge with door/shelf animations

### 🤖 AI Integration
- **Gemini API**: Recipe generation and meal planning
- **Multi-Agent System**: Enhanced meal planning with specialized AI agents
- **OCR Service**: ML Kit text recognition for expiry dates
- **Image Generation**: Product visualization and character creation

### 🏗 Architecture Patterns
- **Clean Architecture**: Separation of concerns with clear layer boundaries
- **Riverpod State Management**: Reactive state management across features
- **Repository Pattern**: Data abstraction with Firebase integration
- **Service Locator**: Dependency injection for core services
- **Error Handling**: Global error management with user-friendly messaging

### 📱 Mobile-Specific Features
- **Adaptive UI**: Platform-aware navigation and styling
- **Camera Integration**: Native camera access for barcode scanning
- **Secure Storage**: Encrypted API key and sensitive data storage
- **Offline Support**: Local database with sync capabilities
- **Performance Optimization**: 60fps animations and efficient rendering

## Testing & Development

### Test Barcode Values
Supported JANs for testing:
- 4901777018888: コカ・コーラ 500ml
- 4902220770199: ポカリスエット 500ml
- 4901005202078: カップヌードル
- 4901301231123: ヤクルト
- 4902102072670: 午後の紅茶
- 4901005200074: どん兵衛
- 4901551354313: カルピスウォーター
- 4901777018871: ファンタオレンジ

### Test Coverage
- **Unit Tests**: Core services and business logic
- **Widget Tests**: UI component functionality
- **Integration Tests**: End-to-end user flows
- **Mock Testing**: Firebase services and external APIs

### Development Commands
```bash
# Run all tests
flutter test

# Run integration tests
flutter test integration_test

# Generate mocks
flutter packages pub run build_runner build

# Check for linting issues
flutter analyze

# Format code
flutter format .
```

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