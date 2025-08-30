# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Flutter Web application for refrigerator management with barcode scanning and AI features. The app is part of the GCP Hackathon F06 project and focuses on food waste reduction through gamified expiry date tracking.

## Common Development Commands

### Build and Run
```bash
# Run in development mode (web)
flutter run -d chrome

# Build for production
flutter build web

# Run tests
flutter test

# Analyze code for issues
flutter analyze

# Format code
dart format lib/
```

### Firebase Deployment
```bash
# Deploy to Firebase Hosting (currently deployed at https://gcp-f06-barcode.web.app)
firebase deploy --only hosting

# Update deployment (after building)
flutter build web && firebase deploy --only hosting
```

### Docker & Cloud Run (Optional)
```bash
# Build Docker image
docker build -t asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest .

# Deploy to Cloud Run
gcloud run deploy barcode-scanner-web \
  --image=asia-northeast1-docker.pkg.dev/gcp-f06-barcode/barcode-scanner/web-app:latest \
  --region=asia-northeast1
```

## Architecture & Code Structure

### Layered Architecture Pattern
The codebase follows a feature-first modular architecture with clear separation of concerns:

```
lib/
├── app.dart                    # Main application widget & navigation
├── main.dart                   # Entry point
├── core/                       # Foundation layer
│   ├── constants/             # App-wide constants (colors, themes)
│   ├── config/                # Firebase & external service configs
│   ├── errors/                # Error handling utilities
│   └── services/              # External service integrations
├── features/                   # Feature modules (vertical slices)
│   ├── home/                  # Home screen with product list
│   ├── scanner/               # Barcode scanning functionality
│   ├── products/              # Product details & search
│   ├── history/               # Scan history tracking
│   └── settings/              # App settings
└── shared/                     # Cross-feature shared code
    ├── models/                # Domain models (Product)
    ├── widgets/               # Reusable UI components
    ├── utils/                 # Helper functions
    └── providers/             # Global state providers
```

### Key Architectural Decisions

1. **Feature-First Organization**: Each feature is self-contained with its own presentation, domain, and data layers, making it easy to add/modify features independently.

2. **Product Model**: Central `Product` class in `shared/models/product.dart` contains business logic for expiry tracking and emotion states (😊→😐→😟→😰→💀).

3. **State Management**: Currently using StatefulWidgets with local state. Ready for Riverpod integration when needed.

4. **Navigation**: Bottom navigation bar with IndexedStack for preserving state between tabs.

## Current Features & Implementation

### Barcode Scanner
- Uses `mobile_scanner` package for camera-based scanning
- Hardcoded product database (8 Japanese products)
- Manual product entry as fallback
- Location: `lib/features/scanner/`

### Product Management
- Expiry date tracking with visual indicators
- Emotion-based status display based on days until expiry
- Category filtering and sorting
- Location: `lib/features/products/` and `lib/shared/models/product.dart`

### Data Flow
1. Scanner captures barcode → looks up in local database
2. User selects expiry date → Product object created
3. Product added to in-memory list (no persistence yet)
4. UI updates across all screens via state management

## Firebase Configuration

- **Project ID**: `gcp-f06-barcode`
- **Hosting URL**: https://gcp-f06-barcode.web.app
- **Region**: asia-northeast1

## Dependencies

Key packages from `pubspec.yaml`:
- `mobile_scanner: ^7.0.1` - Barcode scanning
- `firebase_core: ^4.0.0` - Firebase integration
- `flutter_lints: ^5.0.0` - Linting rules

## Planned Integrations (from requirements)

According to `docs/requirements.html`, future features include:
- Firebase Authentication for multi-user support
- Firestore for data persistence
- ML Kit for OCR (expiry date recognition)
- Vertex AI Imagen for character generation
- Open Food Facts API for product information
- FCM for expiry notifications
- Gemini API for recipe suggestions

## Current Limitations

1. **No Data Persistence**: Products are lost on app restart
2. **Hardcoded Products**: Only 8 Japanese products recognized
3. **No User Authentication**: Single-user mode only
4. **Web-Only Camera**: Mobile platforms need additional setup
5. **No Backend API**: All logic is client-side

## Development Methodology

### Test-Driven Development (TDD) Approach

This project follows TDD principles with an Agile mindset:

1. **Red-Green-Refactor Cycle**
   - Write failing tests first for new features
   - Implement minimal code to pass tests
   - Refactor while keeping tests green

2. **Testing Strategy**
   ```bash
   # Run all tests
   flutter test
   
   # Run specific test file
   flutter test test/features/scanner/scanner_test.dart
   
   # Run with coverage
   flutter test --coverage
   
   # Watch mode for continuous testing
   flutter test --watch
   ```

3. **Test Organization**
   ```
   test/
   ├── features/           # Feature-specific tests
   │   ├── home/
   │   ├── scanner/
   │   └── products/
   ├── shared/            # Shared component tests
   │   └── models/
   └── integration/       # Integration tests
   ```

4. **Writing Tests**
   - Unit tests for business logic (models, services)
   - Widget tests for UI components
   - Integration tests for user flows
   - Mock external dependencies (Firebase, APIs)

### Agile Development Practices

1. **Incremental Development**
   - Start with MVP features
   - Add functionality in small, testable increments
   - Deploy frequently to get user feedback

2. **User Story Format**
   ```
   As a [user type]
   I want to [action]
   So that [benefit]
   ```

3. **Sprint Planning**
   - 2-week sprints
   - Focus on one major feature per sprint
   - Always maintain a deployable state

4. **Code Review Checklist**
   - [ ] Tests written and passing
   - [ ] Code follows project structure
   - [ ] No hardcoded values (except test data)
   - [ ] Error handling implemented
   - [ ] Documentation updated

## Available Subagents

This project includes specialized Claude Code Subagents for efficient development. They are automatically invoked based on context or can be called explicitly.

### 🤖 Configured Subagents

1. **flutter-tdd-developer** - TDD専門家
   - テストファースト開発を徹底
   - Red-Green-Refactorサイクルの実施
   - カバレッジ80%以上を維持

2. **firebase-integrator** - Firebase/GCP統合
   - Firestore, Authentication, Cloud Functions設定
   - セキュリティルールの実装
   - Cloud Run, Vertex AI連携

3. **barcode-product-specialist** - バーコード機能
   - ML Kit統合とOCR実装
   - 商品データベース管理
   - Open Food Facts API連携

4. **ui-character-designer** - UI/UXデザイン
   - Material Design 3準拠
   - キャラクター感情システム
   - レスポンシブデザイン実装

5. **test-automation-runner** - テスト自動化
   - コード変更時の自動テスト実行
   - カバレッジレポート生成
   - CI/CD統合

6. **deployment-orchestrator** - デプロイメント
   - Firebase Hosting自動デプロイ
   - Cloud Runコンテナ管理
   - GitHub Actions CI/CD設定

## Testing Barcode Values

Supported JANs for testing:
- 4901777018888: コカ・コーラ 500ml
- 4902220770199: ポカリスエット 500ml
- 4901005202078: カップヌードル
- 4901301231123: ヤクルト
- 4902102072670: 午後の紅茶
- 4901005200074: どん兵衛
- 4901551354313: カルピスウォーター
- 4901777018871: ファンタオレンジ