import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:table_calendar/table_calendar.dart';
import 'dart:math' as math;
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../providers/scanner_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_button.dart';
import '../../../../shared/widgets/adaptive/adaptive_loading.dart';
import '../../../../shared/widgets/common/error_widget.dart';
import '../../../products/presentation/providers/product_provider.dart';

// 共通のカテゴリリスト
const List<String> _defaultCategories = [
  '飲料',
  '食品', 
  '調味料',
  '冷凍食品',
  'その他'
];

// AI予測系UIの色
const Color _aiPredictionColor = Color(0xFFEECAD5);
const Color _aiPredictionTextColor = Color(0xFFC895A8); // さらに濃い色
const Color _aiPredictionDarkColor = Color(0xFFB88598); // 最も濃い色

// 商品情報UIの配色（#D1E9F6系列）
const Color _dialogBackgroundColor = Colors.white; // 背景色（白）
const Color _blockBackgroundColor = Color(0xFFE8F4FD); // ブロック背景色（薄い青系）
const Color _blockAccentColor = Color(0xFF4A90C2); // ブロックアクセント色（濃い青系）
const Color _textColor = Color(0xFF2C5F8A); // テキスト色（最も濃い青系）
const Color _innerUIBackgroundColor = Color(0xFFF0F8FF); // UI内のUI背景色（薄い青系）
const Color _innerUIBorderColor = Color(0xFFB8D8F0); // UI内のUIボーダー色（中間の青系）

