import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// 献立の状態を表す列挙型
enum MealPlanStatus {
  suggested,  // 提案中
  accepted,   // 承認済み
  cooking,    // 調理中
  completed,  // 完了
  cancelled,  // キャンセル
}

/// メニューのカテゴリを表す列挙型
enum MealCategory {
  main,      // 主菜
  side,      // 副菜
  soup,      // 汁物
  rice,      // 主食
  dessert,   // デザート
  beverage,  // 飲み物
}

/// 難易度レベルを表す列挙型
enum DifficultyLevel {
  easy,      // 簡単
  medium,    // 普通
  hard,      // 難しい
  expert,    // 上級
}

/// 賞味期限の優先度を表す列挙型
enum ExpiryPriority {
  urgent,     // 緊急（1日以内）
  soon,       // 近い（3日以内）
  fresh,      // 新鮮（7日以内）
  longTerm,   // 長期（7日以上）
}

/// 献立のメインモデル
class MealPlan {
  final String? id;
  final String householdId;
  final DateTime date;
  final MealPlanStatus status;
  final MealItem mainDish;
  final MealItem sideDish;
  final MealItem soup;
  final MealItem rice;
  final int totalCookingTime;
  final DifficultyLevel difficulty;
  final double nutritionScore;
  final double confidence;
  final List<MealPlan> alternatives;
  final DateTime createdAt;
  final String createdBy;
  final DateTime? acceptedAt;
  final DateTime? completedAt;

  MealPlan({
    this.id,
    required this.householdId,
    required this.date,
    required this.status,
    required this.mainDish,
    required this.sideDish,
    required this.soup,
    required this.rice,
    required this.totalCookingTime,
    required this.difficulty,
    required this.nutritionScore,
    required this.confidence,
    this.alternatives = const [],
    required this.createdAt,
    required this.createdBy,
    this.acceptedAt,
    this.completedAt,
  });

  /// 献立が完了しているかどうか
  bool get isComplete => status == MealPlanStatus.completed;

  /// 総カロリーを計算
  double get totalCalories {
    return mainDish.nutritionInfo.calories +
           sideDish.nutritionInfo.calories +
           soup.nutritionInfo.calories +
           rice.nutritionInfo.calories;
  }

  /// 不足している材料のリスト
  List<Ingredient> get missingIngredients {
    final allIngredients = [
      ...mainDish.ingredients,
      ...sideDish.ingredients,
      ...soup.ingredients,
      ...rice.ingredients,
    ];
    return allIngredients.where((ingredient) => !ingredient.available).toList();
  }

  /// 全ての材料のリスト
  List<Ingredient> get allIngredients {
    return [
      ...mainDish.ingredients,
      ...sideDish.ingredients,
      ...soup.ingredients,
      ...rice.ingredients,
    ];
  }

  /// 賞味期限が近い材料のリスト
  List<Ingredient> get expiringIngredients {
    return allIngredients.where((ingredient) => 
      ingredient.available && ingredient.priority == ExpiryPriority.urgent
    ).toList();
  }

  /// 献立の表示名
  String get displayName {
    return '${mainDish.name}、${sideDish.name}、${soup.name}、${rice.name}';
  }

