import 'dart:convert';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../../shared/models/product.dart';
import '../../shared/models/meal_plan.dart';
import '../../shared/models/shopping_item.dart';

/// AI献立提案サービスの設定
class MealPlanningConfig {
  final String apiKey;
  final String model;
  final double temperature;
  final int maxTokens;

  const MealPlanningConfig({
    required this.apiKey,
    this.model = 'gemini-1.5-flash',
    this.temperature = 0.7,
    this.maxTokens = 2048,
  });
}

/// ユーザーの好み設定
class UserPreferences {
  final int maxCookingTime; // 分
  final DifficultyLevel preferredDifficulty;
  final List<String> dietaryRestrictions;
  final List<String> allergies;
  final List<String> dislikedIngredients;
  final List<String> preferredCuisines;

  const UserPreferences({
    this.maxCookingTime = 60,
    this.preferredDifficulty = DifficultyLevel.easy,
    this.dietaryRestrictions = const [],
    this.allergies = const [],
    this.dislikedIngredients = const [],
    this.preferredCuisines = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'maxCookingTime': maxCookingTime,
      'preferredDifficulty': preferredDifficulty.name,
      'dietaryRestrictions': dietaryRestrictions,
      'allergies': allergies,
      'dislikedIngredients': dislikedIngredients,
      'preferredCuisines': preferredCuisines,
    };
  }
}

/// AI献立提案サービス
class AIMealPlanningService {
  final MealPlanningConfig _config;
  late final GenerativeModel _model;

  AIMealPlanningService(this._config) {
    _model = GenerativeModel(
      model: _config.model,
      apiKey: _config.apiKey,
      generationConfig: GenerationConfig(
        temperature: _config.temperature,
        maxOutputTokens: _config.maxTokens,
      ),
    );
  }

  /// 献立を提案する
  Future<MealPlan> suggestMealPlan({
    required List<Product> refrigeratorItems,
    required String householdId,
    required UserPreferences preferences,
  }) async {
    try {
      print('🍽️ AI献立生成開始');
      print('   冷蔵庫の商品数: ${refrigeratorItems.length}');
      print('   世帯ID: $householdId');
      
      // 冷蔵庫の食材を分析
      print('🔍 食材分析中...');
      final analyzedIngredients = _analyzeIngredients(refrigeratorItems);
      print('   分析された食材数: ${analyzedIngredients.length}');
      
      // AIに献立生成を依頼
      print('🤖 AIに献立生成を依頼中...');
      final prompt = _buildMealPlanPrompt(analyzedIngredients, preferences);
      print('   プロンプト長: ${prompt.length}文字');
      
      final response = await _model.generateContent([Content.text(prompt)]);
      print('   AIレスポンス受信: ${response.text?.length ?? 0}文字');
      
      // レスポンスをパースしてMealPlanオブジェクトに変換
      print('📝 レスポンス解析中...');
      final mealPlan = _parseMealPlanResponse(
        response.text ?? '',
        householdId,
        analyzedIngredients,
      );
      
      print('✅ 献立生成完了: ${mealPlan.displayName}');
      return mealPlan;
    } catch (e) {
      print('❌ 献立生成エラー: $e');
      throw Exception('献立の生成に失敗しました: $e');
    }
  }

  /// 代替献立を提案する
  Future<List<MealPlan>> suggestAlternatives({
    required MealPlan originalMealPlan,
    required List<Product> refrigeratorItems,
    required String householdId,
    required UserPreferences preferences,
    required String reason,
  }) async {
    try {
      final analyzedIngredients = _analyzeIngredients(refrigeratorItems);
      
      final prompt = _buildAlternativePrompt(
        originalMealPlan,
        analyzedIngredients,
        preferences,
        reason,
      );
      
      final response = await _model.generateContent([Content.text(prompt)]);
      final alternatives = _parseAlternativesResponse(
        response.text ?? '',
        householdId,
        analyzedIngredients,
      );
      
      return alternatives;
    } catch (e) {
      throw Exception('代替献立の生成に失敗しました: $e');
    }
  }

