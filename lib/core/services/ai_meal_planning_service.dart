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
      print('   AIレスポンス内容: ${response.text}');
      
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
食材: $ingredientsText
設定: ${preferences.maxCookingTime}分以内、${preferences.preferredDifficulty.name}レベル

冷蔵庫の食材を活用した具体的な料理名で献立を提案してください。調理法や調味料を含む料理名にしてください。

冷蔵庫にない食材は必ずshoppingListに含めてください。

JSON形式で回答（簡潔に）：

{
  "mainMenu": {
    "name": "豚こま肉と野菜の炒め物",
    "description": "豚こま肉と野菜を炒めた一品",
    "cookingTime": 20,
    "difficulty": "easy",
    "ingredients": [
      {"name": "豚こま肉", "quantity": 150, "unit": "g", "available": true, "priority": "urgent"},
      {"name": "玉ねぎ", "quantity": 0.5, "unit": "個", "available": true, "priority": "urgent"}
    ]
  },
  "alternativeMainDish": {
    "name": "鶏むね肉の照り焼き",
    "description": "鶏むね肉を照り焼きソースで焼いた一品",
    "cookingTime": 25,
    "difficulty": "easy",
    "ingredients": [
      {"name": "鶏むね肉", "quantity": 200, "unit": "g", "available": false, "priority": "fresh"}
    ]
  },
  "sideDish": {
    "name": "キャベツの塩昆布和え",
    "description": "キャベツを塩昆布で和えた副菜",
    "cookingTime": 10,
    "difficulty": "easy",
    "ingredients": [
      {"name": "キャベツ", "quantity": 0.25, "unit": "個", "available": true, "priority": "urgent"}
    ]
  },
  "alternativeSideDish": {
    "name": "じゃがいものバター炒め",
    "description": "じゃがいもをバターで炒めた副菜",
    "cookingTime": 15,
    "difficulty": "easy",
    "ingredients": [
      {"name": "じゃがいも", "quantity": 2, "unit": "個", "available": true, "priority": "urgent"}
    ]
  },
  "soup": {
    "name": "豆腐とわかめの味噌汁",
    "description": "豆腐とわかめを使った味噌汁",
    "cookingTime": 15,
    "difficulty": "easy",
    "ingredients": [
      {"name": "豆腐", "quantity": 0.5, "unit": "丁", "available": true, "priority": "urgent"}
    ]
  },
  "alternativeSoup": {
    "name": "野菜たっぷりコンソメスープ",
    "description": "野菜をたっぷり使ったコンソメスープ",
    "cookingTime": 20,
    "difficulty": "easy",
    "ingredients": [
      {"name": "にんじん", "quantity": 0.5, "unit": "本", "available": true, "priority": "urgent"}
    ]
  },
  "rice": {
    "name": "白米",
    "description": "炊きたての白米",
    "cookingTime": 45,
    "difficulty": "easy",
    "ingredients": [
      {"name": "米", "quantity": 2, "unit": "合", "available": false, "priority": "fresh"}
    ]
  },
  "alternativeRice": {
    "name": "チャーハン",
    "description": "野菜と卵を使ったチャーハン",
    "cookingTime": 20,
    "difficulty": "easy",
    "ingredients": [
      {"name": "ご飯", "quantity": 2, "unit": "合", "available": false, "priority": "fresh"}
    ]
  },
  "shoppingList": {
    "requiredIngredients": [
      {"name": "鶏むね肉", "quantity": 200, "unit": "g", "category": "肉", "estimatedCost": 300},
      {"name": "醤油", "quantity": 1, "unit": "本", "category": "調味料", "estimatedCost": 150},
      {"name": "みりん", "quantity": 1, "unit": "本", "category": "調味料", "estimatedCost": 200}
    ],
    "totalEstimatedCost": 650
  },
  "totalCookingTime": 45,
  "difficulty": "easy",
  "nutritionScore": 85,
  "confidence": 0.9
}

