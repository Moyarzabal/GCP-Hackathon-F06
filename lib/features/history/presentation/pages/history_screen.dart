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
                  child: ListTile(
                    leading: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          product.emotionState,
                          style: const TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      product.scannedAt != null 
                          ? '${product.scannedAt!.year}/${product.scannedAt!.month}/${product.scannedAt!.day} ${product.scannedAt!.hour}:${product.scannedAt!.minute.toString().padLeft(2, '0')}'
                          : '登録日不明',
                    ),
                    trailing: Chip(
                      label: Text(
                        product.category,
                        style: const TextStyle(fontSize: 12),
                      ),
                      backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
                    ),
                  ),
                );
              },
            ),
    );
  }
}