  /// 冷蔵庫の食材を分析
  List<Ingredient> _analyzeIngredients(List<Product> products) {
    final ingredients = <Ingredient>[];
    
    for (final product in products) {
      // 賞味期限の優先度を決定
      final priority = _determineExpiryPriority(product.daysUntilExpiry);
      
      // カテゴリを日本語に変換
      final category = _translateCategory(product.category);
      
      final ingredient = Ingredient(
        name: product.name,
        quantity: product.quantity.toString(),
        unit: product.unit,
        available: true,
        expiryDate: product.expiryDate,
        shoppingRequired: false,
        productId: product.id,
        priority: priority,
        category: category,
        imageUrl: product.currentImageUrl,
      );
      
      ingredients.add(ingredient);
    }
    
    // 優先度でソート（緊急度の高いものから）
    ingredients.sort((a, b) => a.priorityScore.compareTo(b.priorityScore));
    
    return ingredients;
  }

  /// 賞味期限の優先度を決定
  ExpiryPriority _determineExpiryPriority(int daysUntilExpiry) {
    if (daysUntilExpiry <= 0) return ExpiryPriority.urgent;
    if (daysUntilExpiry <= 1) return ExpiryPriority.urgent;
    if (daysUntilExpiry <= 3) return ExpiryPriority.soon;
    if (daysUntilExpiry <= 7) return ExpiryPriority.fresh;
    return ExpiryPriority.longTerm;
  }

  /// カテゴリを日本語に変換
  String _translateCategory(String category) {
    const categoryMap = {
      'vegetables': '野菜',
      'fruits': '果物',
      'meat': '肉',
      'fish': '魚',
      'dairy': '乳製品',
      'grains': '主食',
      'seasonings': '調味料',
      'beverages': '飲み物',
      'snacks': 'お菓子',
      'frozen': '冷凍食品',
    };
    
    return categoryMap[category.toLowerCase()] ?? category;
  }

  /// 献立生成のプロンプトを構築
  String _buildMealPlanPrompt(List<Ingredient> ingredients, UserPreferences preferences) {
    final ingredientsText = ingredients.map((ingredient) {
      final priorityText = ingredient.priority == ExpiryPriority.urgent ? '[URGENT]' : 
                          ingredient.priority == ExpiryPriority.soon ? '[SOON]' : '';
      return '$priorityText${ingredient.name} ${ingredient.quantity}${ingredient.unit}';
    }).join('\n');

    final restrictionsText = preferences.dietaryRestrictions.isNotEmpty 
        ? 'Restrictions: ${preferences.dietaryRestrictions.join(', ')}'
        : '';
    
    final allergiesText = preferences.allergies.isNotEmpty 
        ? 'Allergies: ${preferences.allergies.join(', ')}'
        : '';

    return '''
You are a refrigerator management and nutrition expert. Please suggest a meal plan following these principles:

[Principles]
1. Prioritize ingredients with close expiry dates ([URGENT] and [SOON] marked ingredients have highest priority)
2. Good nutritional balance
3. Consider cooking time and difficulty
4. Consider seasonality and timing
5. Consist of main dish, side dish, soup, and staple food (4 items)

[Refrigerator Ingredients]
$ingredientsText

[User Settings]
- Max cooking time: ${preferences.maxCookingTime} minutes
- Difficulty: ${preferences.preferredDifficulty.name}
$restrictionsText
$allergiesText

[Output Format]
Please suggest a meal plan in the following JSON format:

{
  "mainDish": {
    "name": "Menu name in Japanese",
    "description": "Brief description in Japanese",
    "cookingTime": cooking_time_in_minutes,
    "difficulty": "easy/medium/hard/expert",
    "ingredients": [
      {
        "name": "玉ねぎ",
        "quantity": "1個",
        "unit": "個",
        "available": true,
        "priority": "urgent"
      }
    ],
    "recipe": {
      "steps": ["Step 1 in Japanese", "Step 2 in Japanese", "Step 3 in Japanese"],
      "tips": ["Tip 1 in Japanese", "Tip 2 in Japanese"]
    },
    "nutritionInfo": {
      "calories": calories_number,
      "protein": protein_grams,
      "carbohydrates": carbs_grams,
      "fat": fat_grams
    }
  },
  "sideDish": { /* Same structure */ },
  "soup": { /* Same structure */ },
  "rice": { /* Same structure */ },
  "totalCookingTime": total_cooking_time_in_minutes,
  "difficulty": "easy/medium/hard/expert",
  "nutritionScore": nutrition_score_0_to_100,
  "confidence": confidence_0_to_1
}

CRITICAL REQUIREMENTS:
- All text content should be in Japanese
- String fields (name, description, quantity, unit, steps, tips) MUST be quoted with double quotes
- Numeric fields (cookingTime, calories, protein, carbohydrates, fat, totalCookingTime, nutritionScore, confidence) MUST be numbers without quotes
- Boolean fields (available) MUST be true/false without quotes
- For quantity field: use format like "1個", "2本", "大さじ1", "小さじ2", "100g" (number + unit)
- For unit field: use simple units like "個", "本", "枚", "g", "ml" (unit only)
- IMPORTANT: quantity field should already include the unit, so unit field should be the same unit
- Return ONLY valid JSON format
- Do NOT include any text outside the JSON
- Example: "quantity": "1個", "unit": "個" (correct) NOT "quantity": "1個個", "unit": "個" (incorrect)
''';
  }

