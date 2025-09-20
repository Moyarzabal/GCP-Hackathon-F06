# 商品画像生成プロンプト改善

## 概要
商品画像生成において、商品名が文字として画像内に表示される問題を解決し、賞味期限の短縮に応じてキャラクターの周りにより濃いもやがかかる表現を追加しました。

## 実装内容

### 1. 文字表示問題の解決
- **問題**: 商品名がプロンプトに含まれることで、画像内にテキストとして表示される
- **解決策**: 
  - 商品名に基づくキャラクター生成は維持
  - カテゴリベースの視覚的特徴マッピングを追加で導入
  - 明示的なテキスト禁止指示を追加: `"NO text, letters, words, or product names visible in the image, focus purely on character design and visual representation"`

### 2. 賞味期限表現の強化
賞味期限の短縮に応じて、キャラクターの周りのもやを段階的に濃くする表現を実装：

| 感情状態 | もやレベル | 表現 |
|---------|-----------|------|
| 😊 (新鮮) | なし | clear bright atmosphere with no haze, sparkling clean air |
| 😐 (やや心配) | 軽い | light misty atmosphere, subtle haze around character |
| 😟 (心配) | 中程度 | moderate haze surrounding character, cloudy atmosphere |
| 😰 (パニック) | 濃い | thick dense haze enveloping character, heavy fog atmosphere |
| 💀 (期限切れ) | 極厚 | extremely thick ominous haze, supernatural fog, eerie mist |

### 3. カテゴリ特徴マッピング
商品名と組み合わせて使用する視覚的特徴を提供：

- **乳製品**: creamy white appearance, soft rounded features
- **肉類**: rich reddish-brown coloring, hearty robust features  
- **野菜**: fresh green tones, leafy or rounded natural features
- **果物**: bright vibrant colors, sweet cheerful features
- **穀物**: warm golden-brown tones, wholesome sturdy features
- **海産物**: silvery-blue tones, sleek streamlined features

## ファイル構成

```
docs/product_image_prompt_improvement/
├── README.md                    # このファイル
├── current_implementation.yaml  # 現在の実装分析
├── modification_plan.yaml       # 修正計画
└── updated_implementation.yaml  # 更新後の実装詳細
```

## 技術的変更点

### 修正されたメソッド
- `_createPrompt()`: プロンプト生成ロジックを大幅改善
- `_getCategoryTraits()`: 新規追加 - カテゴリベースの特徴マッピング

### 互換性
- 既存のAPIインターフェースを完全に保持
- 後方互換性を維持
- 既存のキャッシュシステムとの互換性

## 期待される効果

1. **文字表示の完全排除**: 画像内にテキストが表示されない
2. **商品ベースのキャラクター**: 商品名に基づく適切なキャラクター表現
3. **視覚的魅力の向上**: よりクリーンで魅力的なキャラクター画像
4. **賞味期限認識の改善**: もやの段階的変化により期限状態が直感的に理解可能
5. **豊かな表現**: 商品名とカテゴリ特徴の組み合わせによる多様な表現

## 実装済みファイル
- `lib/core/services/imagen_service.dart`: メインの実装ファイル

## 注意事項
- デプロイ後は既存のキャッシュをクリアすることを推奨
- 生成結果の品質監視を継続的に行うことを推奨
