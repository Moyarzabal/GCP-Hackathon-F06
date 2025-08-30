import 'package:flutter/material.dart';
import '../../../../shared/models/product.dart';
import '../pages/product_detail_screen.dart';

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  
  ProductSearchDelegate(this.products);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: const Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.arrow_back),
      onPressed: () {
        close(context, null);
      },
    );
  }
  
  @override
  Widget buildResults(BuildContext context) {
    final results = products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    return ListView.builder(
      itemCount: results.length,
      itemBuilder: (context, index) {
        final product = results[index];
        return ListTile(
          leading: Text(product.emotionState, style: const TextStyle(fontSize: 24)),
          title: Text(product.name),
          subtitle: Text('${product.category} • ${product.daysUntilExpiry}日後'),
          onTap: () {
            close(context, product);
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductDetailScreen(product: product),
              ),
            );
          },
        );
      },
    );
  }
  
  @override
  Widget buildSuggestions(BuildContext context) {
    final suggestions = products
        .where((p) => p.name.toLowerCase().contains(query.toLowerCase()))
        .toList();
    
    return ListView.builder(
      itemCount: suggestions.length,
      itemBuilder: (context, index) {
        final product = suggestions[index];
        return ListTile(
          leading: Text(product.emotionState, style: const TextStyle(fontSize: 24)),
          title: Text(product.name),
          subtitle: Text(product.category),
          onTap: () {
            query = product.name;
            showResults(context);
          },
        );
      },
    );
  }
}