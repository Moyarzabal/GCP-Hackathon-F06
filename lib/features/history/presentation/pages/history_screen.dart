import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';

class HistoryScreen extends ConsumerWidget {
  const HistoryScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allProductsAsync = ref.watch(allProductsProvider);

    return allProductsAsync.when(
      data: (products) {
        final sortedProducts = List<Product>.from(products)
          ..sort((a, b) {
            final aDate = a.scannedAt ?? DateTime(0);
            final bDate = b.scannedAt ?? DateTime(0);
            return bDate.compareTo(aDate);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('スキャン履歴'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () {
                  _reloadHistory(ref);
                },
                tooltip: '履歴をリロード',
              ),
            ],
          ),
          body: sortedProducts.isEmpty
              ? RefreshIndicator(
                  onRefresh: () async {
                    _reloadHistory(ref);
                  },
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.7,
                      child: Center(
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
                            const SizedBox(height: 8),
                            Text(
                              '下にドラッグしてリロード',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[500],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async {
                    _reloadHistory(ref);
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: sortedProducts.length,
                    itemBuilder: (context, index) {
                    final product = sortedProducts[index];
                    final isDeleted = product.deletedAt != null;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 8),
                      color: isDeleted ? Colors.grey[100] : null,
                      child: InkWell(
                        onTap: () {
                          // 商品詳細画面に遷移
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ProductDetailScreen(product: product),
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(12),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // 商品画像
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: SizedBox(
                                  width: 48,
                                  height: 48,
                                  child: product.currentImageUrl != null
                                      ? _buildImageWidget(product)
                                      : Container(
                                          color: Colors.grey[300],
                                          child: Icon(
                                            Icons.image,
                                            color: Colors.grey[600],
                                          ),
                                        ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              // 商品情報
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      product.name,
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: isDeleted ? Colors.grey[600] : null,
                                        decoration: isDeleted ? TextDecoration.lineThrough : null,
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
                                    if (isDeleted) ...[
                                      const SizedBox(height: 4),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.red[100],
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          '削除済み',
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.red[700],
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              // カテゴリチップ
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
              ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stackTrace) => Center(
        child: Text('エラーが発生しました: $error'),
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
        // ネットワーク画像の場合
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

  /// 履歴データをリロード
  void _reloadHistory(WidgetRef ref) {
    print('🔄 履歴データをリロード中...');
    // allProductsProviderを無効化して再読み込み
    ref.invalidate(allProductsProvider);

    // リロード完了のフィードバック
    ScaffoldMessenger.of(ref.context).showSnackBar(
      SnackBar(
        content: const Text(
          '履歴をリロードしました',
          style: TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(ref.context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
      ),
    );
  }
}