import 'package:flutter/material.dart';
import '../../../../shared/models/product.dart';
import '../widgets/product_card.dart';
import '../../../products/presentation/pages/product_detail_screen.dart';
import '../../../products/presentation/widgets/product_search_delegate.dart';

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  
  const HomeScreen({
    Key? key,
    required this.products,
    required this.onProductTap,
  }) : super(key: key);
  
  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _selectedCategory = 'すべて';
  String _sortBy = 'expiry';
  
  final List<String> categories = [
    'すべて',
    '飲料',
    '食品',
    '調味料',
    '冷凍食品',
    'その他'
  ];

  List<Product> get filteredProducts {
    var filtered = widget.products.where((p) {
      if (_selectedCategory == 'すべて') return true;
      return p.category == _selectedCategory;
    }).toList();
    
    if (_sortBy == 'expiry') {
      filtered.sort((a, b) => a.daysUntilExpiry.compareTo(b.daysUntilExpiry));
    } else if (_sortBy == 'name') {
      filtered.sort((a, b) => a.name.compareTo(b.name));
    } else if (_sortBy == 'date') {
      filtered.sort((a, b) {
        final aDate = a.scannedAt ?? DateTime(0);
        final bDate = b.scannedAt ?? DateTime(0);
        return bDate.compareTo(aDate);
      });
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
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
                delegate: ProductSearchDelegate(widget.products),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'expiry', child: Text('賞味期限順')),
              const PopupMenuItem(value: 'name', child: Text('名前順')),
              const PopupMenuItem(value: 'date', child: Text('登録日順')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          SizedBox(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        _selectedCategory = category;
                      });
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
          Expanded(
            child: filteredProducts.isEmpty
                ? Center(
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
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: filteredProducts.length,
                    itemBuilder: (context, index) {
                      final product = filteredProducts[index];
                      return ProductCard(
                        product: product,
                        onTap: () => widget.onProductTap(product),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}