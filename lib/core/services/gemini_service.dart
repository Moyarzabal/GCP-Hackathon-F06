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