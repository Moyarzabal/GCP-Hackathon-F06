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
import 'package:material_design_icons_flutter/material_design_icons_flutter.dart';

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
    
    // ソート済みの商品リストを使用
    final products = productState.filteredProducts;
    
    // デバッグログ: 商品リストの状態を確認
    print('🏠 HomeScreen: 商品リストの状態');
    print('   全商品数: ${appState.products.length}');
    print('   フィルター済み商品数: ${products.length}');
    print('   現在のソートタイプ: ${productState.sortType.displayName}');
    print('   現在のソート方向: ${productState.sortDirection.displayName}');
    for (var product in products) {
      print('   商品ID: ${product.id}, 名前: ${product.name}, 賞味期限: ${product.expiryDate}');
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
          // カテゴリ選択アイコン
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (category) {
              productNotifier.filterByCategory(category);
            },
            itemBuilder: (context) => availableCategories.map((category) {
              final isSelected = category == productState.selectedCategory;
              return PopupMenuItem(
                value: category,
                child: Row(
                  children: [
                    if (isSelected) const Icon(Icons.check, size: 16),
                    if (isSelected) const SizedBox(width: 8),
                    Text(category == 'all' ? 'すべて' : category),
                  ],
                ),
              );
            }).toList(),
          ),
          // Material Design Iconsのソートアイコン
          PopupMenuButton<ProductSortType>(
            icon: Icon(
              productState.sortDirection == SortDirection.ascending
                  ? MdiIcons.sortAscending
                  : MdiIcons.sortDescending,
              // color: Theme.of(context).colorScheme.primary,
            ),
            onSelected: (sortType) {
              productNotifier.setSortType(sortType);
            },
            itemBuilder: (context) => ProductSortType.values.map((sortType) {
              final isSelected = sortType == productState.sortType;
              return PopupMenuItem(
                value: sortType,
                child: Row(
                  children: [
                    if (isSelected) const Icon(Icons.check, size: 16),
                    if (isSelected) const SizedBox(width: 8),
                    Text(sortType.displayName),
                    const Spacer(),
                    if (isSelected)
                      Icon(
                        productState.sortDirection == SortDirection.ascending
                            ? MdiIcons.sortAscending
                            : MdiIcons.sortDescending,
                        size: 16,
                        // color: Theme.of(context).colorScheme.primary,
                      ),
                  ],
                ),
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
              backgroundColor: const Color(0xFFD4A5A5),
              child: const Icon(Icons.delete, color: Colors.black),
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
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFFF1D3CE).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.delete_outline,
                color: const Color(0xFFD4A5A5),
                size: 24,
              ),
            ),
            const SizedBox(width: 12),
            const Text(
              '商品を削除',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '選択された${selectionState.selectedCount}個の商品を削除しますか？',
              style: const TextStyle(fontSize: 16),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF1D3CE).withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0xFFD4A5A5).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.warning_amber_outlined,
                    color: const Color(0xFFB87B7B),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'この操作は取り消せません',
                      style: TextStyle(
                        color: const Color(0xFF8B5A5A),
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: const Text(
              'キャンセル',
              style: TextStyle(fontSize: 16),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFD4A5A5),
              foregroundColor: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 2,
            ),
            child: const Text(
              '削除',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
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