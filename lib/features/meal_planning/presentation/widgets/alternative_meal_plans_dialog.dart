import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class AlternativeMealPlansDialog extends StatelessWidget {
  final MealPlan currentMealPlan;
  final Function(MealPlan) onSelectAlternative;

  const AlternativeMealPlansDialog({
    Key? key,
    required this.currentMealPlan,
    required this.onSelectAlternative,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(context),
            
            // 現在の献立
            _buildCurrentMealPlan(context),
            
            // 代替案リスト
            Expanded(
              child: _buildAlternativesList(context),
            ),
            
            // フッター
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Theme.of(context).colorScheme.primary.withOpacity(0.1),
            Theme.of(context).colorScheme.secondary.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.refresh,
            color: Theme.of(context).colorScheme.primary,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '代替献立を提案',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.close),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withOpacity(0.2),
              foregroundColor: Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentMealPlan(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                color: Theme.of(context).colorScheme.primary,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                '現在の献立',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            currentMealPlan.displayName,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${currentMealPlan.totalCookingTime}分',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.star,
                label: currentMealPlan.difficultyDisplayName,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.favorite,
                label: '${currentMealPlan.nutritionScore.toInt()}点',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAlternativesList(BuildContext context) {
    // モックデータ - 実際の実装では、AIから代替案を取得
    final alternatives = _generateMockAlternatives();
    
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: alternatives.length,
      itemBuilder: (context, index) {
        final alternative = alternatives[index];
        return _buildAlternativeCard(context, alternative, index + 1);
      },
    );
  }

  Widget _buildAlternativeCard(BuildContext context, MealPlan alternative, int number) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        child: InkWell(
          onTap: () {
            onSelectAlternative(alternative);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          number.toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        alternative.displayName,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 16,
                      color: Colors.grey[400],
                    ),
                  ],
                ),
                
                const SizedBox(height: 12),
                
                // メニューアイテムのプレビュー
                _buildMenuItemsPreview(alternative),
                
                const SizedBox(height: 12),
                
                // 情報バー
                Row(
                  children: [
                    _buildInfoChip(
                      icon: Icons.access_time,
                      label: '${alternative.totalCookingTime}分',
                      color: Colors.blue,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.star,
                      label: alternative.difficultyDisplayName,
                      color: Colors.orange,
                    ),
                    const SizedBox(width: 8),
                    _buildInfoChip(
                      icon: Icons.favorite,
                      label: '${alternative.nutritionScore.toInt()}点',
                      color: Colors.green,
                    ),
                    const Spacer(),
                    _buildInfoChip(
                      icon: Icons.psychology,
                      label: '${(alternative.confidence * 100).toInt()}%',
                      color: Colors.purple,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItemsPreview(MealPlan mealPlan) {
    return Row(
      children: [
        _buildMenuItemChip(mealPlan.mainDish.name, Colors.red),
        const SizedBox(width: 4),
        _buildMenuItemChip(mealPlan.sideDish.name, Colors.green),
        const SizedBox(width: 4),
        _buildMenuItemChip(mealPlan.soup.name, Colors.blue),
        const SizedBox(width: 4),
        _buildMenuItemChip(mealPlan.rice.name, Colors.brown),
      ],
    );
  }

  Widget _buildMenuItemChip(String name, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Text(
        name,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w500,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(16),
          bottomRight: Radius.circular(16),
        ),
        border: Border(
          top: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          ),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.close),
              label: const Text('キャンセル'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              onPressed: () {
                // 新しい代替案を生成
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('新しい代替案を生成中...'),
                  ),
                );
              },
              icon: const Icon(Icons.refresh),
              label: const Text('新しい代替案'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  // モックデータ生成（実際の実装では、AIから代替案を取得）
  List<MealPlan> _generateMockAlternatives() {
    return [
      _createMockMealPlan(
        'トマトとチキンのパスタ',
        'サラダ',
        'コンソメスープ',
        '白米',
        45,
        DifficultyLevel.easy,
        85.0,
      ),
      _createMockMealPlan(
        '鮭のムニエル',
        '温野菜',
        '味噌汁',
        '玄米',
        35,
        DifficultyLevel.medium,
        90.0,
      ),
      _createMockMealPlan(
        'ハンバーグ',
        'ポテトサラダ',
        'コーンスープ',
        'パン',
        50,
        DifficultyLevel.easy,
        80.0,
      ),
    ];
  }

  MealPlan _createMockMealPlan(
    String mainDishName,
    String sideDishName,
    String soupName,
    String riceName,
    int cookingTime,
    DifficultyLevel difficulty,
    double nutritionScore,
  ) {
    return MealPlan(
      householdId: currentMealPlan.householdId,
      date: DateTime.now(),
      status: MealPlanStatus.suggested,
      mainDish: _createMockMealItem(mainDishName, MealCategory.main),
      sideDish: _createMockMealItem(sideDishName, MealCategory.side),
      soup: _createMockMealItem(soupName, MealCategory.soup),
      rice: _createMockMealItem(riceName, MealCategory.rice),
      totalCookingTime: cookingTime,
      difficulty: difficulty,
      nutritionScore: nutritionScore,
      confidence: 0.8,
      createdAt: DateTime.now(),
      createdBy: 'ai_agent',
    );
  }

  MealItem _createMockMealItem(String name, MealCategory category) {
    return MealItem(
      name: name,
      category: category,
      description: '$nameの説明',
      ingredients: [
        Ingredient(
          name: '材料1',
          quantity: '100',
          unit: 'g',
          available: true,
          priority: ExpiryPriority.fresh,
          category: 'その他',
          shoppingRequired: false,
        ),
        Ingredient(
          name: '材料2',
          quantity: '1',
          unit: '個',
          available: true,
          priority: ExpiryPriority.fresh,
          category: 'その他',
          shoppingRequired: false,
        ),
      ],
      recipe: Recipe(
        steps: [
          RecipeStep(stepNumber: 1, description: '材料を準備する'),
          RecipeStep(stepNumber: 2, description: '調理する'),
          RecipeStep(stepNumber: 3, description: '盛り付ける'),
        ],
        cookingTime: 20,
        prepTime: 10,
        difficulty: DifficultyLevel.easy,
        servingSize: 4,
        nutritionInfo: NutritionInfo(
          calories: 300.0,
          protein: 20.0,
          carbohydrates: 30.0,
          fat: 10.0,
          fiber: 5.0,
          sugar: 5.0,
          sodium: 500.0,
        ),
      ),
      cookingTime: 20,
      difficulty: DifficultyLevel.easy,
      nutritionInfo: NutritionInfo(
        calories: 300.0,
        protein: 20.0,
        carbohydrates: 30.0,
        fat: 10.0,
        fiber: 5.0,
        sugar: 5.0,
        sodium: 500.0,
      ),
      createdAt: DateTime.now(),
    );
  }
}
