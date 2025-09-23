import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../presentation/providers/fridge_view_provider.dart';
import '../providers/drawer_state_provider.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';
import '../../../home/presentation/widgets/product_card.dart';
import '../../../products/presentation/providers/product_provider.dart';

class FridgeSectionView extends ConsumerWidget {
  const FridgeSectionView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fridgeState = ref.watch(fridgeViewProvider);
    final notifier = ref.read(fridgeViewProvider.notifier);
    final productState = ref.watch(productProvider);

    final products = _resolveProducts(
      productState.filteredProducts,
      fridgeState.selectedSection,
    );

    final title = _titleForSection(fridgeState.selectedSection);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () {
                  // 冷蔵庫セクション選択をクリア
                  notifier.clearSelection();
                  // 引き出し状態を正面ビューにリセット
                  ref.read(drawerStateProvider.notifier).backToFrontView();
                },
              ),
              Text(title, style: Theme.of(context).textTheme.titleMedium),
              const Spacer(),
              Text('${products.length} 件'),
            ],
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? _emptyState(context)
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: products.length,
                  itemBuilder: (context, index) {
                    final product = products[index];
                    return ProductCard(
                      product: product,
                      onTap: () => _showProductDetail(context, product),
                    );
                  },
                ),
        ),
      ],
    );
  }

  List<Product> _resolveProducts(
    List<Product> filteredProducts,
    SelectedFridgeSection? section,
  ) {
    if (section == null) {
      return filteredProducts;
    }

    return filteredProducts.where((product) {
      final location = product.location;
      if (location == null) {
        return section.compartment == FridgeCompartment.refrigerator &&
            section.level == 0;
      }
      return location.compartment == section.compartment &&
          location.level == section.level;
    }).toList();
  }

  String _titleForSection(SelectedFridgeSection? section) {
    if (section == null) return 'セクション';
    switch (section.compartment) {
      case FridgeCompartment.refrigerator:
        return '冷蔵室 棚${section.level + 1}';
      case FridgeCompartment.vegetableDrawer:
        return '野菜室';
      case FridgeCompartment.freezer:
        return '冷凍庫';
      case FridgeCompartment.doorLeft:
        return '左ドアポケット';
      case FridgeCompartment.doorRight:
        return '右ドアポケット';
    }
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inbox, size: 56, color: Colors.grey[400]),
          const SizedBox(height: 8),
          Text('このセクションにはまだ商品がありません',
              style: TextStyle(color: Colors.grey[600])),
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
