import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../scanner/presentation/pages/scanner_screen.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;
  
  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('商品詳細'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () => _showEditDialog(context),
            tooltip: '編集',
          ),
        ],
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
                  color: widget.product.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Center(
                  child: Text(
                    widget.product.emotionState,
                    style: const TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              widget.product.name,
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
                      value: widget.product.category,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.qr_code,
                      label: 'JANコード',
                      value: widget.product.janCode ?? '未設定',
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: '賞味期限',
                      value: widget.product.expiryDate != null
                          ? '${widget.product.expiryDate!.year}/${widget.product.expiryDate!.month}/${widget.product.expiryDate!.day}'
                          : '未設定',
                      valueColor: widget.product.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: '残り日数',
                      value: widget.product.expiryDate != null
                          ? '${widget.product.daysUntilExpiry}日'
                          : '—',
                      valueColor: widget.product.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.add_circle,
                      label: '登録日',
                      value: widget.product.scannedAt != null
                          ? '${widget.product.scannedAt!.year}/${widget.product.scannedAt!.month}/${widget.product.scannedAt!.day}'
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

  /// 編集ダイアログを表示
  void _showEditDialog(BuildContext context) {
    final nameController = TextEditingController(text: widget.product.name);
    String selectedCategory = widget.product.category;
    DateTime? selectedDate = widget.product.expiryDate;
    
    // 商品追加時と同じ色定数を使用（白ベース）
    const _dialogBackgroundColor = Colors.white; // 背景色（白）
    const _blockBackgroundColor = Color(0xFFE8F4FD); // ブロック背景色（薄い青系）
    const _blockAccentColor = Color(0xFF4A90C2); // ブロックアクセント色（濃い青系）
    const _textColor = Color(0xFF2C5F8A); // テキスト色（最も濃い青系）
    const _innerUIBackgroundColor = Color(0xFFF0F8FF); // UI内のUI背景色（薄い青系）
    const _innerUIBorderColor = Color(0xFFB8D8F0); // UI内のUIボーダー色（中間の青系）
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: _dialogBackgroundColor,
            title: const Text('商品を編集'),
            content: SizedBox(
              width: double.maxFinite,
              height: MediaQuery.of(context).size.height * 0.5,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // 商品名セクション
                    _buildInfoSection(
                      context: context,
                      icon: Icons.shopping_bag,
                      title: '商品名',
                      backgroundColor: _blockBackgroundColor,
                      iconColor: _blockAccentColor,
                      textColor: _textColor,
                      child: TextField(
                        controller: nameController,
                        decoration: InputDecoration(
                          hintText: '商品名を入力してください',
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _innerUIBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _innerUIBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _blockAccentColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          fillColor: _innerUIBackgroundColor,
                          filled: true,
                        ),
                        style: TextStyle(color: _textColor),
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // カテゴリセクション
                    _buildInfoSection(
                      context: context,
                      icon: Icons.category,
                      title: 'カテゴリ',
                      backgroundColor: _blockBackgroundColor,
                      iconColor: _blockAccentColor,
                      textColor: _textColor,
                      child: DropdownButtonFormField<String>(
                        value: selectedCategory,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _innerUIBorderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _innerUIBorderColor),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _blockAccentColor),
                          ),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          fillColor: _innerUIBackgroundColor,
                          filled: true,
                        ),
                        dropdownColor: _blockBackgroundColor,
                        style: TextStyle(color: _textColor),
                        items: const [
                          DropdownMenuItem(value: '飲料', child: Text('飲料')),
                          DropdownMenuItem(value: '食品', child: Text('食品')),
                          DropdownMenuItem(value: '調味料', child: Text('調味料')),
                          DropdownMenuItem(value: '冷凍食品', child: Text('冷凍食品')),
                          DropdownMenuItem(value: 'その他', child: Text('その他')),
                        ],
                        onChanged: (value) {
                          setState(() {
                            selectedCategory = value!;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 12),
                    
                    // 賞味期限セクション
                    _buildInfoSection(
                      context: context,
                      icon: Icons.calendar_today,
                      title: '賞味期限',
                      backgroundColor: _blockBackgroundColor,
                      iconColor: _blockAccentColor,
                      textColor: _textColor,
                      child: GestureDetector(
                        onTap: () async {
                          final date = await _showCustomDatePicker(
                            context: context,
                            initialDate: selectedDate ?? DateTime.now(),
                          );
                          if (date != null) {
                            setState(() {
                              selectedDate = date;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: _innerUIBackgroundColor,
                            border: Border.all(color: _innerUIBorderColor),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    selectedDate != null
                                        ? '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'
                                        : '日付を選択',
                                    style: TextStyle(
                                      color: selectedDate != null ? _textColor : Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (selectedDate != null)
                                    Text(
                                      _formatExpiryDate(selectedDate!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: _getExpiryDateColor(selectedDate!),
                                      ),
                                    ),
                                ],
                              ),
                              Icon(Icons.edit_calendar, size: 20, color: _textColor.withOpacity(0.6)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: Text(
                  'キャンセル',
                  style: TextStyle(color: _textColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final updatedProduct = widget.product.copyWith(
                      name: nameController.text,
                      category: selectedCategory,
                      expiryDate: selectedDate,
                    );
                    
                    // アプリ状態の商品を更新
                    ref.read(appStateProvider.notifier).updateProduct(updatedProduct);
                    
                    Navigator.pop(context);
                    // 編集完了の通知
                    _showProductUpdatedSnackBar(context, nameController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blockAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 情報セクションを構築
  Widget _buildInfoSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color backgroundColor,
    required Color iconColor,
    required Color textColor,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: iconColor, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  color: textColor,
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }

  /// カスタム日付ピッカーを表示
  Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
  }) async {
    return await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF4A90C2),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF2C5F8A),
            ),
          ),
          child: child!,
        );
      },
    );
  }

  /// 賞味期限の表示形式をフォーマット
  String _formatExpiryDate(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return '期限切れ';
    } else if (difference == 0) {
      return '今日が期限';
    } else if (difference <= 3) {
      return 'あと${difference}日で期限';
    } else {
      return 'あと${difference}日';
    }
  }

  /// 賞味期限の色を取得
  Color _getExpiryDateColor(DateTime date) {
    final now = DateTime.now();
    final difference = date.difference(now).inDays;
    
    if (difference < 0) {
      return Colors.red;
    } else if (difference <= 3) {
      return Colors.orange;
    } else {
      return Colors.green;
    }
  }

  /// 商品更新完了の通知を表示
  void _showProductUpdatedSnackBar(BuildContext context, String productName) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return AlertDialog(
          contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.check_circle,
                color: const Color(0xFF4A90C2),
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$productName を更新しました',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
    
    // 2秒後に自動で閉じる
    Future.delayed(const Duration(seconds: 2), () {
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    });
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