  /// 代替献立のプロンプトを構築
  String _buildAlternativePrompt(
    MealPlan originalMealPlan,
    List<Ingredient> ingredients,
    UserPreferences preferences,
    String reason,
  ) {
    return '''
元の献立: ${originalMealPlan.displayName}
理由: $reason

上記の理由で代替献立を提案してください。元の献立とは異なるアプローチで、同じ食材を使って新しい献立を考えてください。

【冷蔵庫の食材】
${ingredients.map((ingredient) => '${ingredient.name} ${ingredient.quantity}${ingredient.unit}').join('\n')}

【出力形式】
元の献立と同じJSON形式で、3つの代替案を提案してください。
''';
  }

  /// 献立レスポンスをパース
  MealPlan _parseMealPlanResponse(
    String response,
    String householdId,
    List<Ingredient> availableIngredients,
  ) {
    try {
      // JSON部分を抽出
      final jsonStart = response.indexOf('{');
      final jsonEnd = response.lastIndexOf('}') + 1;
      
      if (jsonStart == -1 || jsonEnd == 0) {
        throw Exception('JSON形式のレスポンスが見つかりません');
      }
      
      String jsonString = response.substring(jsonStart, jsonEnd);
      
      // 日本語の数量文字列を数値に変換
      jsonString = _cleanJsonResponse(jsonString);
      
      final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
      
      // 各メニューアイテムを生成
      final mainDish = _parseMealItem(jsonData['mainDish'] as Map<String, dynamic>, availableIngredients);
      final sideDish = _parseMealItem(jsonData['sideDish'] as Map<String, dynamic>, availableIngredients);
      final soup = _parseMealItem(jsonData['soup'] as Map<String, dynamic>, availableIngredients);
      final rice = _parseMealItem(jsonData['rice'] as Map<String, dynamic>, availableIngredients);
      
      return MealPlan(
        householdId: householdId,
        date: DateTime.now(),
        status: MealPlanStatus.suggested,
        mainDish: mainDish,
        sideDish: sideDish,
        soup: soup,
        rice: rice,
        totalCookingTime: jsonData['totalCookingTime'] as int? ?? 60,
        difficulty: DifficultyLevel.values.firstWhere(
          (e) => e.name == jsonData['difficulty'],
          orElse: () => DifficultyLevel.easy,
        ),
        nutritionScore: (jsonData['nutritionScore'] as num?)?.toDouble() ?? 80.0,
        confidence: (jsonData['confidence'] as num?)?.toDouble() ?? 0.8,
        createdAt: DateTime.now(),
        createdBy: 'ai_agent',
      );
    } catch (e) {
      throw Exception('献立データの解析に失敗しました: $e');
    }
  }

