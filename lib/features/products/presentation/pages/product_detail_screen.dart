import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';
import 'package:table_calendar/table_calendar.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../../../../shared/utils/category_location_mapper.dart';
import '../../../scanner/presentation/pages/scanner_screen.dart';
import '../providers/product_provider.dart';

class ProductDetailScreen extends ConsumerStatefulWidget {
  final Product product;

  const ProductDetailScreen({
    Key? key,
    required this.product,
  }) : super(key: key);

  @override
  ConsumerState<ProductDetailScreen> createState() =>
      _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  @override
  Widget build(BuildContext context) {
    // 商品の状態を監視して最新の商品情報を取得
    final appState = ref.watch(appStateProvider);
    final currentProduct = appState.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );
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
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  color: currentProduct.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: currentProduct.currentImageUrl != null &&
                          currentProduct.currentImageUrl!.isNotEmpty
                      ? _buildImageWidget(currentProduct)
                      : Center(
                          child: Text(
                            currentProduct.emotionState,
                            style: const TextStyle(fontSize: 96),
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              currentProduct.name,
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
                      value: currentProduct.category,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.qr_code,
                      label: 'JANコード',
                      value: currentProduct.janCode ?? '未設定',
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: '賞味期限',
                      value: currentProduct.expiryDate != null
                          ? '${currentProduct.expiryDate!.year}/${currentProduct.expiryDate!.month}/${currentProduct.expiryDate!.day}'
                          : '未設定',
                      valueColor: currentProduct.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: '残り日数',
                      value: currentProduct.expiryDate != null
                          ? '${currentProduct.daysUntilExpiry}日'
                          : '—',
                      valueColor: currentProduct.statusColor,
                    ),
                    const Divider(),
                    _DetailRow(
                      icon: Icons.add_circle,
                      label: '登録日',
                      value: currentProduct.scannedAt != null
                          ? '${currentProduct.scannedAt!.year}/${currentProduct.scannedAt!.month}/${currentProduct.scannedAt!.day}'
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

  Widget _buildImageWidget(Product product) {
    try {
      // Base64画像データかどうかを判定
      if (product.currentImageUrl!.startsWith('data:image/')) {
        // Base64画像データの場合
        final base64String = product.currentImageUrl!.split(',')[1];
        final bytes = base64Decode(base64String);
        return Image.memory(
          bytes,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ Base64画像デコードエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 96),
              ),
            );
          },
        );
      } else {
        // 通常のURLの場合
        return Image.network(
          product.currentImageUrl!,
          width: 200,
          height: 200,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            print('❌ ネットワーク画像読み込みエラー: $error');
            return Center(
              child: Text(
                product.emotionState,
                style: const TextStyle(fontSize: 96),
              ),
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                            loadingProgress.expectedTotalBytes!
                        : null,
                    strokeWidth: 3,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '画像生成中...',
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            );
          },
        );
      }
    } catch (e) {
      print('❌ 画像表示エラー: $e');
      return Center(
        child: Text(
          product.emotionState,
          style: const TextStyle(fontSize: 96),
        ),
      );
    }
  }

  /// 編集ダイアログを表示
  void _showEditDialog(BuildContext context) {
    final appState = ref.read(appStateProvider);
    final currentProduct = appState.products.firstWhere(
      (p) => p.id == widget.product.id,
      orElse: () => widget.product,
    );
    final nameController = TextEditingController(text: currentProduct.name);
    final manufacturerController =
        TextEditingController(text: currentProduct.manufacturer ?? '');
    String selectedCategory = currentProduct.category;
    DateTime? selectedDate = currentProduct.expiryDate;

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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          fillColor: _innerUIBackgroundColor,
                          filled: true,
                        ),
                        style: TextStyle(color: _textColor),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // メーカーセクション
                    _buildInfoSection(
                      context: context,
                      icon: Icons.business,
                      title: 'メーカー',
                      backgroundColor: _blockBackgroundColor,
                      iconColor: _blockAccentColor,
                      textColor: _textColor,
                      child: TextField(
                        controller: manufacturerController,
                        decoration: InputDecoration(
                          hintText: 'メーカー名を入力してください（任意）',
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
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
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 8),
                          fillColor: _innerUIBackgroundColor,
                          filled: true,
                        ),
                        dropdownColor: _blockBackgroundColor,
                        style: TextStyle(color: _textColor),
                        items: const [
                          DropdownMenuItem(value: '飲料', child: Text('飲料')),
                          DropdownMenuItem(value: '食品', child: Text('食品')),
                          DropdownMenuItem(value: '調味料', child: Text('調味料')),
                          DropdownMenuItem(value: '野菜', child: Text('野菜')),
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
                                      color: selectedDate != null
                                          ? _textColor
                                          : Colors.grey,
                                      fontSize: 16,
                                    ),
                                  ),
                                  if (selectedDate != null)
                                    Text(
                                      _formatExpiryDate(selectedDate!),
                                      style: TextStyle(
                                        fontSize: 12,
                                        color:
                                            _getExpiryDateColor(selectedDate!),
                                      ),
                                    ),
                                ],
                              ),
                              Icon(Icons.edit_calendar,
                                  size: 20, color: _textColor.withOpacity(0.6)),
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
                    // カテゴリが変更された場合は適切な配置場所を自動設定
                    final newLocation = selectedCategory != currentProduct.category
                        ? CategoryLocationMapper.getDefaultLocationForCategory(selectedCategory)
                        : currentProduct.location;

                    final updatedProduct = currentProduct.copyWith(
                      name: nameController.text,
                      manufacturer: manufacturerController.text.isNotEmpty
                          ? manufacturerController.text
                          : null,
                      category: selectedCategory,
                      expiryDate: selectedDate,
                      location: newLocation,
                    );

                    // Firebaseで商品を更新
                    ref
                        .read(productProvider.notifier)
                        .editProduct(
                          currentProduct.id!,
                          updatedProduct,
                        )
                        .then((result) {
                      if (result.isSuccess) {
                        // ダイアログを閉じる
                        Navigator.pop(context);

                        // 編集完了の通知
                        _showProductUpdatedSnackBar(
                            context, nameController.text);
                      } else {
                        // エラー表示
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                '商品の更新に失敗しました: ${result.exception?.message}'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    });
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
    DateTime selectedDate = initialDate;
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDayInt = initialDate.day;

    final firstDate = DateTime(DateTime.now().year - 10, 1, 1);
    final lastDate = DateTime(DateTime.now().year + 10, 12, 31);

    return showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('賞味期限を選択'),
            contentPadding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
            content: SizedBox(
              width: 400,
              height: 450,
              child: Stack(
                children: [
                  // カレンダー
                  Padding(
                    padding: const EdgeInsets.only(top: 50),
                    child: TableCalendar<DateTime>(
                      firstDay: firstDate,
                      lastDay: lastDate,
                      focusedDay: selectedDate,
                      selectedDayPredicate: (day) {
                        return isSameDay(selectedDate, day);
                      },
                      onDaySelected: (selectedDay, focusedDay) {
                        if (!isSameDay(selectedDate, selectedDay)) {
                          setState(() {
                            selectedDate = selectedDay;
                            selectedYear = selectedDay.year;
                            selectedMonth = selectedDay.month;
                            selectedDayInt = selectedDay.day;
                          });
                        }
                      },
                      calendarFormat: CalendarFormat.month,
                      startingDayOfWeek: StartingDayOfWeek.sunday,
                      calendarStyle: CalendarStyle(
                        outsideDaysVisible: false,
                        selectedDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.primary,
                          shape: BoxShape.circle,
                        ),
                        todayDecoration: BoxDecoration(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withOpacity(0.5),
                          shape: BoxShape.circle,
                        ),
                        defaultDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        weekendDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        holidayDecoration: const BoxDecoration(
                          shape: BoxShape.circle,
                        ),
                        markerDecoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondary,
                          shape: BoxShape.circle,
                        ),
                      ),
                      headerStyle: HeaderStyle(
                        formatButtonVisible: false,
                        titleCentered: true,
                        titleTextStyle: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        leftChevronIcon: const Icon(Icons.chevron_left),
                        rightChevronIcon: const Icon(Icons.chevron_right),
                      ),
                      availableCalendarFormats: const {
                        CalendarFormat.month: '月表示',
                      },
                      locale: 'ja_JP',
                      onHeaderTapped: (date) => _showMonthYearPicker(
                          context, date, firstDate, lastDate, setState,
                          (newDate) {
                        setState(() {
                          // 選択した日付が有効な範囲内になるように調整
                          if (newDate.isBefore(firstDate)) {
                            selectedDate = firstDate;
                          } else if (newDate.isAfter(lastDate)) {
                            selectedDate = lastDate;
                          } else {
                            selectedDate = newDate;
                          }
                        });
                      }),
                    ),
                  ),
                  // 右上のボタン
                  Positioned(
                    top: 25,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // 今日ボタン
                        GestureDetector(
                          onTap: () {
                            // 今日の日付に移動
                            setState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.blue[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: Colors.blue[300]!,
                                width: 1.5,
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.today,
                                  size: 12,
                                  color: Colors.blue[700],
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  '今日',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(selectedDate),
                child: const Text('選択'),
              ),
            ],
          );
        },
      ),
    );
  }

  /// 月年選択ダイアログを表示
  void _showMonthYearPicker(
      BuildContext context,
      DateTime currentDate,
      DateTime firstDate,
      DateTime lastDate,
      StateSetter setState,
      Function(DateTime) onDateSelected) {
    int selectedYear = currentDate.year;
    int selectedMonth = currentDate.month;

    // 年の範囲を現在年±10年に設定
    final currentYear = DateTime.now().year;
    final minYear = currentYear - 10;
    final maxYear = currentYear + 10;
    final yearRange = maxYear - minYear + 1;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, dialogSetState) => AlertDialog(
          title: const Text('年月を選択'),
          content: SizedBox(
            width: 300,
            height: 300,
            child: Row(
              children: [
                // 年選択
                Expanded(
                  child: Column(
                    children: [
                      const Text('年',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          controller: FixedExtentScrollController(
                            initialItem: selectedYear - minYear,
                          ),
                          onSelectedItemChanged: (index) {
                            dialogSetState(() {
                              selectedYear = minYear + index;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              if (index >= yearRange) return null;
                              return Center(
                                child: Text(
                                  '${minYear + index}年',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selectedYear == minYear + index
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedYear == minYear + index
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black,
                                  ),
                                ),
                              );
                            },
                            childCount: yearRange,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                // 月選択
                Expanded(
                  child: Column(
                    children: [
                      const Text('月',
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      Expanded(
                        child: ListWheelScrollView.useDelegate(
                          itemExtent: 40,
                          controller: FixedExtentScrollController(
                            initialItem: selectedMonth - 1,
                          ),
                          onSelectedItemChanged: (index) {
                            dialogSetState(() {
                              selectedMonth = index + 1;
                            });
                          },
                          childDelegate: ListWheelChildBuilderDelegate(
                            builder: (context, index) {
                              return Center(
                                child: Text(
                                  '${index + 1}月',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selectedMonth == index + 1
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedMonth == index + 1
                                        ? Theme.of(context).colorScheme.primary
                                        : Colors.black,
                                  ),
                                ),
                              );
                            },
                            childCount: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: () {
                final newDate = DateTime(selectedYear, selectedMonth, 1);
                onDateSelected(newDate);
                Navigator.of(context).pop();
              },
              child: const Text('選択'),
            ),
          ],
        ),
      ),
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
