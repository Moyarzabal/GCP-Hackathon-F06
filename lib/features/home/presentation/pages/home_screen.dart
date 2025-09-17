import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../widgets/product_card.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../../shared/widgets/common/error_widget.dart';
import '../../../fridge/presentation/providers/fridge_view_provider.dart';
// import '../../../fridge/presentation/widgets/fridge_overview_widget.dart';
import '../../../fridge/presentation/pages/fridge_section_view.dart';
// import '../../../fridge/presentation/widgets/realistic_fridge_widget.dart';
// import '../../../fridge/presentation/widgets/tesla_style_fridge_widget.dart';
import '../../../fridge/presentation/widgets/layered_3d_fridge_widget.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({Key? key}) : super(key: key);
  
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final productState = ref.watch(productProvider);
    final productNotifier = ref.watch(productProvider.notifier);
    final availableCategories = ref.watch(availableCategoriesProvider);
    
    final fridgeState = ref.watch(fridgeViewProvider);
    final fridgeNotifier = ref.watch(fridgeViewProvider.notifier);

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
          // 表示モード切替（リスト | 冷蔵庫）
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: SegmentedButton<FridgeViewMode>(
              segments: const [
                ButtonSegment(value: FridgeViewMode.list, label: Text('リスト')),
                ButtonSegment(value: FridgeViewMode.fridge, label: Text('冷蔵庫')),
              ],
              selected: {fridgeState.mode},
              onSelectionChanged: (selection) {
                final mode = selection.first;
                fridgeNotifier.setMode(mode);
              },
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
          
          // 表示切替（AnimatedSwitcher）
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: fridgeState.mode == FridgeViewMode.list
                  ? _buildProductList(context, productState)
                  : _buildFridgeView(context, fridgeState, fridgeNotifier),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProductList(BuildContext context, ProductState productState) {
    if (productState.filteredProducts.isEmpty) {
      return _buildEmptyState(context);
    }
    return ListView.builder(
      key: const ValueKey('listView'),
      padding: const EdgeInsets.all(16),
      itemCount: productState.filteredProducts.length,
      itemBuilder: (context, index) {
        final product = productState.filteredProducts[index];
        return ProductCard(
          product: product,
          onTap: () => _showProductDetail(context, product),
        );
      },
    );
  }

  Widget _buildFridgeView(BuildContext context, FridgeViewState state, FridgeViewNotifier notifier) {
    return Column(
      key: const ValueKey('fridgeView'),
      children: [
        if (state.selectedSection == null)
          Expanded(
            child: Layered3DFridgeWidget(
              onSectionTap: (compartment, level) {
                notifier.selectSection(SelectedFridgeSection(compartment: compartment, level: level));
              },
            ),
          )
        else
          const Expanded(child: FridgeSectionView()),
      ],
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