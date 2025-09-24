import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GeminiService {
  late final GenerativeModel _model;

  GeminiService() {
    try {
      final apiKey = dotenv.env['GEMINI_API_KEY'];
      if (apiKey == null || apiKey.isEmpty) {
        print('Warning: GEMINI_API_KEY not found, using mock responses');
        // モックモデルを使用（開発用）
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: 'mock-key',
        );
      } else {
        _model = GenerativeModel(
          model: 'gemini-1.5-flash',
          apiKey: apiKey,
        );
      }
    } catch (e) {
      print('Warning: Failed to access dotenv, using mock responses: $e');
      // エラー時はモックモデルを使用
      _model = GenerativeModel(
        model: 'gemini-1.5-flash',
        apiKey: 'mock-key',
      );
    }
  }

  Future<List<Recipe>> getRecipeSuggestions(List<String> ingredients) async {
    try {
      // APIキーが設定されていない場合はモックデータを返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getMockRecipes(ingredients);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using mock recipes: $e');
        return _getMockRecipes(ingredients);
      }

      final prompt = '''
あなたは料理のエキスパートです。以下の食材を使ったレシピを3つ提案してください。
各レシピには以下の情報を含めてください：
1. レシピ名
2. 調理時間
3. 難易度（簡単/普通/難しい）
4. 必要な材料と分量
5. 作り方（簡潔に）
6. カロリー目安

食材リスト：
${ingredients.join(', ')}

JSON形式で回答してください。形式：
[
  {
    "name": "レシピ名",
    "cookingTime": "調理時間",
    "difficulty": "難易度",
    "ingredients": ["材料1: 分量", "材料2: 分量"],
    "instructions": ["手順1", "手順2"],
    "calories": "カロリー目安"
  }
]
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        return [];
      }

      // Parse JSON response
      final jsonStr = _extractJson(response.text!);
      if (jsonStr == null) return [];

      final List<dynamic> recipesJson = List<dynamic>.from(
        (jsonStr is String) ? _parseJson(jsonStr) : jsonStr
      );

      return recipesJson.map((json) => Recipe.fromJson(json)).toList();
    } catch (e) {
      print('Error getting recipe suggestions: $e');
      return _getMockRecipes(ingredients);
    }
  }

  List<Recipe> _getMockRecipes(List<String> ingredients) {
    return [
      Recipe(
        name: '${ingredients.take(2).join('と')}の炒め物',
        cookingTime: '15分',
        difficulty: '簡単',
        ingredients: ingredients.take(3).map((ing) => '$ing: 適量').toList(),
        instructions: ['材料を切る', 'フライパンで炒める', '調味料で味付け'],
        calories: '約200kcal',
      ),
      Recipe(
        name: '${ingredients.first}のサラダ',
        cookingTime: '10分',
        difficulty: '簡単',
        ingredients: ingredients.take(2).map((ing) => '$ing: 適量').toList()..add('ドレッシング: 適量'),
        instructions: ['材料を切る', 'ボウルで混ぜる', 'ドレッシングをかける'],
        calories: '約150kcal',
      ),
    ];
  }

  Future<String> getFoodWasteTip(String productName, int daysUntilExpiry) async {
    try {
      // APIキーが設定されていない場合はモックデータを返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getMockFoodWasteTip(productName, daysUntilExpiry);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using mock food waste tip: $e');
        return _getMockFoodWasteTip(productName, daysUntilExpiry);
      }

      final prompt = '''
「$productName」があと$daysUntilExpiry日で賞味期限を迎えます。
この食材を無駄にしないための具体的なアドバイスを1つ、100文字以内で教えてください。
保存方法の工夫や、すぐに使えるレシピのアイデアなどを含めてください。
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      return response.text ?? '賞味期限が近づいています。早めにお使いください。';
    } catch (e) {
      print('Error getting food waste tip: $e');
      return _getMockFoodWasteTip(productName, daysUntilExpiry);
    }
  }

  String _getMockFoodWasteTip(String productName, int daysUntilExpiry) {
    if (daysUntilExpiry <= 1) {
      return '$productNameは今日中に使い切りましょう！冷凍保存や炒め物にして保存期間を延ばせます。';
    } else if (daysUntilExpiry <= 3) {
      return '$productNameは早めに調理しましょう。サラダや炒め物にすると美味しく食べられます。';
    } else {
      return '$productNameはまだ大丈夫です。冷蔵庫で適切に保存して、計画的に使いましょう。';
    }
  }

  Future<NutritionAdvice> getNutritionAdvice(List<String> recentMeals) async {
    try {
      // APIキーが設定されていない場合はモックデータを返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getMockNutritionAdvice(recentMeals);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using mock nutrition advice: $e');
        return _getMockNutritionAdvice(recentMeals);
      }

      final prompt = '''
最近の食事内容を分析して、栄養バランスのアドバイスをしてください。

最近の食事：
${recentMeals.join(', ')}

以下の形式でJSON形式で回答してください：
{
  "overallScore": 0-100の数値,
  "strengths": ["良い点1", "良い点2"],
  "improvements": ["改善点1", "改善点2"],
  "recommendations": ["おすすめ食材1", "おすすめ食材2"]
}
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        return NutritionAdvice.empty();
      }

      final jsonStr = _extractJson(response.text!);
      if (jsonStr == null) return NutritionAdvice.empty();

      final json = _parseJson(jsonStr);
      return NutritionAdvice.fromJson(json);
    } catch (e) {
      print('Error getting nutrition advice: $e');
      return _getMockNutritionAdvice(recentMeals);
    }
  }

  NutritionAdvice _getMockNutritionAdvice(List<String> recentMeals) {
    return NutritionAdvice(
      overallScore: 75,
      strengths: ['野菜を多く摂取している', 'バランスの良い食事'],
      improvements: ['タンパク質の摂取を増やす', '水分補給を心がける'],
      recommendations: ['魚介類', '豆類', 'ナッツ類'],
    );
  }

  /// 商品分析（カテゴリ分類と賞味期限予測を統合）
  Future<ProductAnalysis> analyzeProduct({
    required String productName,
    String? manufacturer,
    String? brandName,
    required List<String> categoryOptions,
  }) async {
    try {
      // APIキーが設定されていない場合はモックデータを返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using mock product analysis: $e');
        return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
      }

      final prompt = '''
商品名: $productName
メーカー: ${manufacturer ?? '不明'}
ブランド: ${brandName ?? '不明'}

以下の情報をJSON形式で回答してください：
1. カテゴリ分類（以下の選択肢から1つ）
2. 賞味期限（今日から数えて何日後に設定すべきかの日数）
3. 信頼度（0.0-1.0）

利用可能なカテゴリ：
${categoryOptions.map((cat) => '- $cat').join('\n')}

回答形式：
{
  "category": "カテゴリ名",
  "expiryDays": 数字,
  "confidence": 0.0-1.0
}

例：
- 牛乳: {"category": "乳製品", "expiryDays": 7, "confidence": 0.9}
- トマト: {"category": "野菜", "expiryDays": 5, "confidence": 0.8}
- カップラーメン: {"category": "即席麺", "expiryDays": 60, "confidence": 0.95}

注意：
- カテゴリは必ず提供された選択肢の中から選んでください
- 賞味期限は今日から数えて何日後に設定すべきかを日数で回答してください
- 冷蔵保存を前提として計算してください
''';

      final content = [Content.text(prompt)];
      final response = await _model.generateContent(content);

      if (response.text == null) {
        return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
      }

      // JSONを抽出して解析
      final jsonStr = _extractJson(response.text!);
      if (jsonStr == null) {
        return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
      }

      final json = _parseJson(jsonStr);
      if (json is Map && json['category'] != null && json['expiryDays'] != null) {
        return ProductAnalysis.fromJson(Map<String, dynamic>.from(json));
      }

        return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
    } catch (e) {
      print('Error analyzing product: $e');
        return _getMockProductAnalysis(productName, manufacturer, brandName, categoryOptions);
    }
  }

  ProductAnalysis _getMockProductAnalysis(String productName, String? manufacturer, String? brandName, List<String> categoryOptions) {
    // 商品名に基づく簡単なカテゴリ判定
    final name = productName.toLowerCase();
    String category = categoryOptions.isNotEmpty ? categoryOptions.first : 'その他';
    int expiryDays = 7;
    double confidence = 0.5;

    // 提供されたカテゴリリストから適切なカテゴリを選択
    if (name.contains('牛乳') || name.contains('ヨーグルト') || name.contains('チーズ')) {
      category = categoryOptions.contains('乳製品') ? '乳製品' : categoryOptions.first;
      expiryDays = 7;
      confidence = 0.8;
    } else if (name.contains('肉') || name.contains('ハム') || name.contains('ソーセージ')) {
      category = categoryOptions.contains('肉類') ? '肉類' : categoryOptions.first;
      expiryDays = 3;
      confidence = 0.8;
    } else if (name.contains('魚') || name.contains('刺身') || name.contains('寿司')) {
      category = categoryOptions.contains('魚類') ? '魚類' : categoryOptions.first;
      expiryDays = 3;
      confidence = 0.8;
    } else if (name.contains('野菜') || name.contains('トマト') || name.contains('レタス')) {
      category = categoryOptions.contains('野菜') ? '野菜' : categoryOptions.first;
      expiryDays = 5;
      confidence = 0.7;
    } else if (name.contains('果物') || name.contains('りんご') || name.contains('バナナ')) {
      category = categoryOptions.contains('果物') ? '果物' : categoryOptions.first;
      expiryDays = 5;
      confidence = 0.7;
    } else if (name.contains('ジュース') || name.contains('コーラ') || name.contains('お茶')) {
      category = categoryOptions.contains('飲料') ? '飲料' : categoryOptions.first;
      expiryDays = 30;
      confidence = 0.8;
    } else if (name.contains('ラーメン') || name.contains('うどん') || name.contains('そば')) {
      category = categoryOptions.contains('即席麺') ? '即席麺' : categoryOptions.first;
      expiryDays = 60;
      confidence = 0.9;
    } else if (name.contains('缶詰') || name.contains('レトルト') || name.contains('冷凍')) {
      category = categoryOptions.contains('加工食品') ? '加工食品' : categoryOptions.first;
      expiryDays = 30;
      confidence = 0.7;
    }

    return ProductAnalysis(
      category: category,
      expiryDays: expiryDays,
      confidence: confidence,
    );
  }

  /// 汎用的なコンテンツ生成メソッド
  Future<GenerateContentResponse> generateContent(String prompt) async {
    try {
      // APIキーが設定されていない場合はモックデータを返す
      try {
        if (dotenv.env['GEMINI_API_KEY'] == null || dotenv.env['GEMINI_API_KEY']!.isEmpty) {
          return _getMockResponse(prompt);
        }
      } catch (e) {
        print('Warning: Failed to access dotenv, using mock response: $e');
        return _getMockResponse(prompt);
      }

      final content = [Content.text(prompt)];
      return await _model.generateContent(content);
    } catch (e) {
      print('Error generating content: $e');
      return _getMockResponse(prompt);
    }
  }

  GenerateContentResponse _getMockResponse(String prompt) {
    // MockではGenerateContentResponseの代わりに例外を投げる
    throw Exception('Mock response for development');
  }

  String? _extractJson(String text) {
    // Extract JSON from the response
    final jsonStart = text.indexOf('[');
    final jsonStartObj = text.indexOf('{');

    if (jsonStart == -1 && jsonStartObj == -1) return null;

    final start = (jsonStart != -1 && jsonStartObj != -1)
        ? (jsonStart < jsonStartObj ? jsonStart : jsonStartObj)
        : (jsonStart != -1 ? jsonStart : jsonStartObj);

    if (text[start] == '[') {
      final jsonEnd = text.lastIndexOf(']');
      if (jsonEnd == -1) return null;
      return text.substring(start, jsonEnd + 1);
    } else {
      final jsonEnd = text.lastIndexOf('}');
      if (jsonEnd == -1) return null;
      return text.substring(start, jsonEnd + 1);
    }
  }

  dynamic _parseJson(String jsonStr) {
    try {
      // Remove any markdown code block markers
      jsonStr = jsonStr.replaceAll('```json', '').replaceAll('```', '').trim();

      // Use dart:convert for proper JSON parsing
      return json.decode(jsonStr);
    } catch (e) {
      print('Error parsing JSON: $e');
      return null;
    }
  }
}

class Recipe {
  final String name;
  final String cookingTime;
  final String difficulty;
  final List<String> ingredients;
  final List<String> instructions;
  final String calories;

  Recipe({
    required this.name,
    required this.cookingTime,
    required this.difficulty,
    required this.ingredients,
    required this.instructions,
    required this.calories,
  });

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      name: json['name'] ?? '',
      cookingTime: json['cookingTime'] ?? '',
      difficulty: json['difficulty'] ?? '',
      ingredients: List<String>.from(json['ingredients'] ?? []),
      instructions: List<String>.from(json['instructions'] ?? []),
      calories: json['calories'] ?? '',
    );
  }
}

class NutritionAdvice {
  final int overallScore;
  final List<String> strengths;
  final List<String> improvements;
  final List<String> recommendations;

  NutritionAdvice({
    required this.overallScore,
    required this.strengths,
    required this.improvements,
    required this.recommendations,
  });

  factory NutritionAdvice.fromJson(Map<String, dynamic> json) {
    return NutritionAdvice(
      overallScore: json['overallScore'] ?? 0,
      strengths: List<String>.from(json['strengths'] ?? []),
      improvements: List<String>.from(json['improvements'] ?? []),
      recommendations: List<String>.from(json['recommendations'] ?? []),
    );
  }

  factory NutritionAdvice.empty() {
    return NutritionAdvice(
      overallScore: 0,
      strengths: [],
      improvements: [],
      recommendations: [],
    );
  }
}

class ProductAnalysis {
  final String category;
  final int expiryDays;
  final double confidence;

  ProductAnalysis({
    required this.category,
    required this.expiryDays,
    required this.confidence,
  });

  factory ProductAnalysis.fromJson(Map<String, dynamic> json) {
    return ProductAnalysis(
      category: json['category'] ?? 'その他',
      expiryDays: json['expiryDays'] ?? 7,
      confidence: (json['confidence'] ?? 0.5).toDouble(),
    );
  }

  DateTime get expiryDate => DateTime.now().add(Duration(days: expiryDays));
}