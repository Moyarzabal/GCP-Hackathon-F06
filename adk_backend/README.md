# ADK Meal Planning API

Google ADK (Agent Development Kit) を使用したAI献立提案APIサーバーです。複数の専門エージェントが協調して高精度な献立提案を行います。

## アーキテクチャ

### エージェント構成

1. **食材分析エージェント** - 冷蔵庫の食材を分析し、賞味期限を考慮した優先度付け
2. **栄養バランスエージェント** - 栄養バランスを分析し、健康的な献立を提案
3. **料理提案エージェント** - 利用可能な食材から具体的な料理メニューを提案
4. **調理最適化エージェント** - 調理時間と手順を最適化
5. **献立テーマエージェント** - 献立全体のテーマと統一感を決定
6. **画像生成エージェント** - 各料理の魅力的な写真を生成
7. **ユーザー設定対話エージェント** - 自然な対話でユーザー設定を収集

### 技術スタック

- **Backend**: Python 3.11 + FastAPI
- **AI Models**: Google Gemini 1.5 Pro, OpenAI DALL-E 3
- **ADK Framework**: Google ADK (Python)
- **Container**: Docker
- **Deployment**: Google Cloud Run

## セットアップ

### 1. 環境準備

```bash
# リポジトリをクローン
git clone <repository-url>
cd adk_backend

# 仮想環境を作成
python -m venv venv
source venv/bin/activate  # Windows: venv\Scripts\activate

# 依存関係をインストール
pip install -r requirements.txt
```

### 2. 環境変数設定

```bash
# 環境変数ファイルをコピー
cp env.example .env

# .envファイルを編集してAPIキーを設定
# GEMINI_API_KEY=your_gemini_api_key
# OPENAI_API_KEY=your_openai_api_key
```

### 3. サーバー起動

```bash
# 開発サーバー起動
python main.py

# またはuvicornで起動
uvicorn main:app --host 0.0.0.0 --port 8000 --reload
```

## API エンドポイント

### 献立提案

```http
POST /api/v1/meal-planning/suggest
Content-Type: application/json

{
  "refrigerator_items": [
    {
      "id": "product_1",
      "name": "玉ねぎ",
      "category": "vegetables",
      "quantity": 2,
      "unit": "個",
      "expiry_date": "2024-01-15T00:00:00Z",
      "days_until_expiry": 3
    }
  ],
  "household_id": "household_123",
  "user_preferences": {
    "max_cooking_time": 60,
    "preferred_difficulty": "easy",
    "dietary_restrictions": [],
    "allergies": ["エビ"],
    "disliked_ingredients": ["にんじん"],
    "preferred_cuisines": ["和食", "イタリアン"]
  }
}
```

### 代替献立提案

```http
POST /api/v1/meal-planning/alternatives
Content-Type: application/json

{
  "original_meal_plan": { /* 元の献立データ */ },
  "refrigerator_items": [ /* 冷蔵庫の食材 */ ],
  "household_id": "household_123",
  "user_preferences": { /* ユーザー設定 */ },
  "reason": "辛すぎる"
}
```

### 個別エージェントAPI

```http
# 食材分析
POST /api/v1/agents/ingredient-analysis

# 栄養バランス分析
POST /api/v1/agents/nutrition-balance

# 料理提案
POST /api/v1/agents/recipe-suggestion

# 調理最適化
POST /api/v1/agents/cooking-optimization

# 献立テーマ決定
POST /api/v1/agents/meal-theme

# 画像生成
POST /api/v1/agents/image-generation

# ユーザー設定対話
POST /api/v1/agents/user-preferences
```

## Docker デプロイ

### 1. イメージビルド

```bash
docker build -t adk-meal-planning-api .
```

### 2. コンテナ実行

```bash
docker run -d \
  --name adk-api \
  -p 8000:8000 \
  -e GEMINI_API_KEY=your_api_key \
  -e OPENAI_API_KEY=your_api_key \
  adk-meal-planning-api
```

### 3. Google Cloud Run デプロイ

```bash
# Google Cloud SDKでログイン
gcloud auth login

# プロジェクト設定
gcloud config set project YOUR_PROJECT_ID

# Cloud Runにデプロイ
gcloud run deploy adk-meal-planning-api \
  --source . \
  --platform managed \
  --region asia-northeast1 \
  --allow-unauthenticated
```

## テスト

### 単体テスト

```bash
# テスト実行
pytest tests/

# カバレッジ付きテスト
pytest --cov=app tests/
```

### API テスト

```bash
# API ドキュメント確認
http://localhost:8000/docs

# ヘルスチェック
curl http://localhost:8000/health
```

## 監視とログ

### ログ設定

- 構造化ログ（JSON形式）
- ログレベル: INFO
- ログ出力先: stdout

### メトリクス

- 処理時間
- エージェント使用状況
- エラー率
- API呼び出し回数

## パフォーマンス

### 最適化

- エージェント並列処理
- レスポンスキャッシュ
- プロンプト最適化
- モデル選択の最適化

### スケーリング

- 水平スケーリング対応
- ロードバランシング
- オートスケーリング

## セキュリティ

- API認証（将来実装予定）
- レート制限
- 入力検証
- エラーハンドリング

## トラブルシューティング

### よくある問題

1. **APIキーエラー**
   - 環境変数の確認
   - APIキーの有効性確認

2. **メモリ不足**
   - コンテナリソースの調整
   - バッチサイズの最適化

3. **レスポンス時間が長い**
   - プロンプトの最適化
   - キャッシュの活用

### ログ確認

```bash
# コンテナログ確認
docker logs adk-api

# リアルタイムログ確認
docker logs -f adk-api
```

## ライセンス

MIT License

## 貢献

プルリクエストやイシューの報告を歓迎します。

## サポート

質問やサポートが必要な場合は、GitHubのIssuesページでお知らせください。
