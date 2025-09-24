import 'package:flutter/material.dart';
import '../../../../shared/models/meal_plan.dart';

class MealPlanSquareCard extends StatelessWidget {
  final MealItem? mealItem;
  final String title;
  final VoidCallback? onTap;
  final bool isSelected;
  final String? imageUrl;
  final bool isAddButton;
  // 温かみのあるカラーパレット
  static const Color _baseColor = Color(0xFFF6EACB); // クリーム色
  static const Color _primaryColor = Color(0xFFD4A574); // 温かいベージュ
  static const Color _secondaryColor = Color(0xFFB8956A); // 深いベージュ
  static const Color _accentColor = Color(0xFF8B7355); // ブラウン
  static const Color _textColor = Color(0xFF5D4E37); // ダークブラウン

  const MealPlanSquareCard({
    super.key,
    this.mealItem,
    required this.title,
    this.onTap,
    this.isSelected = false,
    this.imageUrl,
    this.isAddButton = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isAddButton) {
      return _buildAddButton(context);
    }

    return Container(
      decoration: BoxDecoration(
        color: _baseColor.withOpacity(0.8),
        border: Border.all(
          color: _primaryColor.withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: GestureDetector(
          onTap: onTap,
          child: Container(
            color: _baseColor.withOpacity(0.3),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ヘッダー（カテゴリラベル）
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getCategoryColor(context),
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
                      color: _baseColor.withOpacity(0.5),
                    ),
                    child: _buildImageWidget(context),
                  ),
                ),

                // 料理名
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    mealItem?.name ?? '料理名',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: _textColor,
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
                          color: _accentColor,
                        ),
                        const SizedBox(width: 2),
                        Flexible(
                          child: Text(
                            '変更',
                            style: TextStyle(
                              color: _accentColor,
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
        color: _baseColor.withOpacity(0.8),
        border: Border.all(
          color: _primaryColor.withOpacity(0.4),
          width: 2,
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: _primaryColor.withOpacity(0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: _baseColor.withOpacity(0.4),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.add,
                size: 48,
                color: _accentColor.withOpacity(0.8),
              ),
              const SizedBox(height: 8),
              Text(
                'もう一品追加',
                style: TextStyle(
                  color: _textColor,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageWidget(BuildContext context) {
    if (imageUrl != null) {
      return Image.network(
        imageUrl!,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildFallbackNetworkImage(context, mealItem?.name ?? title);
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) {
            return child;
          }
          return Center(
            child: CircularProgressIndicator(
              color: _accentColor,
              strokeWidth: 2,
            ),
          );
        },
      );
    } else {
      return _buildPlaceholderImage(context);
    }
  }

  Widget _buildPlaceholderImage(BuildContext context) {
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
            _baseColor.withOpacity(0.8),
            _baseColor.withOpacity(0.6),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            iconData,
            size: 48,
            color: _accentColor.withOpacity(0.8),
          ),
          const SizedBox(height: 8),
          Text(
            displayText,
            style: TextStyle(
              color: _textColor,
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  /// フォールバック用のネットワーク画像を構築
  Widget _buildFallbackNetworkImage(BuildContext context, String dishName) {
    final dishLower = dishName.toLowerCase();
    String fallbackUrl;

    // 料理タイプに応じたフォールバック画像
    if (dishLower.contains('炒め') || dishLower.contains('焼き')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1559847844-5315695dadae?w=512&h=512&fit=crop';
    } else if (dishLower.contains('煮') || dishLower.contains('煮物')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1565299624946-b28f40a0ca4b?w=512&h=512&fit=crop';
    } else if (dishLower.contains('サラダ') ||
        dishLower.contains('野菜') ||
        dishLower.contains('キャベツ')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1540420773420-3366772f4999?w=512&h=512&fit=crop';
    } else if (dishLower.contains('汁物') ||
        dishLower.contains('スープ') ||
        dishLower.contains('味噌汁')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1547592180-85f173990554?w=512&h=512&fit=crop';
    } else if (dishLower.contains('肉') ||
        dishLower.contains('豚') ||
        dishLower.contains('鶏')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1529692236671-f1f6cf9683ba?w=512&h=512&fit=crop';
    } else if (dishLower.contains('魚') ||
        dishLower.contains('鮭') ||
        dishLower.contains('鯖')) {
      fallbackUrl =
          'https://images.unsplash.com/photo-1544943910-4c1dc44aab44?w=512&h=512&fit=crop';
    } else {
      // デフォルトの料理画像
      fallbackUrl =
          'https://images.unsplash.com/photo-1546833999-b9f581a1996d?w=512&h=512&fit=crop';
    }

    return Image.network(
      fallbackUrl,
      fit: BoxFit.cover,
      errorBuilder: (context, error, stackTrace) {
        // フォールバック画像も失敗した場合はプレースホルダーを表示
        return _buildPlaceholderImage(context);
      },
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return Center(
          child: CircularProgressIndicator(
            color: _accentColor,
            strokeWidth: 2,
          ),
        );
      },
    );
  }

  Color _getCategoryColor(BuildContext context) {
    switch (title) {
      case '主菜':
        return _primaryColor.withOpacity(0.9);
      case '副菜':
        return _primaryColor.withOpacity(0.8);
      case '汁物':
        return _primaryColor.withOpacity(0.7);
      case 'もう一品':
        return _accentColor.withOpacity(0.8);
      default:
        return _secondaryColor.withOpacity(0.7);
    }
  }
}
