import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class MealDetailDialog extends StatefulWidget {
  // カラー定義
  static const Color _baseColor = Color(0xFFF6EACB);
  static const Color _primaryColor = Color(0xFFD4A574);
  static const Color _secondaryColor = Color(0xFFB8956A);
  static const Color _accentColor = Color(0xFF8B7355);
  static const Color _textColor = Color(0xFF5D4E37);
  final MealItem mealItem;

  const MealDetailDialog({
    Key? key,
    required this.mealItem,
  }) : super(key: key);

  @override
  State<MealDetailDialog> createState() => _MealDetailDialogState();
}

class _MealDetailDialogState extends State<MealDetailDialog>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: MealDetailDialog._baseColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        decoration: BoxDecoration(
          color: MealDetailDialog._baseColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: MealDetailDialog._primaryColor.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Column(
          children: [
            // ヘッダー
            _buildHeader(),

            // タブバー
            _buildTabBar(),

            // タブコンテンツ
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildIngredientsTab(),
                  _buildRecipeTab(),
                  _buildNutritionTab(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: MealDetailDialog._primaryColor.withOpacity(0.2),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(16),
          topRight: Radius.circular(16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _getCategoryColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: _getCategoryColor().withOpacity(0.3),
                  ),
                ),
                child: Text(
                  widget.mealItem.categoryDisplayName,
                  style: TextStyle(
                    color: _getCategoryColor(),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: Icon(Icons.close, color: MealDetailDialog._accentColor),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.2),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          Text(
            widget.mealItem.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: MealDetailDialog._textColor,
                ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          if (widget.mealItem.description.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              widget.mealItem.description,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: MealDetailDialog._accentColor,
                  ),
            ),
          ],

          const SizedBox(height: 16),

          // 情報バー
          Row(
            children: [
              _buildInfoChip(
                icon: Icons.access_time,
                label: '${widget.mealItem.cookingTime}分',
                color: Colors.blue,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.star,
                label: widget.mealItem.recipe.difficulty.name,
                color: Colors.orange,
              ),
              const SizedBox(width: 8),
              _buildInfoChip(
                icon: Icons.people,
                label: '${widget.mealItem.recipe.servingSize}人分',
                color: Colors.green,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar() {
    return Container(
      decoration: BoxDecoration(
        color: MealDetailDialog._baseColor,
        border: Border(
          bottom: BorderSide(
            color: MealDetailDialog._primaryColor.withOpacity(0.2),
          ),
        ),
      ),
      child: TabBar(
        controller: _tabController,
        labelColor: MealDetailDialog._textColor,
        unselectedLabelColor: MealDetailDialog._accentColor,
        indicatorColor: MealDetailDialog._primaryColor,
        tabs: const [
          Tab(
            icon: Icon(Icons.shopping_basket),
            text: '材料',
          ),
          Tab(
            icon: Icon(Icons.menu_book),
            text: 'レシピ',
          ),
          Tab(
            icon: Icon(Icons.analytics),
            text: '栄養',
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 在庫状況のサマリー
          _buildIngredientSummary(),

          const SizedBox(height: 20),

          // 材料リスト
          Text(
            '材料リスト',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          ...widget.mealItem.ingredients
              .map((ingredient) => _buildIngredientItem(ingredient)),
        ],
      ),
    );
  }

  Widget _buildIngredientSummary() {
    final availableCount = widget.mealItem.ingredients
        .where((ingredient) => ingredient.available)
        .length;
    final totalCount = widget.mealItem.ingredients.length;
    final missingCount = totalCount - availableCount;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: availableCount == totalCount
            ? Colors.green.withOpacity(0.1)
            : Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: availableCount == totalCount
              ? Colors.green.withOpacity(0.3)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            availableCount == totalCount ? Icons.check_circle : Icons.warning,
            color: availableCount == totalCount ? Colors.green : Colors.orange,
            size: 24,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  availableCount == totalCount
                      ? 'すべての材料が揃っています'
                      : '$missingCount個の材料が不足しています',
                  style: TextStyle(
                    color: availableCount == totalCount
                        ? Colors.green
                        : Colors.orange,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '在庫: $availableCount/$totalCount',
                  style: TextStyle(
                    color: availableCount == totalCount
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientItem(Ingredient ingredient) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: ingredient.available
            ? Colors.green.withOpacity(0.05)
            : Colors.orange.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: ingredient.available
              ? Colors.green.withOpacity(0.2)
              : Colors.orange.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Icon(
            ingredient.available ? Icons.check_circle : Icons.shopping_cart,
            color: ingredient.available ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ingredient.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 16,
                  ),
                ),
                Text(
                  '${ingredient.quantity}${ingredient.unit}',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          if (ingredient.available && ingredient.expiryDate != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: ingredient.priorityColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: ingredient.priorityColor.withOpacity(0.3),
                ),
              ),
              child: Text(
                ingredient.priorityDisplayName,
                style: TextStyle(
                  color: ingredient.priorityColor,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 調理時間と難易度
          _buildRecipeInfo(),

          const SizedBox(height: 20),

          // 調理手順
          Text(
            '調理手順',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          ...widget.mealItem.recipe.steps.asMap().entries.map((entry) {
            final index = entry.key;
            final step = entry.value;
            return _buildRecipeStep(index + 1, step);
          }),

          if (widget.mealItem.recipe.tips.isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildTipsSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildRecipeInfo() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: MealDetailDialog._baseColor.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: MealDetailDialog._primaryColor.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          _buildInfoChip(
            icon: Icons.access_time,
            label: '調理時間: ${widget.mealItem.recipe.cookingTime}分',
            color: Colors.blue,
          ),
          const SizedBox(width: 12),
          _buildInfoChip(
            icon: Icons.star,
            label: widget.mealItem.recipe.difficulty.name,
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildRecipeStep(int stepNumber, RecipeStep step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
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
                stepNumber.toString(),
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.description,
                  style: const TextStyle(
                    fontSize: 16,
                    height: 1.4,
                  ),
                ),
                if (step.duration != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.timer,
                        size: 16,
                        color: Colors.grey[600],
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${step.duration}分',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipsSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.amber.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.lightbulb,
                color: Colors.amber[700],
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'コツ・ポイント',
                style: TextStyle(
                  color: Colors.amber[700],
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...widget.mealItem.recipe.tips.map((tip) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '• ',
                      style: TextStyle(
                        color: Colors.amber[700],
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          color: Colors.amber[700],
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildNutritionTab() {
    final nutrition = widget.mealItem.nutritionInfo;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // カロリー表示
          _buildCalorieDisplay(nutrition.calories),

          const SizedBox(height: 20),

          // 栄養素の詳細
          Text(
            '栄養素の詳細',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),

          const SizedBox(height: 12),

          _buildNutritionItem(
            label: 'タンパク質',
            value: nutrition.protein,
            unit: 'g',
            color: Colors.red,
            icon: Icons.fitness_center,
          ),

          _buildNutritionItem(
            label: '炭水化物',
            value: nutrition.carbohydrates,
            unit: 'g',
            color: Colors.blue,
            icon: Icons.grain,
          ),

          _buildNutritionItem(
            label: '脂質',
            value: nutrition.fat,
            unit: 'g',
            color: Colors.orange,
            icon: Icons.opacity,
          ),

          _buildNutritionItem(
            label: '食物繊維',
            value: nutrition.fiber,
            unit: 'g',
            color: Colors.green,
            icon: Icons.eco,
          ),

          _buildNutritionItem(
            label: '糖質',
            value: nutrition.sugar,
            unit: 'g',
            color: Colors.pink,
            icon: Icons.cake,
          ),

          _buildNutritionItem(
            label: 'ナトリウム',
            value: nutrition.sodium,
            unit: 'mg',
            color: Colors.purple,
            icon: Icons.water_drop,
          ),
        ],
      ),
    );
  }

  Widget _buildCalorieDisplay(double calories) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.red.withOpacity(0.1),
            Colors.orange.withOpacity(0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.local_fire_department,
            color: Colors.red[600],
            size: 32,
          ),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'カロリー',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                '${calories.toInt()} kcal',
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildNutritionItem({
    required String label,
    required double value,
    required String unit,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Text(
            '${value.toStringAsFixed(1)}$unit',
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (widget.mealItem.category) {
      case MealCategory.main:
        return Colors.red;
      case MealCategory.side:
        return Colors.green;
      case MealCategory.soup:
        return Colors.blue;
      case MealCategory.rice:
        return Colors.brown;
      case MealCategory.dessert:
        return Colors.pink;
      case MealCategory.beverage:
        return Colors.cyan;
    }
  }
}
