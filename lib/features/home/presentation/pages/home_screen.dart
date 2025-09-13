import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../widgets/product_card.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../products/presentation/providers/product_selection_provider.dart';
import '../../../../shared/widgets/common/error_widget.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Firebaseから商品データをストリーム監視
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(appStateProvider.notifier).watchProductsFromFirebase();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    final appState = ref.watch(appStateProvider);
    final productState = ref.watch(productProvider);
    final productNotifier = ref.watch(productProvider.notifier);
    final availableCategories = ref.watch(availableCategoriesProvider);
    final selectionState = ref.watch(productSelectionProvider);
    final selectionNotifier = ref.watch(productSelectionProvider.notifier);
    
    // appStateProviderの商品リストを使用（画像更新が反映される）
    final products = appState.products;
    
    // デバッグログ: 商品リストの状態を確認
    print('🏠 HomeScreen: 商品リストの状態');
    print('   商品数: ${products.length}');
    for (var product in products) {
      print('   商品ID: ${product.id}, 名前: ${product.name}, 画像URL: ${product.imageUrl}');
    }
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '冷蔵庫の中身',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _reloadProducts();
            },
            tooltip: 'データをリロード',
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(products),
              );
            },
          ),
          PopupMenuButton<ProductSortType>(
            icon: const Icon(Icons.sort),
            onSelected: (sortType) {
              productNotifier.setSortType(sortType);
            },
            itemBuilder: (context) => ProductSortType.values.map((sortType) {
              return PopupMenuItem(
                value: sortType,
                child: Text(sortType.displayName),
              );
            }).toList(),
          ),
        ],
      ),
      body: Column(
        children: [
          // エラー表示
          if (appState.error != null)
            InlineErrorWidget(
              message: appState.error!,
              onDismiss: () {
                ref.read(appStateProvider.notifier).clearError();
              },
            ),
          // ローディング表示
          if (appState.isLoading)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
          // カテゴリフィルター
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: availableCategories.length,
              itemBuilder: (context, index) {
                final category = availableCategories[index];
                final isSelected = category == productState.selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category == 'all' ? 'すべて' : category),
                    selected: isSelected,
                    onSelected: (selected) {
                      productNotifier.filterByCategory(category);
                    },
                    backgroundColor: isSelected 
                      ? Theme.of(context).colorScheme.primary 
                      : null,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.black : null,
                    ),
                  ),
                );
              },
            ),
          ),
          
          // エラー表示
          if (productState.error != null)
            InlineErrorWidget(
              message: productState.error!,
              onDismiss: () => productNotifier.clearError(),
            ),
          
          // 商品リスト
          Expanded(
            child: products.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return ProductCard(
                        product: product,
                        isSelectionMode: selectionState.isSelectionMode,
                        isSelected: selectionState.isSelected(product.id ?? ''),
                        onTap: () => _showProductDetail(context, product),
                        onLongPress: () => selectionNotifier.toggleSelectionMode(),
                        onSelectionToggle: () => selectionNotifier.toggleProductSelection(product.id ?? ''),
                      );
                    },
                  ),
          ),
        ],
      ),
      // 削除ボタン（選択された商品がある場合のみ表示）
      floatingActionButton: selectionState.selectedProductIds.isNotEmpty
          ? FloatingActionButton(
              onPressed: () => _showDeleteConfirmation(context, selectionNotifier),
              backgroundColor: Colors.red,
              child: const Icon(Icons.delete, color: Colors.white),
            )
          : null,
    );
  }
  
  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.kitchen,
            size: 80,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            '冷蔵庫は空です',
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'バーコードをスキャンして\n商品を追加しましょう',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
  
  void _showProductDetail(BuildContext context, Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  /// 商品データをリロード
  void _reloadProducts() {
    print('🔄 商品データをリロード中...');
    ref.read(appStateProvider.notifier).watchProductsFromFirebase();
    
    // リロード完了のフィードバック
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'データをリロードしました',
          style: TextStyle(fontSize: 14),
        ),
        duration: const Duration(seconds: 2),
        backgroundColor: Theme.of(context).colorScheme.primary,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        elevation: 4,
      ),
    );
  }

  /// 削除確認ダイアログを表示
  Future<void> _showDeleteConfirmation(BuildContext context, ProductSelectionNotifier selectionNotifier) async {
    final selectionState = ref.read(productSelectionProvider);
    
    // デバッグログ: 選択状態を確認
    print('🗑️ 削除確認ダイアログ: 選択状態');
    print('   選択モード: ${selectionState.isSelectionMode}');
    print('   選択数: ${selectionState.selectedCount}');
    print('   選択された商品ID: ${selectionState.selectedProductIds}');
    
    if (selectionState.selectedCount == 0) {
      // 選択された商品がない場合
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              '削除する商品を選択してください',
              style: TextStyle(fontSize: 14),
            ),
            duration: const Duration(seconds: 2),
            backgroundColor: Theme.of(context).colorScheme.error,
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 4,
          ),
        );
      }
      return;
    }
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品を削除'),
        content: Text('選択された${selectionState.selectedCount}個の商品を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('削除'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      // 削除実行
      final result = await selectionNotifier.deleteSelectedProducts();
      
      if (result.isSuccess) {
        // 成功時のスナックバー表示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${selectionState.selectedCount}個の商品を削除しました',
                style: const TextStyle(fontSize: 14),
              ),
              duration: const Duration(seconds: 2),
              backgroundColor: Theme.of(context).colorScheme.primary,
              behavior: SnackBarBehavior.floating,
              margin: const EdgeInsets.only(bottom: 16, left: 16, right: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 4,
            ),
          );
        }
      } else {
        // エラー時のスナックバー表示
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '削除に失敗しました: ${result.exception?.message ?? '不明なエラー'}',
                style: const TextStyle(fontSize: 14),
              ),
              duration: const Duration(seconds: 3),
              backgroundColor: Theme.of(context).colorScheme.error,
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
    }
  }
}