import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';

class ProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback onTap;
  final bool isSelectionMode;
  final bool isSelected;
  final VoidCallback? onLongPress;
  final VoidCallback? onSelectionToggle;

  const ProductCard({
    Key? key,
    required this.product,
    required this.onTap,
    this.isSelectionMode = false,
    this.isSelected = false,
    this.onLongPress,
    this.onSelectionToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 最新の商品情報を取得（appStateProviderを使用）
    final appState = ref.watch(appStateProvider);
    final currentProduct = appState.products.firstWhere(
      (p) => p.id == product.id,
      orElse: () => product,
    );

    // デバッグログ: 商品の状態を確認
    print('🔍 ProductCard: 商品の状態');
    print('   商品ID: ${currentProduct.id}');
    print('   商品名: ${currentProduct.name}');
    print('   画像URL: ${currentProduct.imageUrl}');
    print('   現在の画像URL: ${currentProduct.currentImageUrl}');
    print('   画像段階: ${currentProduct.currentImageStage}');
    print('   複数画像数: ${currentProduct.imageUrls?.length ?? 0}');
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: isSelectionMode ? onSelectionToggle : onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(12),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: currentProduct.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: currentProduct.currentImageUrl != null && currentProduct.currentImageUrl!.isNotEmpty
              ? _buildImageWidget(currentProduct)
              : Center(
                  child: Text(
                    currentProduct.emotionState,
                    style: const TextStyle(fontSize: 32),
                  ),
                ),
        ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      currentProduct.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.category, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          currentProduct.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Icon(Icons.access_time, size: 14, color: Colors.grey),
                        const SizedBox(width: 4),
                        Text(
                          currentProduct.expiryDate != null
                              ? '${currentProduct.daysUntilExpiry}日後'
                              : '期限なし',
                          style: TextStyle(
                            fontSize: 12,
                            color: currentProduct.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
                ],
              ),
            ),
            // 選択モード時のオーバーレイ
            if (isSelectionMode)
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isSelected
                        ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                        : Colors.transparent,
                    border: Border.all(
                      color: isSelected
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey[400]!,
                      width: 2,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(12),
                    ),
                  ),
                  child: Checkbox(
                    value: isSelected,
                    onChanged: (value) => onSelectionToggle?.call(),
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: VisualDensity.compact,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
  Widget _buildImageWidget(Product product) {
    try {
      // Base64画像データかどうかを判定
      if (product.currentImageUrl!.startsWith('data:image/')) {
        // Base64画像データの場合
        final base64String = product.currentImageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Base64画像デコードエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 32),
              ),
            );
          },
        );
      } else {
        // 通常のURLの場合
        return Image.network(
          product.currentImageUrl!,
          width: 60,
          height: 60,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ネットワーク画像読み込みエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 32),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded /
                        loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2,
              ),
            );
          },
        );
      }
    } catch (e) {
      print('❌ 画像表示エラー: $e');
      return Center(
        child: Text(
          product.emotionState,
          style: const TextStyle(fontSize: 32),
        ),
      );
    }
  }
}