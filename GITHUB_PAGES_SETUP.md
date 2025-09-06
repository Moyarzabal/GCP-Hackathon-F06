# GitHub Pages セットアップガイド

## 📖 概要

このガイドでは、冷蔵庫管理AIアプリのプロジェクトドキュメントをGitHub Pagesで公開する方法を説明します。

## 🚀 GitHub Pages 有効化手順

### 1. リポジトリ設定の確認

1. GitHubでリポジトリページに移動
2. **Settings** タブをクリック
3. サイドバーから **Pages** を選択

### 2. Source設定

**Pages** セクションで以下を設定：

- **Source**: `GitHub Actions` を選択
- **Branch**: ワークフローが配置されているブランチ（通常は `main`）

### 3. ワークフローファイルの確認

以下のファイルがリポジトリに含まれていることを確認：
- `.github/workflows/deploy-docs.yml`
- `docs/_config.yml`

### 4. デプロイの実行

設定完了後、以下のいずれかの方法でデプロイが開始されます：

#### 自動デプロイ (推奨)
- `main` または `develop` ブランチの `docs/` フォルダに変更をプッシュ
- GitHub Actionsが自動的にデプロイを実行

#### 手動デプロイ
1. リポジトリの **Actions** タブに移動
2. **Deploy Documentation to GitHub Pages** ワークフローを選択
3. **Run workflow** ボタンをクリック
4. ブランチを選択して **Run workflow** を実行

## 🌐 公開URL

デプロイが完了すると、以下のURLでドキュメントにアクセス可能：

```
https://<ユーザー名>.github.io/GCP-Hackathon-F06/
```

### ページ一覧

- **メインページ**: `https://<ユーザー名>.github.io/GCP-Hackathon-F06/`
- **ロードマップ**: `https://<ユーザー名>.github.io/GCP-Hackathon-F06/roadmap.html`
- **要件定義**: `https://<ユーザー名>.github.io/GCP-Hackathon-F06/index.html`

## 📝 カスタマイズ

### ドメイン設定の変更

`docs/_config.yml` で以下を更新：

```yaml
url: "https://your-username.github.io"
baseurl: "/your-repository-name"
```

### テーマのカスタマイズ

HTMLファイルのスタイルセクションを編集して、デザインをカスタマイズできます。

## ⚠️ トラブルシューティング

### デプロイが失敗する場合

1. **Actions** タブでエラーログを確認
2. 以下の権限が設定されていることを確認：
   - Settings > Actions > General > Workflow permissions
   - "Read and write permissions" を選択

### ページが表示されない場合

1. **Settings > Pages** で設定を確認
2. **Actions** タブでデプロイ状況を確認
3. ブラウザのキャッシュをクリア

### 404エラーが発生する場合

1. `docs/_config.yml` の `baseurl` 設定を確認
2. ファイルパスが正しいことを確認
3. HTMLファイル内のリンクパスを確認

## 📊 監視とメンテナンス

### デプロイ状況の確認

1. **Actions** タブでワークフローの実行状況を確認
2. **Settings > Pages** でPublishing sourceとBranchを確認

### 定期メンテナンス

- 月1回、リンク切れをチェック
- 四半期ごとに、Jekyll/GitHub Actionsの更新を確認
- プロジェクト進捗に合わせてドキュメントを更新

## 🔧 高度な設定

### カスタムドメインの使用

1. `docs/CNAME` ファイルを作成
2. カスタムドメインを記載
3. DNS設定でGitHub Pagesを指すCNAMEレコードを設定

### SEO最適化

`docs/_config.yml` に以下を追加：

```yaml
plugins:
  - jekyll-sitemap
  - jekyll-seo-tag
  - jekyll-feed

google_analytics: UA-XXXXXXXX-X  # Google Analytics ID
```

---

## 📞 サポート

設定で問題が発生した場合：

1. [GitHub Docs - GitHub Pages](https://docs.github.com/pages)
2. [Jekyll Documentation](https://jekyllrb.com/docs/)
3. プロジェクトのIssueを作成

---

**更新日**: 2024-09-05  
**作成者**: GCP Hackathon F06 Team