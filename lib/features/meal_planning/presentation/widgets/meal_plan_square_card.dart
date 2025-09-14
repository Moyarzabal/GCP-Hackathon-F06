import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class MealPlanSquareCard extends StatelessWidget {
  final MealItem? mealItem;
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? imageUrl;
  final bool isAddButton;

  const MealPlanSquareCard({
    Key? key,
    this.mealItem,
    required this.title,
    this.onTap,
    this.isSelected = false,
    this.imageUrl,
    this.isAddButton = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('🔍 MealPlanSquareCard: $title - imageUrl: $imageUrl');
    if (isAddButton) {
      return _buildAddButton(context);
    }
    
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: isSelected
            ? Border.all(color: Theme.of(context).colorScheme.primary, width: 2)
            : null,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Material(
          color: Colors.white,
          child: InkWell(
            onTap: onTap,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー（カテゴリラベル）
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor().withOpacity(0.9),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Spacer(),
                      if (onTap != null)
                        const Icon(
                          Icons.close,
                          size: 16,
                          color: Colors.white,
                        ),
                    ],
                  ),
                ),
                
                // 画像エリア
                Expanded(
                  child: Container(
                    width: double.infinity,
                    height: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.grey[100],
                    ),
                    child: _buildImageWidget(),
                  ),
                ),
                
                // 料理名
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    mealItem?.name ?? '料理名',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
                
                // 変更ボタン
                if (onTap != null)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(8, 0, 8, 6),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.refresh,
                          size: 14,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '変更',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAddButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[300]!,
          style: BorderStyle.solid,
        ),
      ),
      child: Material(
        color: Colors.white,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: double.infinity,
            height: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.add,
                  size: 48,
                  color: Colors.grey[400],
                ),
                const SizedBox(height: 8),
                Text(
                  'もう一品追加',
                  style: TextStyle(
                    color: Colors.grey[600],
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget() {
    print('🖼️ _buildImageWidget: imageUrl = $imageUrl');
    
    if (imageUrl != null) {
      print('🌐 ネットワーク画像を表示: $imageUrl');
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          print('❌ 画像読み込みエラー: $imageUrl - $error');
          return _buildPlaceholderImage();
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            print('✅ 画像読み込み完了: $imageUrl');
            return child;
          }
          return const Center(
            child: CircularProgressIndicator(),
          );
        },
      );
    } else {
      print('🎨 プレースホルダー画像を表示（imageUrl is null）');
      return _buildPlaceholderImage();
    }
  }

  Widget _buildPlaceholderImage() {
    print('🎨 プレースホルダー画像を構築中: $title');
    
    // 料理の種類に応じたアイコンを選択
    IconData iconData;
    String displayText;
    
    switch (title) {
      case '主菜':
        iconData = Icons.restaurant_menu;
        displayText = '主菜';
        break;
      case '副菜':
        iconData = Icons.local_dining;
        displayText = '副菜';
        break;
      case '汁物':
        iconData = Icons.soup_kitchen;
        displayText = '汁物';
        break;
      case '主食':
        iconData = Icons.rice_bowl;
        displayText = '主食';
        break;
      default:
        iconData = Icons.restaurant;
        displayText = '料理';
    }
    
    print('🎨 プレースホルダー画像: $displayText, アイコン: $iconData');
    
    return Container(
      width: double.infinity,
      height: double.infinity,
      constraints: const BoxConstraints(
        minHeight: 100,
        minWidth: 100,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.green[100]!,
            Colors.green[50]!,
          ],
        ),
        border: Border.all(
          color: Colors.red,
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 60,
            height: 60,
            color: Colors.blue[200],
            child: Icon(
              iconData,
              size: 48,
              color: Colors.green[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              color: Colors.green[700],
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          Text(
            'DEBUG',
            style: TextStyle(
              color: Colors.red,
              fontSize: 8,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  Color _getCategoryColor() {
    switch (title) {
      case '主菜':
        return Colors.red;
      case '副菜':
        return Colors.green;
      case '汁物':
        return Colors.blue;
      case '主食':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}
