import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../widgets/product_card.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../../shared/widgets/common/error_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final productState = ref.watch(productProvider);
    final productNotifier = ref.watch(productProvider.notifier);
    final availableCategories = ref.watch(availableCategoriesProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          '冷蔵庫の中身',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(appState.products),
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
                      color: isSelected ? Colors.white : null,
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
            child: productState.filteredProducts.isEmpty
                ? _buildEmptyState(context)
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: productState.filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = productState.filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => _showProductDetail(context, product),
                      );
                    },
                  ),
          ),
        ],
      ),
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
}