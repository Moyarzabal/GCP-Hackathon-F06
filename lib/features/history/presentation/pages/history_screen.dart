import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsProvider);
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) {
        final aDate = a.scannedAt ?? DateTime(0);
        final bDate = b.scannedAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('スキャン履歴'),
      ),
      body: sortedProducts.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.history,
                    size: 80,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    '履歴がありません',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: sortedProducts.length,
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 8),
                  child: InkWell(
                    onTap: () {
                      // タップ時の処理（必要に応じて実装）
                    },
                    borderRadius: BorderRadius.circular(12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: product.currentImageUrl != null && product.currentImageUrl!.isNotEmpty
                                  ? _buildImageWidget(product)
                                  : Center(
                                      child: Text(
                                        product.emotionState,
                                        style: const TextStyle(fontSize: 24),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  product.scannedAt != null 
                                      ? '${product.scannedAt!.year}/${product.scannedAt!.month}/${product.scannedAt!.day} ${product.scannedAt!.hour}:${product.scannedAt!.minute.toString().padLeft(2, '0')}'
                                      : '登録日不明',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Chip(
                            label: Text(
                              product.category,
                              style: const TextStyle(fontSize: 12),
                            ),
                            backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }

  /// 画像ウィジェットを構築（Base64とネットワーク画像に対応）
  Widget _buildImageWidget(Product product) {
    try {
      // Base64画像データかどうかを判定
      if (product.currentImageUrl!.startsWith('data:image/')) {
        // Base64画像データの場合
        final base64String = product.currentImageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Base64画像デコードエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 24),
              ),
            );
          },
        );
      } else {
        // 通常のURLの場合
        return Image.network(
          product.currentImageUrl!,
          width: 48,
          height: 48,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ネットワーク画像読み込みエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 24),
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
          style: const TextStyle(fontSize: 24),
        ),
      );
    }
  }
}