// カテゴリのアイコンマッピング
const Map<String, IconData> _categoryIcons = {
  '飲料': Icons.local_drink,
  '食品': Icons.restaurant,
  '調味料': Icons.kitchen,
  '冷凍食品': Icons.ac_unit,
  'その他': Icons.category,
};

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {

  @override
  void initState() {
    super.initState();
    // 初期状態ではカメラもスキャンも停止状態
    WidgetsBinding.instance.addPostFrameCallback((_) {
      // カメラは初期化しない（スキャン開始時に初期化）
      ref.read(scannerProvider.notifier).stopScanning();
    });
  }

  void _showProductDialog(Product product) {
    DateTime? selectedDate = product.expiryDate; // AI予測日付をデフォルト値に設定
    String selectedCategory = _defaultCategories.contains(product.category) ? product.category : _defaultCategories.first;
    final aiPredictedDate = product.expiryDate; // AI予測日付を保存
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          return StatefulBuilder(
        builder: (context, setState) {
              // 共通のカテゴリリストを使用
              final categoryOptions = _defaultCategories;

              // デバッグ情報を追加
              print('Category options: $categoryOptions');
              print('Selected category: $selectedCategory');
          return AlertDialog(
            backgroundColor: _dialogBackgroundColor,
            title: const Text('商品情報'),
            content: SingleChildScrollView(
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
                    child: Text(
                      product.name,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w500, color: _textColor),
                    ),
                  ),
                  // メーカー情報セクション
                  if (product.manufacturer != null && product.manufacturer!.isNotEmpty)
                    _buildInfoSection(
                      context: context,
                      icon: Icons.business,
                      title: 'メーカー',
                      backgroundColor: _blockBackgroundColor,
                      iconColor: _blockAccentColor,
                      textColor: _textColor,
                      child: Text(
                        product.manufacturer!,
                        style: TextStyle(fontSize: 16, color: _textColor),
                      ),
                    ),
                  // 賞味期限セクション
                  _buildInfoSection(
                    context: context,
                    icon: Icons.calendar_today,
                    title: '賞味期限',
                    backgroundColor: _blockBackgroundColor,
                    iconColor: _blockAccentColor,
                    textColor: _textColor,
                    child: InkWell(
                    onTap: () async {
                        final date = await _showCustomDatePicker(
                        context: context,
                          initialDate: selectedDate ?? aiPredictedDate ?? DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime(DateTime.now().year - 10, 1, 1),
                        lastDate: DateTime(DateTime.now().year + 10, 12, 31),
                          aiPredictedDate: aiPredictedDate,
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
                                      : (aiPredictedDate != null
                                          ? '${aiPredictedDate!.year}/${aiPredictedDate!.month}/${aiPredictedDate!.day}'
                                          : '日付を選択'),
                                  style: TextStyle(
                                    color: (selectedDate != null || aiPredictedDate != null) ? _textColor : Colors.grey,
                                    fontSize: 16,
                                  ),
                                ),
                                if (selectedDate != null || aiPredictedDate != null)
                                  Text(
                                    _formatExpiryDate(selectedDate ?? aiPredictedDate!),
                            style: TextStyle(
                                      fontSize: 12,
                                      color: _getExpiryDateColor(selectedDate ?? aiPredictedDate!),
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
                        filled: true,
                        fillColor: _innerUIBackgroundColor,
                        border: OutlineInputBorder(
                          borderSide: BorderSide(color: _innerUIBorderColor),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _innerUIBorderColor),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderSide: BorderSide(color: _blockAccentColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      ),
                      items: _defaultCategories.map((String category) {
                        return DropdownMenuItem<String>(
                          value: category,
                          child: Row(
                            children: [
                              Icon(
                                _categoryIcons[category] ?? Icons.category,
                                size: 16,
                                color: _textColor,
                              ),
                              const SizedBox(width: 8),
                              Text(category, style: TextStyle(color: _textColor)),
                            ],
                          ),
                        );
                      }).toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCategory = newValue;
                          });
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  ref.read(scannerProvider.notifier).clearLastScannedCode();
                },
                child: const Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  // 賞味期限とカテゴリを更新
                  final updatedProduct = product.copyWith(
                    expiryDate: selectedDate,
                    category: selectedCategory,
                  );
                  
                  // アプリ状態に商品を更新
                  ref.read(appStateProvider.notifier).updateProduct(updatedProduct);
                  
                  Navigator.pop(context);
                  ref.read(scannerProvider.notifier).clearLastScannedCode();
                  
                  // 商品追加完了の通知
                  _showProductAddedSnackBar(context, product.name);
                },
                child: const Text('保存'),
              ),
            ],
          );
            },
          );
        },
      ),
    );
  }
  
  void _showManualInput() {
    // 手動登録時はスキャンを停止
    ref.read(scannerProvider.notifier).stopScanning();
    final nameController = TextEditingController();
    String selectedCategory = '食品';
    DateTime? selectedDate;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            backgroundColor: _dialogBackgroundColor,
            title: const Text('手動で商品を追加'),
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
                      items: _defaultCategories
                          .map((cat) => DropdownMenuItem(
                                value: cat,
                                child: Row(
                                  children: [
                                    Icon(
                                      _categoryIcons[cat] ?? Icons.category,
                                      size: 16,
                                      color: _textColor,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(cat, style: TextStyle(color: _textColor)),
                                  ],
                                ),
                              ))
                          .toList(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            selectedCategory = value;
                          });
                        }
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
                    child: InkWell(
                      onTap: () async {
                        final date = await showDatePicker(
                          context: context,
                          initialDate: DateTime.now().add(const Duration(days: 7)),
                          firstDate: DateTime(DateTime.now().year - 10, 1, 1),
                          lastDate: DateTime(DateTime.now().year + 10, 12, 31),
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
                            Text(
                              selectedDate != null
                                  ? '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'
                                  : '日付を選択',
                              style: TextStyle(
                                color: (selectedDate != null) ? _textColor : Colors.grey,
                                fontSize: 16,
                              ),
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
                  ref.read(scannerProvider.notifier).clearLastScannedCode();
                  // 手動登録キャンセル時はスキャンを再開
                  ref.read(scannerProvider.notifier).startScanning();
                },
                child: Text(
                  'キャンセル',
                  style: TextStyle(color: _textColor),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final product = Product(
                      id: DateTime.now().millisecondsSinceEpoch.toString(),
                      janCode: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      category: selectedCategory,
                      scannedAt: DateTime.now(),
                      addedDate: DateTime.now(),
                      expiryDate: selectedDate,
                    );
                    
                    // アプリ状態に商品を追加
                    ref.read(appStateProvider.notifier).addProduct(product);
                    
                    Navigator.pop(context);
                    // 手動登録完了時はスキャンを再開
                    ref.read(scannerProvider.notifier).startScanning();
                    // 商品追加完了の通知
                    _showProductAddedSnackBar(context, nameController.text);
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _blockAccentColor,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: const Text('追加'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    try {
    final scannerState = ref.watch(scannerProvider);
    final scannerNotifier = ref.watch(scannerProvider.notifier);
    // デバッグ用ログ
    print('🖥️ UI状態: isScanning=${scannerState.isScanning}, isProcessingProduct=${scannerState.isProcessingProduct}, isCameraActive=${scannerState.isCameraActive}');
    return Scaffold(
      appBar: AppBar(
        title: const Text('バーコードスキャン'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: _showManualInput,
            tooltip: '手動入力',
          ),
        ],
      ),
      body: Column(
        children: [
          // エラー表示
          if (scannerState.error != null)
            InlineErrorWidget(
              message: scannerState.error!,
              onDismiss: () => scannerNotifier.clearError(),
            ),
          
          Expanded(
            child: (scannerState.isCameraActive && scannerState.isScanning)
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: scannerNotifier.controller,
                        onDetect: (capture) {
                          _handleBarcodeDetection(capture, scannerNotifier);
                        },
                      ),
                      // スキャンガイド
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black54,
                          child: Column(
                            children: [
                              const Text(
                            'バーコードを枠内に合わせてください',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.qr_code_scanner,
                                    color: Colors.white,
                                    size: 20,
                                  ),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'カメラを商品のバーコードに向けてください',
                                    style: TextStyle(
                                      color: Colors.white70,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                      // スキャン枠のオーバーレイ
                      Center(
                        child: Container(
                          width: 280,
                          height: 180,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                              width: 2,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Stack(
                            children: [
                              // コーナーマーカー
                              Positioned(
                                top: 0,
                                left: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                      left: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                top: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      top: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                      right: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                left: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                      left: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                              Positioned(
                                bottom: 0,
                                right: 0,
                                child: Container(
                                  width: 20,
                                  height: 20,
                                  decoration: BoxDecoration(
                                    border: Border(
                                      bottom: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                      right: BorderSide(
                                        color: Theme.of(context).colorScheme.primary,
                                        width: 3,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      // 商品情報処理中のローディング表示
                      if (scannerState.isProcessingProduct)
                        Container(
                          color: Colors.black54,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const CircularProgressIndicator(
                            color: Colors.white,
                                  strokeWidth: 3,
                                ),
                                const SizedBox(height: 16),
                                const Text(
                                  '商品情報を検索中...',
                                  style: TextStyle(
                            color: Colors.white,
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'JAN Code: ${scannerState.lastScannedCode}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                : (scannerState.isProcessingProduct)
                    ? _buildProcessingState(context, scannerState)
                : _buildIdleState(context),
          ),
          
          // スキャンボタン
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  if (scannerState.isScanning || scannerState.isProcessingProduct) {
                    scannerNotifier.stopScanning();
                    scannerNotifier.resetProcessingState();
                  } else {
                    // スキャン開始時にカメラを初期化
                    scannerNotifier.initializeCamera();
                    scannerNotifier.startScanning();
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: (scannerState.isScanning || scannerState.isProcessingProduct)
                      ? _textColor.withOpacity(0.1)
                      : _blockAccentColor,
                  foregroundColor: (scannerState.isScanning || scannerState.isProcessingProduct)
                      ? _textColor
                      : Colors.white,
                  elevation: (scannerState.isScanning || scannerState.isProcessingProduct) ? 0 : 2,
                  shadowColor: _blockAccentColor.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: (scannerState.isScanning || scannerState.isProcessingProduct)
                        ? BorderSide(color: _textColor.withOpacity(0.3), width: 1)
                        : BorderSide.none,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      (scannerState.isScanning || scannerState.isProcessingProduct)
                          ? Icons.stop_circle_outlined
                          : Icons.qr_code_scanner,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      (scannerState.isScanning || scannerState.isProcessingProduct)
                          ? 'スキャンを停止'
                          : 'スキャンを開始',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
    } catch (e) {
      // プロバイダーが初期化されていない場合のフォールバック
      return Scaffold(
        appBar: AppBar(
          title: const Text('バーコードスキャン'),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                size: 100,
                color: Colors.red,
              ),
              const SizedBox(height: 16),
              const Text(
                'スキャナーを初期化中です...',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  // プロバイダーを再初期化
                  ref.invalidate(scannerProvider);
                },
                child: const Text('再試行'),
              ),
            ],
          ),
        ),
      );
    }
  }
  
  Widget _buildIdleState(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface,
            Theme.of(context).colorScheme.surface.withOpacity(0.8),
          ],
        ),
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // メインアイコンコンテナ
              Container(
                width: 160,
                height: 160,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      Theme.of(context).colorScheme.primary.withOpacity(0.05),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(80),
                  boxShadow: [
                    BoxShadow(
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    // 背景の円
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(60),
                      ),
                    ),
                    // メインアイコン
                    Icon(
                      Icons.qr_code_scanner,
                      size: 60,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    // アニメーション用の波紋効果
                    Positioned(
                      child: Container(
                        width: 140,
                        height: 140,
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                            width: 2,
                          ),
                          borderRadius: BorderRadius.circular(70),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 40),
              
              // メインタイトル
              Text(
                'バーコードをスキャン',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 12),
              
              // サブタイトル
              Text(
                '商品を冷蔵庫に追加しましょう',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w400,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 48),
              
              // 機能説明カード
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.1),
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.auto_awesome,
                            size: 20,
                            color: Theme.of(context).colorScheme.primary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'AIが自動でカテゴリと賞味期限を予測',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.schedule,
                            size: 20,
                            color: Theme.of(context).colorScheme.secondary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            '期限切れの通知で食品ロスを防止',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _handleBarcodeDetection(BarcodeCapture capture, ScannerNotifier notifier) async {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        // バーコードスキャン処理を実行
        final result = await notifier.onBarcodeScanned(capture);
        
        if (result.isSuccess) {
          final product = result.data!;
          _showProductDialog(product);
        } else {
          _showErrorDialog(result.exception?.message ?? 'スキャンに失敗しました');
          // エラー時もクリアして再スキャンを可能にする
          notifier.clearLastScannedCode();
        }
        break; // 最初のバーコードのみ処理
      }
    }
  }
  
  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('エラー'),
        content: Text(message),
        actions: [
          AdaptiveButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              ref.read(scannerProvider.notifier).clearLastScannedCode();
            },
          ),
        ],
      ),
    );
  }
  
  void _showUnknownProductDialog(String janCode) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('商品が見つかりません'),
        content: Text('JANコード: $janCode\n\nこの商品はまだデータベースに登録されていません。'),
        actions: [
          AdaptiveButton(
            child: const Text('OK'),
            onPressed: () {
              Navigator.pop(context);
              ref.read(scannerProvider.notifier).clearLastScannedCode();
            },
          ),
        ],
      ),
    );
  }

  /// 情報セクションを作成する共通メソッド
  Widget _buildInfoSection({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Widget child,
    Color? backgroundColor,
    Color? iconColor,
    Color? textColor,
  }) {
    final bgColor = backgroundColor ?? Colors.grey[50]!;
    final icColor = iconColor ?? Theme.of(context).colorScheme.primary;
    final txtColor = textColor ?? Theme.of(context).colorScheme.primary;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: bgColor.withOpacity(0.3),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: bgColor.withOpacity(0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 20,
                color: icColor,
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                  color: txtColor,
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

  /// 商品情報処理中の状態を表示
  Widget _buildProcessingState(BuildContext context, ScannerState scannerState) {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Container(
          margin: const EdgeInsets.all(32),
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(
                strokeWidth: 3,
              ),
              const SizedBox(height: 24),
              const Text(
                '商品情報を検索中...',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'JAN Code: ${scannerState.lastScannedCode}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'しばらくお待ちください',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[500],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// 商品追加完了の通知を表示（SnackBarの代わりにダイアログを使用）
  void _showProductAddedSnackBar(BuildContext context, String productName) {
    // SnackBarの代わりに一時的なダイアログで通知
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
                color: _blockAccentColor,
                size: 48,
              ),
              const SizedBox(height: 16),
              Text(
                '$productName を追加しました',
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

  /// カスタム日付ピッカーを表示
  Future<DateTime?> _showCustomDatePicker({
    required BuildContext context,
    required DateTime initialDate,
    required DateTime firstDate,
    required DateTime lastDate,
    DateTime? aiPredictedDate,
  }) async {
    DateTime selectedDate = initialDate;
    int selectedYear = initialDate.year;
    int selectedMonth = initialDate.month;
    int selectedDayInt = initialDate.day;

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
                          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
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
                      calendarBuilders: CalendarBuilders(
                        markerBuilder: (context, day, events) {
                          if (aiPredictedDate != null && isSameDay(day, aiPredictedDate)) {
                            return Container(
                              margin: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: _aiPredictionColor.withOpacity(0.9),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: _aiPredictionDarkColor,
                                  width: 2.5,
                                ),
                              ),
                              child: const SizedBox.shrink(),
                            );
                          }
                          return null;
                        },
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
                      onHeaderTapped: (date) => _showMonthYearPicker(context, date, firstDate, lastDate, setState, (newDate) {
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
                        if (aiPredictedDate != null)
                          GestureDetector(
                            onTap: () {
                              // AI予測の日に移動
                              setState(() {
                                selectedDate = aiPredictedDate!;
                              });
                            },
                            child: Container(
                              margin: const EdgeInsets.only(right: 8),
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _aiPredictionColor.withOpacity(0.6),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: _aiPredictionDarkColor.withOpacity(0.8),
                                  width: 1.5,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.psychology,
                                    size: 12,
                                    color: _aiPredictionDarkColor,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    'AI予測',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: _aiPredictionDarkColor,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        // 今日ボタン
                        GestureDetector(
                          onTap: () {
                            // 今日の日付に移動
                            setState(() {
                              selectedDate = DateTime.now();
                            });
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
  void _showMonthYearPicker(BuildContext context, DateTime currentDate, DateTime firstDate, DateTime lastDate, StateSetter setState, Function(DateTime) onDateSelected) {
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
                      const Text('年', style: TextStyle(fontWeight: FontWeight.bold)),
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
                const SizedBox(width: 16),
                // 月選択
                Expanded(
                  child: Column(
                    children: [
                      const Text('月', style: TextStyle(fontWeight: FontWeight.bold)),
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
                              final month = index + 1;
                              return Center(
                                child: Text(
                                  '${month}月',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: selectedMonth == month
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: selectedMonth == month
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
                // 選択した日付が有効な範囲内かチェック
                if (newDate.isBefore(firstDate)) {
                  // 範囲外の場合は有効な範囲内の日付に調整
                  final adjustedDate = firstDate;
                  Navigator.of(context).pop(adjustedDate);
                } else if (newDate.isAfter(lastDate)) {
                  // 範囲外の場合は有効な範囲内の日付に調整
                  final adjustedDate = lastDate;
                  Navigator.of(context).pop(adjustedDate);
                } else {
                  Navigator.of(context).pop(newDate);
                }
              },
              child: const Text('選択'),
            ),
          ],
        ),
      ),
    ).then((result) {
      if (result != null && result is DateTime) {
        onDateSelected(result);
      }
    });
  }

  /// 賞味期限の表示テキストをフォーマット
  String _formatExpiryDate(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = expiry.difference(today).inDays;
    
    if (difference == 0) {
      return '今日';
    } else if (difference == 1) {
      return '明日';
    } else if (difference == 2) {
      return '明後日';
    } else if (difference > 0) {
      return '${difference}日後';
    } else {
      return '${-difference}日前';
    }
  }

  /// 賞味期限の表示色を取得
  Color _getExpiryDateColor(DateTime expiryDate) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final difference = expiry.difference(today).inDays;
    
    if (difference < 0) {
      // 過去の日付は赤字
      return Colors.red;
    } else if (difference <= 2) {
      // 今日・明日・明後日はオレンジ色
      return Colors.orange;
    } else {
      // それ以外は通常の色
      return _textColor.withOpacity(0.7);
    }
  }

  @override
  void dispose() {
    // Riverpodプロバイダーがカメラを管理するため、ここでは何もしない
    super.dispose();
  }
}