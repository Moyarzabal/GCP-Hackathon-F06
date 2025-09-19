import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class MealPlanCard extends StatelessWidget {
  final MealItem mealItem;
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? imageUrl;
  final bool isAddButton;

  const MealPlanCard({
    Key? key,
    required this.mealItem,
    required this.title,
    this.onTap,
    this.isSelected = false,
    this.imageUrl,
    this.isAddButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isSelected
            ? BorderSide(color: Theme.of(context).colorScheme.primary, width: 2)
            : BorderSide.none,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ヘッダー
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor().withOpacity(0.1),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _getCategoryColor().withOpacity(0.3),
                      ),
                    ),
                    child: Text(
                      title,
                      style: TextStyle(
                        color: _getCategoryColor(),
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                  const Spacer(),
                  if (mealItem.isAvailable)
                    Icon(
                      Icons.check_circle,
                      color: Colors.green,
                      size: 20,
                    )
                  else
                    Icon(
                      Icons.shopping_cart,
                      color: Colors.orange,
                      size: 20,
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // メニュー名
              Text(
                mealItem.name,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (mealItem.description.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(
                  mealItem.description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey[600],
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],

              const SizedBox(height: 12),

              // 情報バー
              Row(
                children: [
                  _buildInfoChip(
                    icon: Icons.access_time,
                    label: '${mealItem.cookingTime}分',
                    color: Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.star,
                    label: mealItem.difficultyDisplayName,
                    color: Colors.orange,
                  ),
                  const SizedBox(width: 8),
                  _buildInfoChip(
                    icon: Icons.local_fire_department,
                    label: '${mealItem.nutritionInfo.calories.toInt()}kcal',
                    color: Colors.red,
                  ),
                ],
              ),

              const SizedBox(height: 12),

              // 材料情報
              _buildIngredientsInfo(),
            ],
          ),
        ),
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w500,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIngredientsInfo() {
    final availableCount = mealItem.ingredients.where((ingredient) => ingredient.available).length;
    final totalCount = mealItem.ingredients.length;
    final missingCount = totalCount - availableCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.shopping_basket,
              size: 16,
              color: Colors.grey[600],
            ),
            const SizedBox(width: 4),
            Text(
              '材料: $availableCount/$totalCount',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const Spacer(),
            if (missingCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: Text(
                  '$missingCount個不足',
                  style: const TextStyle(
                    color: Colors.orange,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
          ],
        ),

        if (mealItem.ingredients.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: mealItem.ingredients.take(3).map((ingredient) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: ingredient.available
                      ? Colors.green.withOpacity(0.1)
                      : Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: ingredient.available
                        ? Colors.green.withOpacity(0.3)
                        : Colors.orange.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      ingredient.available ? Icons.check : Icons.shopping_cart,
                      size: 12,
                      color: ingredient.available ? Colors.green : Colors.orange,
                    ),
                    const SizedBox(width: 2),
                    Text(
                      ingredient.name,
                      style: TextStyle(
                        color: ingredient.available ? Colors.green : Colors.orange,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),

          if (mealItem.ingredients.length > 3) ...[
            const SizedBox(height: 4),
            Text(
              '他${mealItem.ingredients.length - 3}個の材料',
              style: TextStyle(
                color: Colors.grey[500],
                fontSize: 10,
              ),
            ),
          ],
        ],
      ],
    );
  }

  Color _getCategoryColor() {
    switch (mealItem.category) {
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
