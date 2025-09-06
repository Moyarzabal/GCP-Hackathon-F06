# 🍅 冷蔵庫管理AIアプリ - プロジェクトドキュメント

## 📖 概要

このディレクトリには、冷蔵庫管理AIアプリのプロジェクトドキュメントとGitHub Pagesサイトが含まれています。

## 🌐 公開サイト

- **メインサイト**: [プロジェクト概要](./index.html)
- **ロードマップ**: [開発ロードマップ](./roadmap.html)
- **詳細計画**: [development-roadmap.md](./development-roadmap.md)

## 📁 ファイル構成

```
docs/
├── index.html              # メインページ（要件定義書）
├── roadmap.html            # 開発ロードマップページ  
├── development-roadmap.md  # 詳細開発計画（マークダウン）
├── _config.yml            # Jekyll設定
└── README.md              # このファイル
```

## 🚀 GitHub Pages デプロイ方法

### 1. 自動デプロイ（推奨）

リポジトリの設定が完了していれば、以下の操作で自動デプロイされます：

```bash
# docsディレクトリ内のファイルを更新
git add docs/
git commit -m "docs: プロジェクトドキュメント更新"
git push origin main
```

### 2. 手動デプロイ

1. GitHubリポジトリの **Actions** タブに移動
2. **Deploy to GitHub Pages** ワークフローを選択
3. **Run workflow** をクリック
4. **Run workflow** を実行

### 3. 初回設定手順

GitHubリポジトリで以下を設定：

1. **Settings** → **Pages**
2. **Source**: `GitHub Actions` を選択
3. **Save** をクリック

## 🛠 ローカル開発

### Jekyll でローカル実行

```bash
# Jekyll をインストール（初回のみ）
gem install bundler jekyll

# docsディレクトリに移動
cd docs

# 依存関係をインストール
bundle install

# ローカルサーバー起動
bundle exec jekyll serve

# ブラウザで確認
open http://localhost:4000
```

### シンプルなHTTPサーバー

```bash
# docsディレクトリに移動
cd docs

# Python HTTPサーバー起動
python3 -m http.server 8000

# ブラウザで確認
open http://localhost:8000
```

## 📝 ドキュメント更新手順

### 1. ロードマップの更新

`roadmap.html` を直接編集するか、`development-roadmap.md` を更新してから変換：

```bash
# マークダウンファイル更新
vi docs/development-roadmap.md

# HTMLファイル更新（必要に応じて）
vi docs/roadmap.html

# 変更をコミット
git add docs/
git commit -m "docs: ロードマップ更新"
git push origin main
```

### 2. 要件定義の更新

```bash
# メインページ更新
vi docs/index.html

# 変更をコミット
git add docs/index.html
git commit -m "docs: 要件定義更新"
git push origin main
```

## ⚠️ トラブルシューティング

### ページが表示されない

1. **GitHub Actions** でデプロイ状況を確認
2. **Settings → Pages** で設定を確認
3. ブラウザキャッシュをクリア

### 404エラー

1. `_config.yml` の `baseurl` 設定を確認
2. HTMLファイル内のリンクパスを確認
3. ファイル名の大文字小文字を確認

### CSSが適用されない

1. HTMLファイル内のスタイルタグを確認
2. 外部CSSファイルのパスを確認
3. ブラウザの開発者ツールでネットワークエラーを確認

## 📊 パフォーマンス最適化

### 画像最適化

```bash
# 画像ファイルを追加する場合
# WebP形式に変換して容量を削減
cwebp -q 80 input.png -o output.webp
```

### HTMLミニファイ

```bash
# html-minifierをインストール
npm install -g html-minifier

# HTMLファイルを圧縮
html-minifier --collapse-whitespace --remove-comments --minify-css --minify-js docs/roadmap.html -o docs/roadmap.min.html
```

## 🔍 SEO設定

`_config.yml` でSEO設定を最適化：

```yaml
title: "🍅 冷蔵庫管理AIアプリ"
description: "Flutter + Firebase + GCP による冷蔵庫管理AIアプリの開発ドキュメント"
lang: ja_JP
author: "GCP Hackathon F06 Team"

plugins:
  - jekyll-seo-tag
  - jekyll-sitemap
```

---

## 📞 サポート

ドキュメントに関する質問や問題：

- **GitHub Issues**: [プロジェクトのIssue](https://github.com/yourusername/GCP-Hackathon-F06/issues)
- **GitHub Discussions**: プロジェクトのDiscussions
- **Email**: team-f06@example.com

---

**最終更新**: 2024-09-05  
**作成者**: GCP Hackathon F06 Team