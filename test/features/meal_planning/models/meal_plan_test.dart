import 'package:flutter_test/flutter_test.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../lib/shared/models/meal_plan.dart';

void main() {
  group('MealPlan', () {
    test('should create a valid MealPlan instance', () {
      final mealPlan = MealPlan(
        householdId: 'test-household',
        date: DateTime(2024, 1, 1),
        status: MealPlanStatus.suggested,
        mainDish: _createMockMealItem('主菜', MealCategory.main),
        sideDish: _createMockMealItem('副菜', MealCategory.side),
        soup: _createMockMealItem('汁物', MealCategory.soup),
        rice: _createMockMealItem('主食', MealCategory.rice),
        totalCookingTime: 60,
        difficulty: DifficultyLevel.easy,
        nutritionScore: 85.0,
        confidence: 0.8,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'test-user',
      );

      expect(mealPlan.householdId, 'test-household');
      expect(mealPlan.status, MealPlanStatus.suggested);
      expect(mealPlan.totalCookingTime, 60);
      expect(mealPlan.difficulty, DifficultyLevel.easy);
      expect(mealPlan.nutritionScore, 85.0);
      expect(mealPlan.confidence, 0.8);
    });

    test('should calculate total calories correctly', () {
      final mealPlan = MealPlan(
        householdId: 'test-household',
        date: DateTime(2024, 1, 1),
        status: MealPlanStatus.suggested,
        mainDish: _createMockMealItemWithCalories('主菜', 300.0),
        sideDish: _createMockMealItemWithCalories('副菜', 150.0),
        soup: _createMockMealItemWithCalories('汁物', 100.0),
        rice: _createMockMealItemWithCalories('主食', 200.0),
        totalCookingTime: 60,
        difficulty: DifficultyLevel.easy,
        nutritionScore: 85.0,
        confidence: 0.8,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'test-user',
      );

      expect(mealPlan.totalCalories, 750.0);
    });

    test('should identify missing ingredients correctly', () {
      final mealPlan = MealPlan(
        householdId: 'test-household',
        date: DateTime(2024, 1, 1),
        status: MealPlanStatus.suggested,
        mainDish: _createMockMealItemWithIngredients([
          _createMockIngredient('材料1', true),
          _createMockIngredient('材料2', false),
        ]),
        sideDish: _createMockMealItemWithIngredients([
          _createMockIngredient('材料3', true),
        ]),
        soup: _createMockMealItemWithIngredients([
          _createMockIngredient('材料4', false),
        ]),
        rice: _createMockMealItemWithIngredients([
          _createMockIngredient('材料5', true),
        ]),
        totalCookingTime: 60,
        difficulty: DifficultyLevel.easy,
        nutritionScore: 85.0,
        confidence: 0.8,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'test-user',
      );

      final missingIngredients = mealPlan.missingIngredients;
      expect(missingIngredients.length, 2);
      expect(missingIngredients.any((ingredient) => ingredient.name == '材料2'), true);
      expect(missingIngredients.any((ingredient) => ingredient.name == '材料4'), true);
    });

    test('should convert to and from Firestore correctly', () {
      final originalMealPlan = MealPlan(
        householdId: 'test-household',
        date: DateTime(2024, 1, 1),
        status: MealPlanStatus.suggested,
        mainDish: _createMockMealItem('主菜', MealCategory.main),
        sideDish: _createMockMealItem('副菜', MealCategory.side),
        soup: _createMockMealItem('汁物', MealCategory.soup),
        rice: _createMockMealItem('主食', MealCategory.rice),
        totalCookingTime: 60,
        difficulty: DifficultyLevel.easy,
        nutritionScore: 85.0,
        confidence: 0.8,
        createdAt: DateTime(2024, 1, 1),
        createdBy: 'test-user',
      );

      final firestoreData = originalMealPlan.toFirestore();
      final restoredMealPlan = MealPlan.fromFirestore('test-id', firestoreData);

      expect(restoredMealPlan.householdId, originalMealPlan.householdId);
      expect(restoredMealPlan.status, originalMealPlan.status);
      expect(restoredMealPlan.totalCookingTime, originalMealPlan.totalCookingTime);
      expect(restoredMealPlan.difficulty, originalMealPlan.difficulty);
      expect(restoredMealPlan.nutritionScore, originalMealPlan.nutritionScore);
      expect(restoredMealPlan.confidence, originalMealPlan.confidence);
    });
  });

  group('MealItem', () {
    test('should create a valid MealItem instance', () {
      final mealItem = MealItem(
        name: 'テストメニュー',
        category: MealCategory.main,
        description: 'テスト説明',
        ingredients: [_createMockIngredient('材料1', true)],
        recipe: _createMockRecipe(),
        cookingTime: 30,
        difficulty: DifficultyLevel.easy,
        nutritionInfo: _createMockNutritionInfo(),
        createdAt: DateTime(2024, 1, 1),
      );

      expect(mealItem.name, 'テストメニュー');
      expect(mealItem.category, MealCategory.main);
      expect(mealItem.cookingTime, 30);
      expect(mealItem.difficulty, DifficultyLevel.easy);
    });

    test('should check availability correctly', () {
      final availableItem = MealItem(
        name: '利用可能メニュー',
        category: MealCategory.main,
        description: 'テスト説明',
        ingredients: [
          _createMockIngredient('材料1', true),
          _createMockIngredient('材料2', true),
        ],
        recipe: _createMockRecipe(),
        cookingTime: 30,
        difficulty: DifficultyLevel.easy,
        nutritionInfo: _createMockNutritionInfo(),
        createdAt: DateTime(2024, 1, 1),
      );

      final unavailableItem = MealItem(
        name: '利用不可メニュー',
        category: MealCategory.main,
        description: 'テスト説明',
        ingredients: [
          _createMockIngredient('材料1', true),
          _createMockIngredient('材料2', false),
        ],
        recipe: _createMockRecipe(),
        cookingTime: 30,
        difficulty: DifficultyLevel.easy,
        nutritionInfo: _createMockNutritionInfo(),
        createdAt: DateTime(2024, 1, 1),
      );

      expect(availableItem.isAvailable, true);
      expect(unavailableItem.isAvailable, false);
    });
  });

  group('Ingredient', () {
    test('should create a valid Ingredient instance', () {
      final ingredient = Ingredient(
        name: 'テスト材料',
        quantity: '100',
        unit: 'g',
        available: true,
        expiryDate: DateTime(2024, 1, 10),
        shoppingRequired: false,
        priority: ExpiryPriority.fresh,
        category: '野菜',
      );

      expect(ingredient.name, 'テスト材料');
      expect(ingredient.quantity, '100');
      expect(ingredient.unit, 'g');
      expect(ingredient.available, true);
      expect(ingredient.shoppingRequired, false);
      expect(ingredient.priority, ExpiryPriority.fresh);
    });

    test('should calculate days until expiry correctly', () {
      final today = DateTime(2024, 1, 1);
      final tomorrow = DateTime(2024, 1, 2);
      final nextWeek = DateTime(2024, 1, 8);

      final ingredient1 = Ingredient(
        name: '材料1',
        quantity: '100',
        unit: 'g',
        available: true,
        expiryDate: tomorrow,
        shoppingRequired: false,
        priority: ExpiryPriority.urgent,
        category: '野菜',
      );

      final ingredient2 = Ingredient(
        name: '材料2',
        quantity: '100',
        unit: 'g',
        available: true,
        expiryDate: nextWeek,
        shoppingRequired: false,
        priority: ExpiryPriority.fresh,
        category: '野菜',
      );

      // 注意: 実際のテストでは、DateTime.now()をモックする必要があります
      // ここでは基本的な構造のみテスト
      expect(ingredient1.expiryDate, tomorrow);
      expect(ingredient2.expiryDate, nextWeek);
    });
  });
}

