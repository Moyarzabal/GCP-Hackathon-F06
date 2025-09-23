import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';
import '../../../products/presentation/providers/product_provider.dart';
import '../../../../shared/widgets/common/error_widget.dart';
import '../../../fridge/presentation/providers/fridge_view_provider.dart';
// import '../../../fridge/presentation/widgets/fridge_overview_widget.dart';
import '../../../fridge/presentation/pages/fridge_section_view.dart';
// import '../../../fridge/presentation/widgets/realistic_fridge_widget.dart';
// import '../../../fridge/presentation/widgets/tesla_style_fridge_widget.dart';
import '../../../fridge/presentation/widgets/enhanced_fridge_widget.dart';
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
    final availableCategoriesAsync = ref.watch(availableCategoriesProvider);

    final fridgeState = ref.watch(fridgeViewProvider);
    final fridgeNotifier = ref.watch(fridgeViewProvider.notifier);
    final isListViewActive = fridgeState.selectedSection != null;

    // ソート済みの商品リストを使用
    final products = productState.filteredProducts;

    // デバッグログ: 商品リストの状態を確認
    print('🏠 HomeScreen: 商品リストの状態');
    print('   全商品数: ${appState.products.length}');
    print('   フィルター済み商品数: ${products.length}');
    print('   現在のソートタイプ: ${productState.sortType.displayName}');
    print('   現在のソート方向: ${productState.sortDirection.displayName}');
    for (var product in products) {
      print(
          '   商品ID: ${product.id}, 名前: ${product.name}, 賞味期限: ${product.expiryDate}');
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edibuddy',
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
          if (isListViewActive)
            availableCategoriesAsync.when(
              data: (availableCategories) => PopupMenuButton<String>(
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
                        Text(category == 'すべて' ? 'すべて' : category),
                      ],
                    ),
                  );
                }).toList(),
              ),
              loading: () => const SizedBox.shrink(),
              error: (error, stack) => const SizedBox.shrink(),
            ),
          if (isListViewActive)
            PopupMenuButton<ProductSortType>(
              icon: Icon(
                productState.sortDirection == SortDirection.ascending
                    ? MdiIcons.sortAscending
                    : MdiIcons.sortDescending,
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

          // 冷蔵庫ビュー
          Expanded(
              child: _buildFridgeView(context, fridgeState, fridgeNotifier)),
        ],
      ),
    );
  }

  Widget _buildFridgeView(BuildContext context, FridgeViewState state,
      FridgeViewNotifier notifier) {
    return Column(
      key: const ValueKey('fridgeView'),
      children: [
        if (state.selectedSection == null)
          Expanded(
            child: EnhancedFridgeWidget(
              onSectionTap: (compartment, level) {
                notifier.selectSection(SelectedFridgeSection(
                    compartment: compartment, level: level));
              },
            ),
          )
        else
          const Expanded(child: FridgeSectionView()),
      ],
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
}
