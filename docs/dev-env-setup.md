## 開発環境セットアップガイド（Flutter + Firebase Emulator + Cloud Run/Docker）

このドキュメントは、日々の開発をローカルで高速に回しつつ、本番はサーバーレス（Cloud Functions/Cloud Run）で運用するための標準セットアップをまとめたものです。macOS Sonoma を前提に記述しています。

### 前提とゴール
- **ゴール**: Flutter アプリを Firebase Emulator Suite とローカル Docker(API)で動かし、デプロイ先は Cloud Functions/Cloud Run を前提に整備
- **対象**: モバイル開発者/バックエンド開発者/CI 管理者

### 必要ツールのインストール
1) Homebrew（未導入の場合）
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```

2) FVM（Flutter バージョン固定）
```bash
brew install fvm
fvm install 3.22.0
fvm use 3.22.0
```

3) Firebase CLI / FlutterFire CLI
```bash
brew install firebase-cli
dart pub global activate flutterfire_cli
```

4) Google Cloud SDK / Docker / Node.js 20
```bash
brew install --cask google-cloud-sdk
brew install --cask docker
brew install node@20
```

5) GCP 認証（初回のみ）
```bash
gcloud auth login
gcloud config set project <YOUR_GCP_PROJECT_ID>
```

### Flutter プロジェクト初期化（必要に応じて）
既存の Flutter アプリがない場合:
```bash
fvm flutter create app
cd app
```

### Firebase 連携（FlutterFire）
環境（dev/staging/prod）に合わせて Firebase プロジェクトを選択・作成してください。
```bash
flutterfire configure \
  --project=<YOUR_FIREBASE_PROJECT_ID> \
  --platforms=ios,android,web
```

### Firebase Emulator Suite 設定
`firebase.json` と `.firebaserc` をプロジェクト直下に追加します。以下は雛形です。

`firebase.json`:
```json
{
  "emulators": {
    "auth": { "port": 9099 },
    "firestore": { "port": 8080 },
    "storage": { "port": 9199 },
    "functions": { "port": 5001 }
  },
  "firestore": { "rules": "firestore.rules" },
  "storage": { "rules": "storage.rules" }
}
```

`.firebaserc`:
```json
{
  "projects": {
    "default": "<YOUR_FIREBASE_PROJECT_ID>"
  }
}
```

`firestore.rules`（最小例・実運用では厳格化してください）:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /{document=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

`storage.rules`（最小例）:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}
```

エミュレータ起動:
```bash
firebase emulators:start
```

Flutter 側でエミュレータを使用するための接続設定（例）:
- Auth: `localhost:9099`
- Firestore: `localhost:8080`
- Storage: `localhost:9199`
- Functions: `localhost:5001`

### Cloud Functions（ローカル / 本番）
初期化（プロジェクト直下で）:
```bash
firebase init functions
```
推奨設定:
- Node.js 20
- TypeScript 有効
- ESLint 有効

ローカル実行はエミュレータがハンドリングします。デプロイは:
```bash
firebase deploy --only functions
```

### Cloud Run 相当 API（Docker ローカル / 本番 Cloud Run）
`api/` ディレクトリを作成し、以下の雛形を配置します。

`api/Dockerfile`（Node.js ランタイム例）:
```dockerfile
FROM node:20-alpine AS build
WORKDIR /app
COPY package*.json ./
RUN npm ci
COPY . .
RUN npm run build

FROM gcr.io/distroless/nodejs20
WORKDIR /app
COPY --from=build /app/dist ./dist
COPY --from=build /app/node_modules ./node_modules
ENV PORT=8080
EXPOSE 8080
CMD ["dist/index.js"]
```

`docker-compose.yml`（ルート直下）:
```yaml
version: "3.9"
services:
  api:
    build: ./api
    ports:
      - "8080:8080"
    environment:
      - NODE_ENV=development
      - GOOGLE_CLOUD_PROJECT=<YOUR_GCP_PROJECT_ID>
    volumes:
      - ./api:/app
```

ローカル起動:
```bash
docker compose up --build
```

Cloud Run デプロイ（例）:
```bash
gcloud builds submit --tag "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/api:latest" ./api
gcloud run deploy f06-api \
  --image "<REGION>-docker.pkg.dev/<PROJECT_ID>/<REPO>/api:latest" \
  --region <REGION> \
  --allow-unauthenticated
```

### CI/CD（GitHub Actions 例）
`.github/workflows/ci.yml`:
```yaml
name: CI
on:
  push:
    branches: [ main, develop ]
  pull_request:
    branches: [ main, develop ]

jobs:
  flutter:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Dependencies
        run: flutter pub get
      - name: Format
        run: flutter format --set-exit-if-changed .
      - name: Analyze
        run: flutter analyze
      - name: Test
        run: flutter test
```

### Secrets 管理
- ローカル: `.env.local`（`.gitignore` に追加）
- CI: GitHub Encrypted Secrets
- 本番: GCP Secret Manager（Cloud Run/Functions にバインド）

### ローカル動作確認
1) Firebase Emulator 起動: `firebase emulators:start`
2) API 起動: `docker compose up --build`
3) Flutter アプリ起動: `fvm flutter run`

### 参考
- 設計: `docs/architecture.md`
- ブランチ戦略/環境対応: `docs/git-branch-strategy.yaml`
- 補助 YAML: `docs/dev-env-setup/current.yaml`, `plan.yaml`, `updated.yaml`