  /// 難易度の表示名
  String get difficultyDisplayName {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return '簡単';
      case DifficultyLevel.medium:
        return '普通';
      case DifficultyLevel.hard:
        return '難しい';
      case DifficultyLevel.expert:
        return '上級';
    }
  }

  /// 状態の表示名
  String get statusDisplayName {
    switch (status) {
      case MealPlanStatus.suggested:
        return '提案中';
      case MealPlanStatus.accepted:
        return '承認済み';
      case MealPlanStatus.cooking:
        return '調理中';
      case MealPlanStatus.completed:
        return '完了';
      case MealPlanStatus.cancelled:
        return 'キャンセル';
    }
  }

  /// 状態の色
  Color get statusColor {
    switch (status) {
      case MealPlanStatus.suggested:
        return Colors.blue;
      case MealPlanStatus.accepted:
        return Colors.green;
      case MealPlanStatus.cooking:
        return Colors.orange;
      case MealPlanStatus.completed:
        return Colors.grey;
      case MealPlanStatus.cancelled:
        return Colors.red;
    }
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'householdId': householdId,
      'date': Timestamp.fromDate(date),
      'status': status.name,
      'mainDish': mainDish.toFirestore(),
      'sideDish': sideDish.toFirestore(),
      'soup': soup.toFirestore(),
      'rice': rice.toFirestore(),
      'totalCookingTime': totalCookingTime,
      'difficulty': difficulty.name,
      'nutritionScore': nutritionScore,
      'confidence': confidence,
      'alternatives': alternatives.map((alt) => alt.toFirestore()).toList(),
      'createdAt': Timestamp.fromDate(createdAt),
      'createdBy': createdBy,
      'acceptedAt': acceptedAt != null ? Timestamp.fromDate(acceptedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  static MealPlan fromFirestore(String id, Map<String, dynamic> data) {
    return MealPlan(
      id: id,
      householdId: data['householdId'] as String,
      date: (data['date'] as Timestamp).toDate(),
      status: MealPlanStatus.values.firstWhere(
        (e) => e.name == data['status'],
        orElse: () => MealPlanStatus.suggested,
      ),
      mainDish: MealItem.fromFirestore(data['mainDish'] as Map<String, dynamic>),
      sideDish: MealItem.fromFirestore(data['sideDish'] as Map<String, dynamic>),
      soup: MealItem.fromFirestore(data['soup'] as Map<String, dynamic>),
      rice: MealItem.fromFirestore(data['rice'] as Map<String, dynamic>),
      totalCookingTime: data['totalCookingTime'] as int,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      nutritionScore: (data['nutritionScore'] as num).toDouble(),
      confidence: (data['confidence'] as num).toDouble(),
      alternatives: (data['alternatives'] as List<dynamic>?)
          ?.map((alt) => MealPlan.fromFirestore('', alt as Map<String, dynamic>))
          .toList() ?? [],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      createdBy: data['createdBy'] as String,
      acceptedAt: data['acceptedAt'] != null 
          ? (data['acceptedAt'] as Timestamp).toDate() 
          : null,
      completedAt: data['completedAt'] != null 
          ? (data['completedAt'] as Timestamp).toDate() 
          : null,
    );
  }

  MealPlan copyWith({
    String? id,
    String? householdId,
    DateTime? date,
    MealPlanStatus? status,
    MealItem? mainDish,
    MealItem? sideDish,
    MealItem? soup,
    MealItem? rice,
    int? totalCookingTime,
    DifficultyLevel? difficulty,
    double? nutritionScore,
    double? confidence,
    List<MealPlan>? alternatives,
    DateTime? createdAt,
    String? createdBy,
    DateTime? acceptedAt,
    DateTime? completedAt,
  }) {
    return MealPlan(
      id: id ?? this.id,
      householdId: householdId ?? this.householdId,
      date: date ?? this.date,
      status: status ?? this.status,
      mainDish: mainDish ?? this.mainDish,
      sideDish: sideDish ?? this.sideDish,
      soup: soup ?? this.soup,
      rice: rice ?? this.rice,
      totalCookingTime: totalCookingTime ?? this.totalCookingTime,
      difficulty: difficulty ?? this.difficulty,
      nutritionScore: nutritionScore ?? this.nutritionScore,
      confidence: confidence ?? this.confidence,
      alternatives: alternatives ?? this.alternatives,
      createdAt: createdAt ?? this.createdAt,
      createdBy: createdBy ?? this.createdBy,
      acceptedAt: acceptedAt ?? this.acceptedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}

/// メニューアイテムのモデル
class MealItem {
  final String? id;
  final String name;
  final MealCategory category;
  final String description;
  final List<Ingredient> ingredients;
  final Recipe recipe;
  final int cookingTime;
  final DifficultyLevel difficulty;
  final String? imageUrl;
  final NutritionInfo nutritionInfo;
  final List<String> tags;
  final double rating;
  final DateTime createdAt;

  MealItem({
    this.id,
    required this.name,
    required this.category,
    required this.description,
    required this.ingredients,
    required this.recipe,
    required this.cookingTime,
    required this.difficulty,
    this.imageUrl,
    required this.nutritionInfo,
    this.tags = const [],
    this.rating = 0.0,
    required this.createdAt,
  });

  /// 利用可能かどうか（すべての材料が在庫にあるか）
  bool get isAvailable {
    return ingredients.every((ingredient) => ingredient.available);
  }

  /// 不足している材料のリスト
  List<Ingredient> get missingIngredients {
    return ingredients.where((ingredient) => !ingredient.available).toList();
  }

  /// 賞味期限が近い材料のリスト
  List<Ingredient> get expiringIngredients {
    return ingredients.where((ingredient) => 
      ingredient.available && ingredient.priority == ExpiryPriority.urgent
    ).toList();
  }

  /// カテゴリの表示名
  String get categoryDisplayName {
    switch (category) {
      case MealCategory.main:
        return '主菜';
      case MealCategory.side:
        return '副菜';
      case MealCategory.soup:
        return '汁物';
      case MealCategory.rice:
        return '主食';
      case MealCategory.dessert:
        return 'デザート';
      case MealCategory.beverage:
        return '飲み物';
    }
  }

  /// 難易度の表示名
  String get difficultyDisplayName {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return '簡単';
      case DifficultyLevel.medium:
        return '普通';
      case DifficultyLevel.hard:
        return '難しい';
      case DifficultyLevel.expert:
        return '上級';
    }
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'category': category.name,
      'description': description,
      'ingredients': ingredients.map((ingredient) => ingredient.toFirestore()).toList(),
      'recipe': recipe.toFirestore(),
      'cookingTime': cookingTime,
      'difficulty': difficulty.name,
      'imageUrl': imageUrl,
      'nutritionInfo': nutritionInfo.toFirestore(),
      'tags': tags,
      'rating': rating,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  static MealItem fromFirestore(Map<String, dynamic> data) {
    return MealItem(
      name: data['name'] as String,
      category: MealCategory.values.firstWhere(
        (e) => e.name == data['category'],
        orElse: () => MealCategory.main,
      ),
      description: data['description'] as String? ?? '',
      ingredients: (data['ingredients'] as List<dynamic>)
          .map((ingredient) => Ingredient.fromFirestore(ingredient as Map<String, dynamic>))
          .toList(),
      recipe: Recipe.fromFirestore(data['recipe'] as Map<String, dynamic>),
      cookingTime: data['cookingTime'] as int,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      imageUrl: data['imageUrl'] as String?,
      nutritionInfo: NutritionInfo.fromFirestore(data['nutritionInfo'] as Map<String, dynamic>),
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
      rating: (data['rating'] as num?)?.toDouble() ?? 0.0,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  MealItem copyWith({
    String? id,
    String? name,
    MealCategory? category,
    String? description,
    List<Ingredient>? ingredients,
    Recipe? recipe,
    int? cookingTime,
    DifficultyLevel? difficulty,
    String? imageUrl,
    NutritionInfo? nutritionInfo,
    List<String>? tags,
    double? rating,
    DateTime? createdAt,
  }) {
    return MealItem(
      id: id ?? this.id,
      name: name ?? this.name,
      category: category ?? this.category,
      description: description ?? this.description,
      ingredients: ingredients ?? this.ingredients,
      recipe: recipe ?? this.recipe,
      cookingTime: cookingTime ?? this.cookingTime,
      difficulty: difficulty ?? this.difficulty,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

/// 材料のモデル
class Ingredient {
  final String? id;
  final String name;
  final String quantity;
  final String unit;
  final bool available;
  final DateTime? expiryDate;
  final bool shoppingRequired;
  final String? productId;
  final ExpiryPriority priority;
  final String category;
  final String? imageUrl;
  final String notes;

  Ingredient({
    this.id,
    required this.name,
    required this.quantity,
    required this.unit,
    required this.available,
    this.expiryDate,
    required this.shoppingRequired,
    this.productId,
    required this.priority,
    required this.category,
    this.imageUrl,
    this.notes = '',
  });

  /// 賞味期限までの日数
  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    final now = DateTime.now();
    final difference = expiryDate!.difference(DateTime(now.year, now.month, now.day));
    return difference.inDays;
  }

  /// 期限が近いかどうか
  bool get isExpiring => priority == ExpiryPriority.urgent || priority == ExpiryPriority.soon;

  /// 期限切れかどうか
  bool get isExpired => daysUntilExpiry < 0;

  /// 優先度スコア（数値が小さいほど優先）
  double get priorityScore {
    switch (priority) {
      case ExpiryPriority.urgent:
        return 1.0;
      case ExpiryPriority.soon:
        return 2.0;
      case ExpiryPriority.fresh:
        return 3.0;
      case ExpiryPriority.longTerm:
        return 4.0;
    }
  }

  /// 表示名（数量込み）
  String get displayName {
    return '$name $quantity$unit';
  }

  /// 優先度の表示名
  String get priorityDisplayName {
    switch (priority) {
      case ExpiryPriority.urgent:
        return '緊急';
      case ExpiryPriority.soon:
        return '近い';
      case ExpiryPriority.fresh:
        return '新鮮';
      case ExpiryPriority.longTerm:
        return '長期';
    }
  }

  /// 優先度の色
  Color get priorityColor {
    switch (priority) {
      case ExpiryPriority.urgent:
        return Colors.red;
      case ExpiryPriority.soon:
        return Colors.orange;
      case ExpiryPriority.fresh:
        return Colors.green;
      case ExpiryPriority.longTerm:
        return Colors.blue;
    }
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'quantity': quantity,
      'unit': unit,
      'available': available,
      'expiryDate': expiryDate?.millisecondsSinceEpoch,
      'shoppingRequired': shoppingRequired,
      'productId': productId,
      'priority': priority.name,
      'category': category,
      'imageUrl': imageUrl,
      'notes': notes,
    };
  }

  static Ingredient fromFirestore(Map<String, dynamic> data) {
    return Ingredient(
      name: data['name'] as String,
      quantity: data['quantity'] as String,
      unit: data['unit'] as String,
      available: data['available'] as bool,
      expiryDate: data['expiryDate'] != null 
          ? DateTime.fromMillisecondsSinceEpoch(data['expiryDate'] as int)
          : null,
      shoppingRequired: data['shoppingRequired'] as bool,
      productId: data['productId'] as String?,
      priority: ExpiryPriority.values.firstWhere(
        (e) => e.name == data['priority'],
        orElse: () => ExpiryPriority.fresh,
      ),
      category: data['category'] as String,
      imageUrl: data['imageUrl'] as String?,
      notes: data['notes'] as String? ?? '',
    );
  }

  Ingredient copyWith({
    String? id,
    String? name,
    String? quantity,
    String? unit,
    bool? available,
    DateTime? expiryDate,
    bool? shoppingRequired,
    String? productId,
    ExpiryPriority? priority,
    String? category,
    String? imageUrl,
    String? notes,
  }) {
    return Ingredient(
      id: id ?? this.id,
      name: name ?? this.name,
      quantity: quantity ?? this.quantity,
      unit: unit ?? this.unit,
      available: available ?? this.available,
      expiryDate: expiryDate ?? this.expiryDate,
      shoppingRequired: shoppingRequired ?? this.shoppingRequired,
      productId: productId ?? this.productId,
      priority: priority ?? this.priority,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
    );
  }
}

/// レシピのモデル
class Recipe {
  final String? id;
  final List<RecipeStep> steps;
  final int cookingTime;
  final int prepTime;
  final DifficultyLevel difficulty;
  final List<String> tips;
  final int servingSize;
  final NutritionInfo nutritionInfo;
  final List<String> equipment;
  final List<String> tags;

  Recipe({
    this.id,
    required this.steps,
    required this.cookingTime,
    required this.prepTime,
    required this.difficulty,
    this.tips = const [],
    required this.servingSize,
    required this.nutritionInfo,
    this.equipment = const [],
    this.tags = const [],
  });

  /// 総時間（準備時間 + 調理時間）
  int get totalTime => prepTime + cookingTime;

  /// 難易度スコア（1-4）
  int get difficultyScore {
    switch (difficulty) {
      case DifficultyLevel.easy:
        return 1;
      case DifficultyLevel.medium:
        return 2;
      case DifficultyLevel.hard:
        return 3;
      case DifficultyLevel.expert:
        return 4;
    }
  }

  /// ベジタリアン対応かどうか
  bool get isVegetarian {
    return !steps.any((step) => 
      step.description.toLowerCase().contains('肉') ||
      step.description.toLowerCase().contains('魚') ||
      step.description.toLowerCase().contains('鶏')
    );
  }

  /// ビーガン対応かどうか
  bool get isVegan {
    return isVegetarian && !steps.any((step) => 
      step.description.toLowerCase().contains('卵') ||
      step.description.toLowerCase().contains('乳') ||
      step.description.toLowerCase().contains('バター')
    );
  }

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'steps': steps.map((step) => step.toFirestore()).toList(),
      'cookingTime': cookingTime,
      'prepTime': prepTime,
      'difficulty': difficulty.name,
      'tips': tips,
      'servingSize': servingSize,
      'nutritionInfo': nutritionInfo.toFirestore(),
      'equipment': equipment,
      'tags': tags,
    };
  }

  static Recipe fromFirestore(Map<String, dynamic> data) {
    return Recipe(
      steps: (data['steps'] as List<dynamic>)
          .map((step) => RecipeStep.fromFirestore(step as Map<String, dynamic>))
          .toList(),
      cookingTime: data['cookingTime'] as int,
      prepTime: data['prepTime'] as int,
      difficulty: DifficultyLevel.values.firstWhere(
        (e) => e.name == data['difficulty'],
        orElse: () => DifficultyLevel.easy,
      ),
      tips: (data['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      servingSize: data['servingSize'] as int,
      nutritionInfo: NutritionInfo.fromFirestore(data['nutritionInfo'] as Map<String, dynamic>),
      equipment: (data['equipment'] as List<dynamic>?)?.cast<String>() ?? [],
      tags: (data['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }

  Recipe copyWith({
    String? id,
    List<RecipeStep>? steps,
    int? cookingTime,
    int? prepTime,
    DifficultyLevel? difficulty,
    List<String>? tips,
    int? servingSize,
    NutritionInfo? nutritionInfo,
    List<String>? equipment,
    List<String>? tags,
  }) {
    return Recipe(
      id: id ?? this.id,
      steps: steps ?? this.steps,
      cookingTime: cookingTime ?? this.cookingTime,
      prepTime: prepTime ?? this.prepTime,
      difficulty: difficulty ?? this.difficulty,
      tips: tips ?? this.tips,
      servingSize: servingSize ?? this.servingSize,
      nutritionInfo: nutritionInfo ?? this.nutritionInfo,
      equipment: equipment ?? this.equipment,
      tags: tags ?? this.tags,
    );
  }
}

/// レシピステップのモデル
class RecipeStep {
  final String? id;
  final int stepNumber;
  final String description;
  final int? duration; // 分
  final String? imageUrl;
  final List<String> tips;
  final bool isCompleted;

  RecipeStep({
    this.id,
    required this.stepNumber,
    required this.description,
    this.duration,
    this.imageUrl,
    this.tips = const [],
    this.isCompleted = false,
  });

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'stepNumber': stepNumber,
      'description': description,
      'duration': duration,
      'imageUrl': imageUrl,
      'tips': tips,
      'isCompleted': isCompleted,
    };
  }

  static RecipeStep fromFirestore(Map<String, dynamic> data) {
    return RecipeStep(
      stepNumber: data['stepNumber'] as int,
      description: data['description'] as String,
      duration: data['duration'] as int?,
      imageUrl: data['imageUrl'] as String?,
      tips: (data['tips'] as List<dynamic>?)?.cast<String>() ?? [],
      isCompleted: data['isCompleted'] as bool? ?? false,
    );
  }

  RecipeStep copyWith({
    String? id,
    int? stepNumber,
    String? description,
    int? duration,
    String? imageUrl,
    List<String>? tips,
    bool? isCompleted,
  }) {
    return RecipeStep(
      id: id ?? this.id,
      stepNumber: stepNumber ?? this.stepNumber,
      description: description ?? this.description,
      duration: duration ?? this.duration,
      imageUrl: imageUrl ?? this.imageUrl,
      tips: tips ?? this.tips,
      isCompleted: isCompleted ?? this.isCompleted,
    );
  }
}

/// 栄養情報のモデル
class NutritionInfo {
  final double calories;
  final double protein;
  final double carbohydrates;
  final double fat;
  final double fiber;
  final double sugar;
  final double sodium;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbohydrates,
    required this.fat,
    required this.fiber,
    required this.sugar,
    required this.sodium,
  });

  // Firestore変換メソッド
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'protein': protein,
      'carbohydrates': carbohydrates,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }

  static NutritionInfo fromFirestore(Map<String, dynamic> data) {
    return NutritionInfo(
      calories: (data['calories'] as num).toDouble(),
      protein: (data['protein'] as num).toDouble(),
      carbohydrates: (data['carbohydrates'] as num).toDouble(),
      fat: (data['fat'] as num).toDouble(),
      fiber: (data['fiber'] as num).toDouble(),
      sugar: (data['sugar'] as num).toDouble(),
      sodium: (data['sodium'] as num).toDouble(),
    );
  }

  NutritionInfo copyWith({
    double? calories,
    double? protein,
    double? carbohydrates,
    double? fat,
    double? fiber,
    double? sugar,
    double? sodium,
  }) {
    return NutritionInfo(
      calories: calories ?? this.calories,
      protein: protein ?? this.protein,
      carbohydrates: carbohydrates ?? this.carbohydrates,
      fat: fat ?? this.fat,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
    );
  }
}
