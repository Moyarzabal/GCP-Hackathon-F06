import 'package:flutter/material.dart';
import '../../../../shared/models/product.dart';

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  
  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品詳細'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: product.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    product.emotionState,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              product.name,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category,
                      label: 'カテゴリ',
                      value: product.category,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.qr_code,
                      label: 'JANコード',
                      value: product.janCode ?? '未設定',
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: '賞味期限',
                      value: product.expiryDate != null
                          ? '${product.expiryDate!.year}/${product.expiryDate!.month}/${product.expiryDate!.day}'
                          : '未設定',
                      valueColor: product.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: '残り日数',
                      value: product.expiryDate != null
                          ? '${product.daysUntilExpiry}日'
                          : '—',
                      valueColor: product.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.add_circle,
                      label: '登録日',
                      value: product.scannedAt != null
                          ? '${product.scannedAt!.year}/${product.scannedAt!.month}/${product.scannedAt!.day}'
                          : '未設定',
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: valueColor,
            ),
          ),
        ],
      ),
    );
  }
}