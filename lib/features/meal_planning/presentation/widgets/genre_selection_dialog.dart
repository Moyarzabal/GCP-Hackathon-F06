import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class GenreSelectionDialog extends StatelessWidget {
  final Function(MealCategory) onGenreSelected;

  const GenreSelectionDialog({
    super.key,
    required this.onGenreSelected,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFFF6EACB),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      title: const Text(
        'ジャンルを選択',
        style: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          color: Color(0xFF5D4E37),
        ),
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            '追加したい料理のジャンルを選択してください',
            style: TextStyle(
              fontSize: 14,
              color: Color(0xFF8B7355),
            ),
          ),
          const SizedBox(height: 20),
          _buildGenreButton(context, '主菜', MealCategory.main, Icons.restaurant),
          const SizedBox(height: 12),
          _buildGenreButton(
              context, '副菜', MealCategory.side, Icons.local_dining),
          const SizedBox(height: 12),
          _buildGenreButton(
              context, '汁物', MealCategory.soup, Icons.soup_kitchen),
          const SizedBox(height: 12),
          _buildGenreButton(
              context, 'おつまみ', MealCategory.dessert, Icons.cookie),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'キャンセル',
            style: TextStyle(
              color: Color(0xFF8B7355),
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGenreButton(
    BuildContext context,
    String title,
    MealCategory category,
    IconData icon,
  ) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          Navigator.of(context).pop();
          onGenreSelected(category);
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF5D4E37),
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFFD4A574), width: 1),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 24,
              color: const Color(0xFF8B7355),
            ),
            const SizedBox(width: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Color(0xFF5D4E37),
              ),
            ),
            const Spacer(),
            const Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: Color(0xFF8B7355),
            ),
          ],
        ),
      ),
    );
  }
}