  /// メニューアイテムをパース
  MealItem _parseMealItem(Map<String, dynamic> data, List<Ingredient> availableIngredients) {
    final ingredients = (data['ingredients'] as List<dynamic>)
        .map((ingredientData) => _parseIngredient(ingredientData as Map<String, dynamic>, availableIngredients))
        .toList();
    
    final recipeData = data['recipe'] as Map<String, dynamic>;
    final recipe = Recipe(
      steps: (recipeData['steps'] as List<dynamic>)
          .asMap()
          .entries
          .map((entry) => RecipeStep(
                stepNumber: entry.key + 1,
                description: entry.value as String,
              ))
          .toList(),
      cookingTime: data['cookingTime'] as int? ?? 30,
      prepTime: 10, // デフォルト値
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      tips: (recipeData['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      servingSize: 4, // デフォルト値
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>),
    );
    
    return MealItem(
      name: data['name'] as String,
      category: MealCategory.main, // デフォルト値、実際は呼び出し元で設定
      description: data['description'] as String? ?? '',
      ingredients: ingredients,
      recipe: recipe,
      cookingTime: data['cookingTime'] as int? ?? 30,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>),
      createdAt: DateTime.now(),
    );
  }

  /// 材料をパース
  Ingredient _parseIngredient(Map<String, dynamic> data, List<Ingredient> availableIngredients) {
    final name = data['name'] as String;
    final available = data['available'] as bool? ?? true;
    final quantity = data['quantity'] as String? ?? '1';
    final unit = data['unit'] as String? ?? '個';
    
    // 利用可能な材料から詳細情報を取得
    final availableIngredient = availableIngredients.firstWhere(
      (ingredient) => ingredient.name == name,
      orElse: () => Ingredient(
        name: name,
        quantity: quantity,
        unit: unit,
        available: available,
        shoppingRequired: !available,
        priority: ExpiryPriority.values.firstWhere(
          (e) => e.name == data['priority'],
          orElse: () => ExpiryPriority.fresh,
        ),
        category: 'その他',
      ),
    );
    
    return availableIngredient.copyWith(
      quantity: quantity,
      unit: unit,
      available: available,
      shoppingRequired: !available,
    );
  }

  /// 栄養情報をパース
  NutritionInfo _parseNutritionInfo(Map<String, dynamic> data) {
    return NutritionInfo(
      calories: (data['calories'] as num?)?.toDouble() ?? 0.0,
      protein: (data['protein'] as num?)?.toDouble() ?? 0.0,
      carbohydrates: (data['carbohydrates'] as num?)?.toDouble() ?? 0.0,
      fat: (data['fat'] as num?)?.toDouble() ?? 0.0,
      fiber: 0.0, // デフォルト値
      sugar: 0.0, // デフォルト値
      sodium: 0.0, // デフォルト値
    );
  }

  /// JSONレスポンスをクリーニング
  String _cleanJsonResponse(String jsonString) {
    // クォーテーションなしの文字列フィールドにクォーテーションを追加
    String cleaned = jsonString;
    
    // quantity, unit, name, description などの文字列フィールドを処理
    final stringFields = ['quantity', 'unit', 'name', 'description'];
    
    for (final field in stringFields) {
      // クォーテーションなしのパターンを検索して修正
      final unquotedPattern = RegExp('"$field":\\s*([^",}\\]]+?)(?=,|\\}|\\])');
      cleaned = cleaned.replaceAllMapped(unquotedPattern, (match) {
        final value = match.group(1)?.trim() ?? '';
        // 既にクォーテーションで囲まれている場合はスキップ
        if (value.startsWith('"') && value.endsWith('"')) {
          return match.group(0)!;
        }
        
        // 重複を除去（例：「1本本」→「1本」、「大さじ1大さじ」→「大さじ1」）
        final cleanedValue = _removeDuplicates(value);
        
        // クォーテーションを追加
        return '"$field": "$cleanedValue"';
      });
    }
    
    return cleaned;
  }

