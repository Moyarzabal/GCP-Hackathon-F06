import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../providers/scanner_provider.dart';
import '../../../../shared/widgets/adaptive/adaptive_button.dart';
import '../../../../shared/widgets/adaptive/adaptive_loading.dart';
import '../../../../shared/widgets/common/error_widget.dart';

class ScannerScreen extends ConsumerStatefulWidget {
  const ScannerScreen({Key? key}) : super(key: key);
  
  @override
  ConsumerState<ScannerScreen> createState() => _ScannerScreenState();
}

class _ScannerScreenState extends ConsumerState<ScannerScreen> {
  final products = {
    '4901777018888': {'name': 'コカ・コーラ 500ml', 'category': '飲料'},
    '4902220770199': {'name': 'ポカリスエット 500ml', 'category': '飲料'},
    '4901005202078': {'name': 'カップヌードル', 'category': '食品'},
    '4901301231123': {'name': 'ヤクルト', 'category': '飲料'},
    '4902102072670': {'name': '午後の紅茶', 'category': '飲料'},
    '4901005200074': {'name': 'どん兵衛', 'category': '食品'},
    '4901551354313': {'name': 'カルピスウォーター', 'category': '飲料'},
    '4901777018871': {'name': 'ファンタオレンジ', 'category': '飲料'},
  };

  @override
  void initState() {
    super.initState();
    // カメラ初期化を次のフレームで実行
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(scannerProvider.notifier).initializeCamera();
    });
  }

  void _showProductDialog(String janCode, Map<String, String> productInfo) {
    DateTime? selectedDate;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
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
                          productInfo['name']!,
                          style: const TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
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
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(const Duration(days: 7)),
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
                                ? '${selectedDate!.year}/${selectedDate!.month}/${selectedDate!.day}'
                                : '日付を選択',
                            style: TextStyle(
                              color: selectedDate != null ? null : Colors.grey,
                            ),
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
                  final product = Product(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    janCode: janCode,
                    name: productInfo['name']!,
                    category: productInfo['category']!,
                    scannedAt: DateTime.now(),
                    addedDate: DateTime.now(),
                    expiryDate: selectedDate,
                  );
                  
                  // アプリ状態に商品を追加
                  ref.read(appStateProvider.notifier).addProduct(product);
                  
                  Navigator.pop(context);
                  ref.read(scannerProvider.notifier).clearLastScannedCode();
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${productInfo['name']} を追加しました'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
                child: const Text('保存'),
              ),
            ],
          );
        },
      ),
    );
  }
  
  void _showManualInput() {
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
                    items: ['飲料', '食品', '調味料', '冷凍食品', 'その他']
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
                onPressed: () => Navigator.pop(context),
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
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} を追加しました'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
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
            child: scannerState.isCameraActive
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: scannerNotifier.controller,
                        onDetect: (capture) {
                          _handleBarcodeDetection(capture, scannerNotifier);
                        },
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          color: Colors.black54,
                          child: const Text(
                            'バーコードを枠内に合わせてください',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
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
                child: Text(scannerState.isCameraActive ? 'スキャンを停止' : 'スキャンを開始'),
                onPressed: () {
                  if (scannerState.isCameraActive) {
                    scannerNotifier.stopCamera();
                  } else {
                    scannerNotifier.initializeCamera();
                  }
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildIdleState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.qr_code_scanner,
            size: 100,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(height: 32),
          Text(
            'バーコードをスキャンして\n商品を冷蔵庫に追加',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 18,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 48),
          AdaptiveButton(
            child: const Text('手動で追加'),
            onPressed: _showManualInput,
            style: AdaptiveButtonStyle.outlined,
          ),
        ],
      ),
    );
  }
  
  void _handleBarcodeDetection(BarcodeCapture capture, ScannerNotifier notifier) {
    final barcodes = capture.barcodes;
    for (final barcode in barcodes) {
      if (barcode.rawValue != null) {
        final productInfo = products[barcode.rawValue!];
        
        if (productInfo != null) {
          _showProductDialog(barcode.rawValue!, productInfo);
        } else {
          _showUnknownProductDialog(barcode.rawValue!);
        }
        break; // 最初のバーコードのみ処理
      }
    }
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