重要：
- 有効なJSON形式のみを返してください
- 具体的な料理名を提案してください
- 必ずshoppingListフィールドを含めてください
- 冷蔵庫にない食材は全てshoppingListに含めてください
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
      
      print('🔍 JSON解析対象文字列: $jsonString');

      // JSONが不完全な場合は修復を試みる
      if (!jsonString.trim().endsWith('}')) {
        print('⚠️ 不完全なJSONを検出、修復を試みます');
        jsonString = _repairIncompleteJson(jsonString);
        print('🔧 修復後のJSON: $jsonString');
      }

      // さらに詳細な修復を試みる
      jsonString = _advancedJsonRepair(jsonString);
      
      // confidenceフィールドの修復を試みる
      jsonString = _repairConfidenceField(jsonString);
      
      // 途中で切れたJSONレスポンスの修復を試みる
      jsonString = _repairTruncatedResponse(jsonString);

      Map<String, dynamic> jsonData;
      try {
        jsonData = jsonDecode(jsonString) as Map<String, dynamic>;
        print('✅ JSON解析成功: ${jsonData.keys}');
      } catch (e) {
        print('⚠️ JSON解析失敗、フォールバック機能を使用: $e');
        return _createFallbackMealPlan(householdId, availableIngredients);
      }

      // 新しい形式のメインメニューをパース
      final mainMenuData = jsonData['mainMenu'] as Map<String, dynamic>?;
      if (mainMenuData == null) {
        throw Exception('mainMenuデータが見つかりません');
      }
      final mainDish = _parseMainMenu(mainMenuData, availableIngredients);

      // 買い物リスト情報を取得
      final shoppingListData = jsonData['shoppingList'] as Map<String, dynamic>?;
      final shoppingList = _parseShoppingList(shoppingListData);

      // 冷蔵庫使用情報を取得
      final refrigeratorUsageData = jsonData['refrigeratorUsage'] as Map<String, dynamic>?;
      final refrigeratorUsage = _parseRefrigeratorUsage(refrigeratorUsageData);

      // 新しい形式から4品構成を解析（null安全性を追加）
      Map<String, dynamic>? sideDishData;
      Map<String, dynamic>? soupData;
      Map<String, dynamic>? riceData;

      // 代替メニューデータを解析
      Map<String, dynamic>? alternativeMainDishData;
      Map<String, dynamic>? alternativeSideDishData;
      Map<String, dynamic>? alternativeSoupData;
      Map<String, dynamic>? alternativeRiceData;

      try {
        sideDishData = _safeCastToMap(jsonData['sideDish'], 'sideDish');
        soupData = _safeCastToMap(jsonData['soup'], 'soup');
        riceData = _safeCastToMap(jsonData['rice'], 'rice');
        
        alternativeMainDishData = _safeCastToMap(jsonData['alternativeMainDish'], 'alternativeMainDish');
        alternativeSideDishData = _safeCastToMap(jsonData['alternativeSideDish'], 'alternativeSideDish');
        alternativeSoupData = _safeCastToMap(jsonData['alternativeSoup'], 'alternativeSoup');
        alternativeRiceData = _safeCastToMap(jsonData['alternativeRice'], 'alternativeRice');
      } catch (e) {
        print('⚠️ メニューデータの解析中にエラー: $e');
        // エラーが発生した場合はフォールバックに移行
        return _createFallbackMealPlan(householdId, availableIngredients);
      }

      print('🔍 副菜データ: $sideDishData');
      print('🔍 汁物データ: $soupData');
      print('🔍 主食データ: $riceData');
      print('🔍 代替主菜データ: $alternativeMainDishData');
      print('🔍 代替副菜データ: $alternativeSideDishData');
      print('🔍 代替汁物データ: $alternativeSoupData');
      print('🔍 代替主食データ: $alternativeRiceData');

      final sideDish = sideDishData != null
          ? _parseMealItem(sideDishData, availableIngredients, MealCategory.side)
          : _createSideDishFromMainMenu(mainMenuData);
      final soup = soupData != null
          ? _parseMealItem(soupData, availableIngredients, MealCategory.soup)
          : _createSoupFromMainMenu(mainMenuData);
      final rice = riceData != null
          ? _parseMealItem(riceData, availableIngredients, MealCategory.rice)
          : _createRiceFromMainMenu(mainMenuData);

      // 代替メニューをパース
      final alternativeMainDish = alternativeMainDishData != null
          ? _parseMealItem(alternativeMainDishData, availableIngredients, MealCategory.main)
          : null;
      final alternativeSideDish = alternativeSideDishData != null
          ? _parseMealItem(alternativeSideDishData, availableIngredients, MealCategory.side)
          : null;
      final alternativeSoup = alternativeSoupData != null
          ? _parseMealItem(alternativeSoupData, availableIngredients, MealCategory.soup)
          : null;
      final alternativeRice = alternativeRiceData != null
          ? _parseMealItem(alternativeRiceData, availableIngredients, MealCategory.rice)
          : null;
      
      return MealPlan(
        householdId: householdId,
        date: DateTime.now(),
        status: MealPlanStatus.suggested,
        mainDish: mainDish,
        sideDish: sideDish,
        soup: soup,
        rice: rice,
        alternativeMainDish: alternativeMainDish,
        alternativeSideDish: alternativeSideDish,
        alternativeSoup: alternativeSoup,
        alternativeRice: alternativeRice,
        totalCookingTime: jsonData['totalCookingTime'] as int? ?? 60,
        difficulty: DifficultyLevel.values.firstWhere(
          (e) => e.name == jsonData['difficulty'],
          orElse: () => DifficultyLevel.easy,
        ),
        nutritionScore: (jsonData['nutritionScore'] as num?)?.toDouble() ?? 80.0,
        confidence: (jsonData['confidence'] as num?)?.toDouble() ?? 0.8,
        createdAt: DateTime.now(),
        createdBy: 'ai_agent',
        // 新しいフィールドを追加（後でMealPlanモデルを拡張）
        shoppingList: shoppingList,
        popularityScore: mainMenuData['popularityScore'] as int? ?? 5,
        cookingFrequency: mainMenuData['cookingFrequency'] as String? ?? 'monthly',
        seasonalRelevance: mainMenuData['seasonalRelevance'] as String? ?? 'all',
        refrigeratorUsage: refrigeratorUsage,
      );
    } catch (e) {
      print('❌ JSON解析詳細エラー: $e');
      print('❌ 解析対象のレスポンス（最初の500文字）: ${response.substring(0, response.length > 500 ? 500 : response.length)}');
      throw Exception('献立データの解析に失敗しました: $e');
    }
  }

  /// メインメニューをパース
  MealItem _parseMainMenu(Map<String, dynamic> data, List<Ingredient> availableIngredients) {
    final ingredients = (data['ingredients'] as List<dynamic>)
        .map((ingredientData) => _parseIngredient(ingredientData as Map<String, dynamic>, availableIngredients))
        .toList();
    
    final recipeData = data['recipe'] as Map<String, dynamic>?;
    final recipe = Recipe(
      steps: recipeData != null ? (recipeData['steps'] as List<dynamic>?)
          ?.asMap()
          .entries
          .map((entry) => RecipeStep(
                stepNumber: entry.key + 1,
                description: entry.value as String,
              ))
          .toList() ?? [] : [],
      cookingTime: data['cookingTime'] as int? ?? 30,
      prepTime: 10, // デフォルト値
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      tips: recipeData != null ? (recipeData['tips'] as List<dynamic>?)?.cast<String>() ?? [] : [],
      servingSize: 4, // デフォルト値
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>?),
    );
    
    return MealItem(
      name: data['name'] as String,
      category: MealCategory.main,
      description: data['description'] as String? ?? '',
      ingredients: ingredients,
      recipe: recipe,
      cookingTime: data['cookingTime'] as int? ?? 30,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>?),
      createdAt: DateTime.now(),
    );
  }

  /// 買い物リストをパース
  List<ShoppingItem> _parseShoppingList(Map<String, dynamic>? data) {
    if (data == null) return [];

    final requiredIngredients = data['requiredIngredients'] as List<dynamic>? ?? [];
    return requiredIngredients.map((item) {
      final itemData = item as Map<String, dynamic>;
      final quantityRaw = itemData['quantity'];
      final quantity = quantityRaw is String ? quantityRaw : quantityRaw.toString();
      return ShoppingItem(
        name: itemData['name'] as String,
        quantity: quantity,
        unit: itemData['unit'] as String,
        category: itemData['category'] as String,
        isCustom: false,
        addedBy: 'ai_agent',
        addedAt: DateTime.now(),
        notes: '概算費用: ${itemData['estimatedCost']}円',
      );
    }).toList();
  }

  /// 冷蔵庫使用情報をパース
  Map<String, dynamic> _parseRefrigeratorUsage(Map<String, dynamic>? data) {
    if (data == null) return {};

    return {
      'usedIngredients': data['usedIngredients'] as List<dynamic>? ?? [],
      'wasteReduction': data['wasteReduction'] as String? ?? '',
    };
  }

  /// メインメニューから副菜を作成（後方互換性のため）
  MealItem _createSideDishFromMainMenu(Map<String, dynamic> mainMenuData) {
    final mainDishName = mainMenuData['name'] as String? ?? '料理';
    final sideDishName = _generateSideDishName(mainDishName);
    final sideDishDescription = _generateSideDishDescription(mainDishName);
    return MealItem(
      name: sideDishName,
      category: MealCategory.side,
      description: sideDishDescription,
      ingredients: _generateSideDishIngredients(mainDishName),
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '材料を準備する'),
          RecipeStep(stepNumber: 2, description: '$sideDishNameを作る'),
        ],
        cookingTime: 10,
        prepTime: 5,
        difficulty: DifficultyLevel.easy,
        tips: ['メインメニューとのバランスを考えて味付けする'],
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: 10,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// メインメニューから汁物を作成（後方互換性のため）
  MealItem _createSoupFromMainMenu(Map<String, dynamic> mainMenuData) {
    final mainDishName = mainMenuData['name'] as String? ?? '料理';
    final soupName = _generateSoupName(mainDishName);
    final soupDescription = _generateSoupDescription(mainDishName);
    return MealItem(
      name: soupName,
      category: MealCategory.soup,
      description: soupDescription,
      ingredients: _generateSoupIngredients(mainDishName),
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '出汁を準備する'),
          RecipeStep(stepNumber: 2, description: '$soupNameを作る'),
        ],
        cookingTime: 15,
        prepTime: 5,
        difficulty: DifficultyLevel.easy,
        tips: ['メインメニューに合う味付けにする'],
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: 15,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// メインメニューから主食を作成（後方互換性のため）
  MealItem _createRiceFromMainMenu(Map<String, dynamic> mainMenuData) {
    return MealItem(
      name: 'ご飯',
      category: MealCategory.rice,
      description: '白米',
      ingredients: [
        Ingredient(
          name: '米',
          quantity: '2合',
          unit: '合',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '主食',
        ),
      ],
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '米を研ぐ'),
          RecipeStep(stepNumber: 2, description: '炊飯器で炊く'),
        ],
        cookingTime: 45,
        prepTime: 5,
        difficulty: DifficultyLevel.easy,
        tips: ['水加減を適切にする'],
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: 45,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );
  }

  /// メニューアイテムをパース（従来の形式用）
  MealItem _parseMealItem(Map<String, dynamic> data, List<Ingredient> availableIngredients, [MealCategory? category]) {
    final ingredients = (data['ingredients'] as List<dynamic>)
        .map((ingredientData) => _parseIngredient(ingredientData as Map<String, dynamic>, availableIngredients))
        .toList();

    final recipeData = data['recipe'] as Map<String, dynamic>?;
    final recipe = Recipe(
      steps: recipeData != null ? (recipeData['steps'] as List<dynamic>?)
          ?.asMap()
          .entries
          .map((entry) => RecipeStep(
                stepNumber: entry.key + 1,
                description: entry.value as String,
              ))
          .toList() ?? [] : [],
      cookingTime: data['cookingTime'] as int? ?? 30,
      prepTime: 10, // デフォルト値
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      tips: recipeData != null ? (recipeData['tips'] as List<dynamic>?)?.cast<String>() ?? [] : [],
      servingSize: 4, // デフォルト値
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>?),
    );

    return MealItem(
      name: data['name'] as String,
      category: category ?? MealCategory.main, // 指定されたカテゴリまたはデフォルト値
      description: data['description'] as String? ?? '',
      ingredients: ingredients,
      recipe: recipe,
      cookingTime: data['cookingTime'] as int? ?? 30,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionInfo: _parseNutritionInfo(data['nutritionInfo'] as Map<String, dynamic>?),
      createdAt: DateTime.now(),
    );
  }

  /// 材料をパース
  Ingredient _parseIngredient(Map<String, dynamic> data, List<Ingredient> availableIngredients) {
    final name = data['name'] as String;
    final available = data['available'] as bool? ?? true;
    final quantityRaw = data['quantity'];
    final quantity = quantityRaw is String ? quantityRaw : quantityRaw.toString();
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
  NutritionInfo _parseNutritionInfo(Map<String, dynamic>? data) {
    if (data == null) return NutritionInfo.empty();
    
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

  /// 不完全なJSONを修復する
  String _repairIncompleteJson(String incompleteJson) {
    try {
      String repaired = incompleteJson.trim();

      // 基本的な修復: 閉じ括弧を追加
      int openBraces = '{'.allMatches(repaired).length;
      int closeBraces = '}'.allMatches(repaired).length;

      while (closeBraces < openBraces) {
        repaired += '}';
        closeBraces++;
      }

      // 配列の閉じ括弧も修復
      int openBrackets = '['.allMatches(repaired).length;
      int closeBrackets = ']'.allMatches(repaired).length;

      while (closeBrackets < openBrackets) {
        repaired += ']';
        closeBrackets++;
      }

      // 最後のカンマを削除
      repaired = repaired.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

      return repaired;
    } catch (e) {
      print('⚠️ JSON修復に失敗: $e');
      return incompleteJson;
    }
  }

  /// 高度なJSON修復
  String _advancedJsonRepair(String jsonString) {
    try {
      String repaired = jsonString;

      // 不完全な文字列を修復
      repaired = _repairIncompleteStrings(repaired);

      // 不完全な配列を修復
      repaired = _repairIncompleteArrays(repaired);

      // 不完全なオブジェクトを修復
      repaired = _repairIncompleteObjects(repaired);

      return repaired;
    } catch (e) {
      print('⚠️ 高度なJSON修復に失敗: $e');
      return jsonString;
    }
  }

  /// 不完全な文字列を修復
  String _repairIncompleteStrings(String json) {
    // 不完全なクォーテーションを修復
    String repaired = json;

    // 不完全な文字列のパターンを検出して修復
    final incompleteStringPattern = RegExp(r'"([^"]*?)$');
    if (incompleteStringPattern.hasMatch(repaired)) {
      repaired = repaired.replaceFirst(incompleteStringPattern, r'"$1"');
    }

    // 不完全なキーの修復
    final incompleteKeyPattern = RegExp(r'(\w+)\s*:\s*([^"]*?)$');
    if (incompleteKeyPattern.hasMatch(repaired)) {
      repaired = repaired.replaceFirst(incompleteKeyPattern, r'"$1": "$2"');
    }

    return repaired;
  }

  /// 不完全な配列を修復
  String _repairIncompleteArrays(String json) {
    String repaired = json;

    // 不完全な配列要素を修復
    final incompleteArrayPattern = RegExp(r',\s*$');
    if (incompleteArrayPattern.hasMatch(repaired)) {
      repaired = repaired.replaceFirst(incompleteArrayPattern, '');
    }

    // 不完全なオブジェクト要素を修復
    final incompleteObjectPattern = RegExp(r',\s*"([^"]*?)":\s*([^"]*?)$');
    if (incompleteObjectPattern.hasMatch(repaired)) {
      repaired = repaired.replaceFirst(incompleteObjectPattern, r', "$1": "$2"');
    }

    return repaired;
  }

  /// 不完全なオブジェクトを修復
  String _repairIncompleteObjects(String json) {
    String repaired = json;

    // 最後のカンマを削除
    repaired = repaired.replaceAll(RegExp(r',(\s*[}\]])'), r'$1');

    // 不完全なオブジェクトの閉じ括弧を追加
    int braceCount = 0;
    int bracketCount = 0;
    bool inString = false;
    bool escaped = false;

    for (int i = 0; i < repaired.length; i++) {
      final char = repaired[i];

      if (escaped) {
        escaped = false;
        continue;
      }

      if (char == '\\') {
        escaped = true;
        continue;
      }

      if (char == '"') {
        inString = !inString;
        continue;
      }

      if (!inString) {
        if (char == '{') braceCount++;
        else if (char == '}') braceCount--;
        else if (char == '[') bracketCount++;
        else if (char == ']') bracketCount--;
      }
    }

    // 不足している閉じ括弧を追加
    while (braceCount > 0) {
      repaired += '}';
      braceCount--;
    }

    while (bracketCount > 0) {
      repaired += ']';
      bracketCount--;
    }

    return repaired;
  }

  /// 安全な型キャスト（Map<String, dynamic>?への変換）
  Map<String, dynamic>? _safeCastToMap(dynamic value, String fieldName) {
    try {
      if (value == null) {
        print('🔍 $fieldName: null');
        return null;
      }
      
      if (value is Map<String, dynamic>) {
        print('🔍 $fieldName: Map型で正常');
        return value;
      }
      
      if (value is Map) {
        print('🔍 $fieldName: Map型をMap<String, dynamic>に変換');
        return Map<String, dynamic>.from(value);
      }
      
      print('⚠️ $fieldName: 予期しない型 ${value.runtimeType}, 値: $value');
      return null;
    } catch (e) {
      print('❌ $fieldName: 型キャストエラー - $e');
      return null;
    }
  }

  /// confidenceフィールドの修復
  String _repairConfidenceField(String jsonString) {
    try {
      String repaired = jsonString;
      
      // confidenceフィールドの不正な形式を修復
      // "confidence"$1"} → "confidence": 0.8}
      final confidencePattern = RegExp(r'"confidence"\$?\d*"?\}?$');
      if (confidencePattern.hasMatch(repaired)) {
        repaired = repaired.replaceFirst(confidencePattern, '"confidence": 0.8}');
        print('🔧 confidenceフィールドを修復しました');
      }
      
      // 不完全なconfidenceフィールドを修復
      final incompleteConfidencePattern = RegExp(r'"confidence":\s*[^,}\d]*$');
      if (incompleteConfidencePattern.hasMatch(repaired)) {
        repaired = repaired.replaceFirst(incompleteConfidencePattern, '"confidence": 0.8');
        print('🔧 不完全なconfidenceフィールドを修復しました');
      }
      
      return repaired;
    } catch (e) {
      print('⚠️ confidenceフィールド修復に失敗: $e');
      return jsonString;
    }
  }

  /// 途中で切れたJSONレスポンスの修復
  String _repairTruncatedResponse(String jsonString) {
    try {
      String repaired = jsonString;
      print('🔍 レスポンス修復開始: ${repaired.length}文字');
      
      // 1. quantityフィールドの修復（文字列を数値に変換）
      repaired = repaired.replaceAllMapped(
        RegExp(r'"quantity":\s*"([0-9.]+)"'),
        (match) => '"quantity": ${match.group(1)}',
      );
      
      // 1.5. フィールドが入れ替わっている問題の修復
      repaired = repaired.replaceAllMapped(
        RegExp(r'"quantity":\s*([^,}]+),\s*"unit":\s*"([^"]+)"'),
        (match) {
          final quantity = match.group(1)?.trim();
          final unit = match.group(2)?.trim();
          // 数値かどうかチェック
          if (quantity != null && RegExp(r'^[0-9.]+$').hasMatch(quantity)) {
            return '"quantity": $quantity, "unit": "$unit"';
          } else {
            return '"quantity": 1, "unit": "$quantity"';
          }
        },
      );
      
      // 2. 不完全なフィールドの修復パターン
      final quantityPatterns = [
        RegExp(r'"quantity":\s*"大さじ[0-9]+"'),
        RegExp(r'"quantity":\s*"小さじ[0-9]+"'),
        RegExp(r'"quantity":\s*"小$'),
      ];
      
      for (final pattern in quantityPatterns) {
        if (pattern.hasMatch(repaired)) {
          repaired = repaired.replaceFirst(pattern, '"quantity": 1');
          print('🔧 quantityフィールドを修復しました');
        }
      }
      
      // unitフィールドの修復
      if (RegExp(r'"unit":\s*""').hasMatch(repaired)) {
        repaired = repaired.replaceFirst(RegExp(r'"unit":\s*""'), '"unit": "大さじ"');
        print('🔧 unitフィールドを修復しました');
      }
      
      // priorityフィールドの修復
      final priorityPatterns = [
        RegExp(r'"priority":\s*"fre$'),
        RegExp(r'"priority":\s*"fresh$'),
      ];
      
      for (final pattern in priorityPatterns) {
        if (pattern.hasMatch(repaired)) {
          repaired = repaired.replaceFirst(pattern, '"priority": "fresh"');
          print('🔧 priorityフィールドを修復しました');
        }
      }
      
      // 3. 不完全な配列の修復
      if (repaired.contains('"ingredients": [') && !repaired.contains(']')) {
        // 最後の不完全なオブジェクトを修復
        repaired = repaired.replaceAll(RegExp(r',\s*$'), '');
        repaired = repaired + ']';
        print('🔧 不完全なingredients配列を修復しました');
      }
      
      // 4. 不完全なオブジェクトの修復
      if (repaired.contains('{') && !repaired.endsWith('}')) {
        // 最後のカンマを削除
        repaired = repaired.replaceAll(RegExp(r',\s*$'), '');
        
        // 不完全なオブジェクトを閉じる
        int openBraces = repaired.split('{').length - 1;
        int closeBraces = repaired.split('}').length - 1;
        int missingBraces = openBraces - closeBraces;
        
        for (int i = 0; i < missingBraces; i++) {
          repaired = repaired + '}';
        }
        print('🔧 不完全なオブジェクトを修復しました（$missingBraces個の閉じ括弧を追加）');
      }
      
      // 5. 最終的なJSON構造の修復
      if (!repaired.trim().endsWith('}')) {
        repaired = repaired.trim() + '}';
        print('🔧 最終的なJSON構造を修復しました');
      }
      
      print('✅ レスポンス修復完了: ${repaired.length}文字');
      return repaired;
    } catch (e) {
      print('⚠️ 途中切れレスポンス修復に失敗: $e');
      return jsonString;
    }
  }

  /// フォールバック用の献立を作成
  MealPlan _createFallbackMealPlan(String householdId, List<Ingredient> availableIngredients) {
    print('🔄 フォールバック献立を作成中...');

    // 利用可能な食材から簡単な献立を作成
    final urgentIngredients = availableIngredients
        .where((ingredient) => ingredient.priority == ExpiryPriority.urgent)
        .take(3)
        .toList();

    final mainDishName = urgentIngredients.isNotEmpty
        ? '${urgentIngredients.first.name}の炒め物'
        : '野菜炒め';

    final mainDish = MealItem(
      name: mainDishName,
      category: MealCategory.main,
      description: '冷蔵庫の食材を活用した簡単な炒め物',
      ingredients: urgentIngredients.take(3).map((ingredient) => Ingredient(
        name: ingredient.name,
        quantity: '適量',
        unit: '',
        available: true,
        expiryDate: ingredient.expiryDate,
        shoppingRequired: false,
        productId: ingredient.productId,
        priority: ingredient.priority,
        category: ingredient.category,
      )).toList(),
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '材料を切る'),
          RecipeStep(stepNumber: 2, description: 'フライパンで炒める'),
          RecipeStep(stepNumber: 3, description: '調味料で味付け'),
        ],
        cookingTime: 20,
        prepTime: 10,
        difficulty: DifficultyLevel.easy,
        tips: ['強火で手早く炒める'],
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: 20,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );

    // 代替主菜も同様に作成
    final alternativeMainDish = MealItem(
      name: '${urgentIngredients.isNotEmpty ? urgentIngredients.first.name : '野菜'}の煮物',
      category: MealCategory.main,
      description: '代替としての煮物',
      ingredients: urgentIngredients.take(2).map((ingredient) => Ingredient(
        name: ingredient.name,
        quantity: '適量',
        unit: '',
        available: true,
        expiryDate: ingredient.expiryDate,
        shoppingRequired: false,
        productId: ingredient.productId,
        priority: ingredient.priority,
        category: ingredient.category,
      )).toList(),
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '材料を切る'),
          RecipeStep(stepNumber: 2, description: '煮汁で煮る'),
        ],
        cookingTime: 25,
        prepTime: 10,
        difficulty: DifficultyLevel.easy,
        tips: ['弱火でじっくり煮る'],
        servingSize: 4,
        nutritionInfo: NutritionInfo.empty(),
      ),
      cookingTime: 25,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo.empty(),
      createdAt: DateTime.now(),
    );

    // 副菜、汁物、主食も作成
    final sideDish = _createSideDishFromMainMenu({'name': mainDishName});
    final alternativeSideDish = _createSideDishFromMainMenu({'name': '代替副菜'});
    final soup = _createSoupFromMainMenu({'name': mainDishName});
    final alternativeSoup = _createSoupFromMainMenu({'name': '代替汁物'});
    final rice = _createRiceFromMainMenu({'name': mainDishName});
    final alternativeRice = _createRiceFromMainMenu({'name': '代替主食'});

    // 基本的な買い物リストを作成
    final shoppingList = <ShoppingItem>[
      ShoppingItem(
        name: '醤油',
        quantity: '1',
        unit: '本',
        category: '調味料',
        isCustom: false,
        addedBy: 'fallback_system',
        addedAt: DateTime.now(),
        notes: '概算費用: 150円',
      ),
      ShoppingItem(
        name: '塩',
        quantity: '1',
        unit: 'パック',
        category: '調味料',
        isCustom: false,
        addedBy: 'fallback_system',
        addedAt: DateTime.now(),
        notes: '概算費用: 100円',
      ),
    ];

    return MealPlan(
      householdId: householdId,
      date: DateTime.now(),
      status: MealPlanStatus.suggested,
      mainDish: mainDish,
      sideDish: sideDish,
      soup: soup,
      rice: rice,
      alternativeMainDish: alternativeMainDish,
      alternativeSideDish: alternativeSideDish,
      alternativeSoup: alternativeSoup,
      alternativeRice: alternativeRice,
      totalCookingTime: 45,
      difficulty: DifficultyLevel.easy,
      nutritionScore: 70.0,
      confidence: 0.6,
      createdAt: DateTime.now(),
      createdBy: 'fallback_system',
      shoppingList: shoppingList,
    );
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
          
          final mainDish = _parseMealItem(jsonData['mainDish'] as Map<String, dynamic>, availableIngredients, MealCategory.main);
          final sideDish = _parseMealItem(jsonData['sideDish'] as Map<String, dynamic>, availableIngredients, MealCategory.side);
          final soup = _parseMealItem(jsonData['soup'] as Map<String, dynamic>, availableIngredients, MealCategory.soup);
          final rice = _parseMealItem(jsonData['rice'] as Map<String, dynamic>, availableIngredients, MealCategory.rice);
          
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

  /// メインメニューに合わせた副菜名を生成
  String _generateSideDishName(String mainDishName) {
    final mainDishLower = mainDishName.toLowerCase();
    if (mainDishLower.contains('炒め') || mainDishLower.contains('焼き')) {
      return 'キャベツとコーンのサラダ';
    } else if (mainDishLower.contains('煮') || mainDishLower.contains('煮物')) {
      return 'ほうれん草のお浸し';
    } else if (mainDishLower.contains('カレー')) {
      return 'らっきょうとピクルス';
    } else if (mainDishLower.contains('豚') || mainDishLower.contains('肉')) {
      return '千切りキャベツ';
    } else if (mainDishLower.contains('魚') || mainDishLower.contains('鮭') || mainDishLower.contains('鯖')) {
      return '大根おろし';
    } else if (mainDishLower.contains('揚げ') || mainDishLower.contains('フライ')) {
      return 'レタスとトマトのサラダ';
    } else {
      return '季節野菜のサラダ';
    }
  }

  /// メインメニューに合わせた副菜の説明を生成
  String _generateSideDishDescription(String mainDishName) {
    final sideDishName = _generateSideDishName(mainDishName);
    return '$mainDishNameに合わせた$sideDishName。栄養バランスを整える一品です。';
  }

  /// メインメニューに合わせた汁物名を生成
  String _generateSoupName(String mainDishName) {
    final mainDishLower = mainDishName.toLowerCase();
    if (mainDishLower.contains('炒め') || mainDishLower.contains('中華')) {
      return 'わかめスープ';
    } else if (mainDishLower.contains('カレー')) {
      return 'コンソメスープ';
    } else if (mainDishLower.contains('洋') || mainDishLower.contains('パスタ') || mainDishLower.contains('グラタン')) {
      return 'オニオンスープ';
    } else if (mainDishLower.contains('魚') || mainDishLower.contains('鮭') || mainDishLower.contains('鯖')) {
      return 'あさりの味噌汁';
    } else if (mainDishLower.contains('豚') || mainDishLower.contains('肉')) {
      return '豆腐とわかめの味噌汁';
    } else {
      return '野菜の味噌汁';
    }
  }

  /// メインメニューに合わせた汁物の説明を生成
  String _generateSoupDescription(String mainDishName) {
    final soupName = _generateSoupName(mainDishName);
    return '$mainDishNameと相性の良い$soupName。体を温める優しい味わいです。';
  }

  /// 副菜の材料を生成
  List<Ingredient> _generateSideDishIngredients(String mainDishName) {
    final sideDishName = _generateSideDishName(mainDishName);
    if (sideDishName.contains('サラダ')) {
      return [
        Ingredient(
          name: 'レタス',
          quantity: '1/2',
          unit: '個',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '野菜',
        ),
        Ingredient(
          name: 'トマト',
          quantity: '1',
          unit: '個',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '野菜',
        ),
      ];
    } else if (sideDishName.contains('お浸し')) {
      return [
        Ingredient(
          name: 'ほうれん草',
          quantity: '1',
          unit: '束',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '野菜',
        ),
      ];
    } else {
      return [
        Ingredient(
          name: 'キャベツ',
          quantity: '1/4',
          unit: '個',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '野菜',
        ),
      ];
    }
  }

  /// 汁物の材料を生成
  List<Ingredient> _generateSoupIngredients(String mainDishName) {
    final soupName = _generateSoupName(mainDishName);
    if (soupName.contains('味噌汁')) {
      return [
        Ingredient(
          name: '味噌',
          quantity: '大さじ2',
          unit: '',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.longTerm,
          category: '調味料',
        ),
        Ingredient(
          name: '豆腐',
          quantity: '1/2',
          unit: '丁',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.soon,
          category: '豆製品',
        ),
        Ingredient(
          name: 'わかめ',
          quantity: '適量',
          unit: '',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.longTerm,
          category: '海藻',
        ),
      ];
    } else if (soupName.contains('コンソメ') || soupName.contains('オニオン')) {
      return [
        Ingredient(
          name: 'コンソメ',
          quantity: '1',
          unit: '個',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.longTerm,
          category: '調味料',
        ),
        Ingredient(
          name: '玉ねぎ',
          quantity: '1',
          unit: '個',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.fresh,
          category: '野菜',
        ),
      ];
    } else {
      return [
        Ingredient(
          name: 'わかめ',
          quantity: '適量',
          unit: '',
          available: false,
          shoppingRequired: true,
          priority: ExpiryPriority.longTerm,
          category: '海藻',
        ),
      ];
    }
  }
}