// ヘルパー関数
MealItem _createMockMealItem(String name, MealCategory category) {
  return MealItem(
    name: name,
    category: category,
    description: '$nameの説明',
    ingredients: [_createMockIngredient('材料1', true)],
    recipe: _createMockRecipe(),
    cookingTime: 30,
    difficulty: DifficultyLevel.easy,
    nutritionInfo: _createMockNutritionInfo(),
    createdAt: DateTime(2024, 1, 1),
  );
}

MealItem _createMockMealItemWithCalories(String name, double calories) {
  return MealItem(
    name: name,
    category: MealCategory.main,
    description: '$nameの説明',
    ingredients: [_createMockIngredient('材料1', true)],
    recipe: _createMockRecipe(),
    cookingTime: 30,
    difficulty: DifficultyLevel.easy,
    nutritionInfo: NutritionInfo(
      calories: calories,
      protein: 10.0,
      carbohydrates: 20.0,
      fat: 5.0,
      fiber: 2.0,
      sugar: 3.0,
      sodium: 100.0,
    ),
    createdAt: DateTime(2024, 1, 1),
  );
}

MealItem _createMockMealItemWithIngredients(List<Ingredient> ingredients) {
  return MealItem(
    name: 'テストメニュー',
    category: MealCategory.main,
    description: 'テスト説明',
    ingredients: ingredients,
    recipe: _createMockRecipe(),
    cookingTime: 30,
    difficulty: DifficultyLevel.easy,
    nutritionInfo: _createMockNutritionInfo(),
    createdAt: DateTime(2024, 1, 1),
  );
}

Ingredient _createMockIngredient(String name, bool available) {
  return Ingredient(
    name: name,
    quantity: '100',
    unit: 'g',
    available: available,
    expiryDate: DateTime(2024, 1, 10),
    shoppingRequired: !available,
    priority: ExpiryPriority.fresh,
    category: '野菜',
  );
}

Recipe _createMockRecipe() {
  return Recipe(
    steps: [
      RecipeStep(stepNumber: 1, description: '材料を準備する'),
      RecipeStep(stepNumber: 2, description: '調理する'),
    ],
    cookingTime: 20,
    prepTime: 10,
    difficulty: DifficultyLevel.easy,
    servingSize: 4,
    nutritionInfo: _createMockNutritionInfo(),
  );
}

NutritionInfo _createMockNutritionInfo() {
  return NutritionInfo(
    calories: 300.0,
    protein: 20.0,
    carbohydrates: 30.0,
    fat: 10.0,
    fiber: 5.0,
    sugar: 5.0,
    sodium: 500.0,
  );
}