  /// 重複を除去する
  String _removeDuplicates(String value) {
    // よくある重複パターンを修正
    final patterns = [
      (RegExp(r'(\d+)(個|本|枚|パック|杯|さじ|大さじ|小さじ)\1\2'), r'$1$2'), // 1個個 → 1個
      (RegExp(r'(大さじ|小さじ)(\d+)\1'), r'$1$2'), // 大さじ1大さじ → 大さじ1
      (RegExp(r'(\d+)(g|ml|kg|l)\1'), r'$1$2'), // 100g100g → 100g
    ];
    
    String result = value;
    for (final (pattern, replacement) in patterns) {
      result = result.replaceAll(pattern, replacement);
    }
    
    return result;
  }


  /// 代替案レスポンスをパース
  List<MealPlan> _parseAlternativesResponse(
    String response,
    String householdId,
    List<Ingredient> availableIngredients,
  ) {
    try {
      // 複数のJSONオブジェクトを抽出
      final alternatives = <MealPlan>[];
      final jsonPattern = RegExp(r'\{[^{}]*(?:\{[^{}]*\}[^{}]*)*\}');
      final matches = jsonPattern.allMatches(response);
      
      for (final match in matches.take(3)) { // 最大3つの代替案
        try {
          final jsonString = match.group(0)!;
          final jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
          
          final mainDish = _parseMealItem(jsonData['mainDish'] as Map<String, dynamic>, availableIngredients);
          final sideDish = _parseMealItem(jsonData['sideDish'] as Map<String, dynamic>, availableIngredients);
          final soup = _parseMealItem(jsonData['soup'] as Map<String, dynamic>, availableIngredients);
          final rice = _parseMealItem(jsonData['rice'] as Map<String, dynamic>, availableIngredients);
          
          final mealPlan = MealPlan(
            householdId: householdId,
            date: DateTime.now(),
            status: MealPlanStatus.suggested,
            mainDish: mainDish,
            sideDish: sideDish,
            soup: soup,
            rice: rice,
            totalCookingTime: jsonData['totalCookingTime'] as int? ?? 60,
            difficulty: DifficultyLevel.values.firstWhere(
              (e) => e.name == jsonData['difficulty'],
              orElse: () => DifficultyLevel.easy,
            ),
            nutritionScore: (jsonData['nutritionScore'] as num?)?.toDouble() ?? 80.0,
            confidence: (jsonData['confidence'] as num?)?.toDouble() ?? 0.8,
            createdAt: DateTime.now(),
            createdBy: 'ai_agent',
          );
          
          alternatives.add(mealPlan);
        } catch (e) {
          // 個別の代替案の解析に失敗した場合はスキップ
          continue;
        }
      }
      
      return alternatives;
    } catch (e) {
      throw Exception('代替献立データの解析に失敗しました: $e');
    }
  }

  /// 買い物リストを生成
  List<ShoppingItem> generateShoppingList(MealPlan mealPlan) {
    final shoppingItems = <ShoppingItem>[];
    
    // すべての材料を収集
    final allIngredients = [
      ...mealPlan.mainDish.ingredients,
      ...mealPlan.sideDish.ingredients,
      ...mealPlan.soup.ingredients,
      ...mealPlan.rice.ingredients,
    ];
    
    // 不足している材料を買い物リストに追加
    for (final ingredient in allIngredients) {
      if (ingredient.shoppingRequired) {
        final shoppingItem = ShoppingItem(
          name: ingredient.name,
          quantity: ingredient.quantity,
          unit: ingredient.unit,
          category: ingredient.category,
          isCustom: false,
          addedBy: 'ai_agent',
          addedAt: DateTime.now(),
          notes: ingredient.notes,
        );
        
        shoppingItems.add(shoppingItem);
      }
    }
    
    return shoppingItems;
  }
}
