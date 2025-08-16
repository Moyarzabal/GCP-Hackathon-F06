## Git ブランチ戦略（3 人チーム）

このドキュメントは、本プロジェクトにおける Git 運用ルール（Git Flow 準拠）を、わかりやすく Markdown でまとめたものです。対象リポジトリは `GCP-Hackathon-F06`、チーム規模は 3 名を想定しています。

### 戦略概要

- **方式**: Git Flow
- **目的**: 並行開発の衝突を最小化し、安全なリリースと品質担保を実現

### メインブランチ

- **main**（本番用）

  - 常にデプロイ可能
  - 直接 push 禁止 / PR レビュー必須（最少 1 名）

- **develop**（開発統合）
  - 機能統合・テスト用
  - `feature/*` からのマージを受け付け、安定後に `main` へ昇格

### 作業ブランチ

- **feature/**

  - 目的: 各機能開発
  - 命名: `feature/{機能名}`（例: `feature/barcode-scanner`, `feature/ui-components`）
  - ベース: `develop`
  - マージ先: `develop`

- **hotfix/**
  - 目的: 本番緊急修正
  - 命名: `hotfix/{修正内容}`（例: `hotfix/critical-auth-bug`）
  - ベース: `main`
  - マージ先: `main` および `develop`

### 役割（ドラフト）

- `shun`: TBD
- `fukku`: TBD
- `rena`: TBD

候補ロール例:

- フロントエンド（Flutter/Rive/UI）: ブランチ接頭辞 `feature/ui-`
- AI/バックエンド（Vertex AI/Functions）: `feature/ai-`
- スキャン・データ管理（ML Kit/Firestore 設計）: `feature/data-`

### ワークフロー

- 機能開発（Feature）

  1. `develop` から `feature/xxx` を作成
  2. 実装・テスト
  3. `feature/xxx` → `develop` へ PR
  4. コードレビュー
  5. マージして統合

- リリース（Release）

  1. `develop` で統合テスト
  2. `develop` → `main` へ PR
  3. 本番デプロイ準備確認
  4. `main` へマージ
  5. 本番デプロイ

- ホットフィックス（Hotfix）
  1. `main` から `hotfix/xxx` を作成
  2. 緊急修正
  3. `main` と `develop` の双方へ反映
  4. 即時デプロイ

### ブランチ保護

- `main`

  - 直接 push 禁止 / PR・レビュー必須（最少 1 名）
  - 古いレビューの無効化、ステータスチェック必須
  - 必須チェック: `Flutter Build`, `Unit Tests`, `Integration Tests`

- `develop`
  - 直接 push 禁止 / PR・レビュー必須（最少 1 名）
  - ステータスチェック必須

### コミット規約（Conventional Commits）

- 形式: `{type}({scope}): {description}`
- 種別: `feat` | `fix` | `docs` | `style` | `refactor` | `test` | `chore`
- 例:

```text
feat(barcode): ML Kitバーコードスキャン機能追加
fix(auth): Firebase認証エラー修正
docs(readme): インストール手順更新
```

### CI/CD（GitHub Actions）

- トリガー: `push` / `pull_request`（`main`, `develop`）
- ジョブ例:
  - Build: Flutter SDK セットアップ → 依存解決 → フォーマット検証 → 静的解析 → ビルド
  - Test: Unit / Widget / Integration Tests
  - Deploy: `main` のみで Firebase/App Distribution（条件付き）

### 環境分離（Firebase/GCP）

- Production（`main`）
  - `gcp-hackathon-f06-prod` / `app.gcp-hackathon-f06.com`
- Staging（`develop`）
  - `gcp-hackathon-f06-staging` / `staging.gcp-hackathon-f06.com`
- Development（`feature/*`）
  - 開発者ごとに個別プロジェクトを推奨

### 利点

- 3 人の並行開発でも競合を最小化
- 安全で再現性の高いリリースプロセス
- 明確な役割分担と品質管理
- 環境分離による安全な検証
