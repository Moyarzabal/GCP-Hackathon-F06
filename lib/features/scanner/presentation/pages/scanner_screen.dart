import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
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
    DateTime? selectedDate;
    String selectedCategory = _defaultCategories.contains(product.category) ? product.category : _defaultCategories.first;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Consumer(
        builder: (context, ref, child) {
          // 共通のカテゴリリストを使用
          final categoryOptions = _defaultCategories;
          
          // デバッグ情報を追加
          print('Category options: $categoryOptions');
          print('Selected category: $selectedCategory');
          
          return StatefulBuilder(
            builder: (context, setState) {
              return AlertDialog(
            title: const Text('商品情報'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.shopping_bag, size: 20),
                            SizedBox(width: 8),
                            Text(
                              '商品名',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          product.name,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // メーカー情報
                  if (product.manufacturer != null && product.manufacturer!.isNotEmpty) ...[
                    const Row(
                      children: [
                        Icon(Icons.business, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'メーカー',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.manufacturer!,
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 16),
                  ],
                  const Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '賞味期限',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  // 現在の賞味期限表示
                  if (product.expiryDate != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: product.statusColor.withOpacity(0.1),
                        border: Border.all(color: product.statusColor),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Text(
                            product.emotionState,
                            style: const TextStyle(fontSize: 24),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'AI予測賞味期限',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                                Text(
                                  '${product.expiryDate!.year}/${product.expiryDate!.month}/${product.expiryDate!.day}',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: product.statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                  // カテゴリ選択
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'カテゴリ',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        DropdownButtonFormField<String>(
                          value: categoryOptions.contains(selectedCategory) ? selectedCategory : categoryOptions.first,
                          decoration: const InputDecoration(
                            border: OutlineInputBorder(),
                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: categoryOptions.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // 賞味期限編集
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? product.expiryDate ?? DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        border: Border.all(color: Colors.grey[300]!),
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
                              color: selectedDate != null ? null : Colors.grey,
                                  fontSize: 16,
                                ),
                              ),
                              if (selectedDate != null)
                                Text(
                                  '${selectedDate!.difference(DateTime.now()).inDays}日後',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey[600],
                                  ),
                                ),
                            ],
                          ),
                          const Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
                        ],
                      ),
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
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      key: ValueKey('product_added_${product.id}'),
                      content: Text('${product.name} を追加しました'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 3),
                    ),
                  );
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
            title: const Text('手動で商品を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: '商品名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: const InputDecoration(
                      labelText: 'カテゴリ',
                      border: OutlineInputBorder(),
                    ),
                    items: _defaultCategories
                        .map((cat) => DropdownMenuItem(
                              value: cat,
                              child: Text(cat),
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
                  const SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
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
                        border: Border.all(color: Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate != null
                                ? '賞味期限: ${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'
                                : '賞味期限を選択',
                            style: TextStyle(
                              color: selectedDate != null ? null : Colors.grey,
                            ),
                          ),
                          const Icon(Icons.calendar_today, size: 20),
                        ],
                      ),
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
                  // 手動登録キャンセル時はスキャンを再開
                  ref.read(scannerProvider.notifier).startScanning();
                },
                child: const Text('キャンセル'),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        key: ValueKey('manual_product_added_${DateTime.now().millisecondsSinceEpoch}'),
                        content: Text('${nameController.text} を追加しました'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                        behavior: SnackBarBehavior.floating,
                        duration: const Duration(seconds: 3),
                      ),
                    );
                  }
                },
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
                          width: 250,
                          height: 150,
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
                      if (scannerState.isScanning)
                        const Center(
                          child: AdaptiveLoading(
                            color: Colors.white,
                            size: 32,
                          ),
                        ),
                    ],
                  )
                : _buildIdleState(context),
          ),
          
          // スキャンボタン
          Container(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: AdaptiveButton(
                child: Text(
                  scannerState.isScanning ? 'スキャンを停止' : 'スキャンを開始',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  if (scannerState.isScanning) {
                    scannerNotifier.stopScanning();
                  } else {
                    // スキャン開始時にカメラを初期化
                    scannerNotifier.initializeCamera();
                    scannerNotifier.startScanning();
                  }
                },
                style: scannerState.isScanning 
                    ? AdaptiveButtonStyle.secondary 
                    : AdaptiveButtonStyle.primary,
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
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // アイコンコンテナ
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.qr_code_scanner,
                size: 60,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'バーコードをスキャンして\n商品を冷蔵庫に追加',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w500,
                color: Colors.grey[700],
                height: 1.4,
              ),
            ),
            const SizedBox(height: 48),
            // スキャン開始ボタン
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AdaptiveButton(
                child: const Text(
                  'スキャン開始',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: () {
                  // スキャン開始時にカメラを初期化
                  ref.read(scannerProvider.notifier).initializeCamera();
                  ref.read(scannerProvider.notifier).startScanning();
                },
                style: AdaptiveButtonStyle.primary,
              ),
            ),
            const SizedBox(height: 12),
            // 手動追加ボタン
            SizedBox(
              width: double.infinity,
              height: 56,
              child: AdaptiveButton(
                child: const Text(
                  '手動で追加',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                onPressed: _showManualInput,
                style: AdaptiveButtonStyle.outlined,
              ),
            ),
          ],
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

  @override
  void dispose() {
    // Riverpodプロバイダーがカメラを管理するため、ここでは何もしない
    super.dispose();
  }
}