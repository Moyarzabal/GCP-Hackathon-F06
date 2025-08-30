import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'バーコードスキャナー MVP',
      theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
      ),
      home: ScannerScreen(),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
  final products = {
    '4901777018888': 'コカ・コーラ 500ml',
    '4902220770199': 'ポカリスエット 500ml',
    '4901005202078': 'カップヌードル',
    '4901301231123': 'ヤクルト',
    '4902102072670': '午後の紅茶',
    '4901005200074': 'どん兵衛',
    '4901551354313': 'カルピスウォーター',
    '4901777018871': 'ファンタオレンジ',
  };

  String? lastScanned;
  bool isScanning = false;
  MobileScannerController controller = MobileScannerController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('バーコードスキャナー'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Column(
        children: [
          Expanded(
            child: isScanning
                ? MobileScanner(
                    controller: controller,
                    onDetect: (capture) {
                      final List<Barcode> barcodes = capture.barcodes;
                      for (final barcode in barcodes) {
                        if (barcode.rawValue != null &&
                            barcode.rawValue != lastScanned) {
                          lastScanned = barcode.rawValue;
                          final productName =
                              products[barcode.rawValue] ?? '不明な商品';

                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('スキャン結果'),
                              content: Column(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '商品名:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    productName,
                                    style: TextStyle(fontSize: 18),
                                  ),
                                  SizedBox(height: 16),
                                  Text(
                                    'JANコード:',
                                    style:
                                        TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  Text(
                                    barcode.rawValue!,
                                    style: TextStyle(fontSize: 14),
                                  ),
                                ],
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      lastScanned = null;
                                    });
                                  },
                                  child: Text('もう一度スキャン'),
                                ),
                                TextButton(
                                  onPressed: () {
                                    Navigator.pop(context);
                                    setState(() {
                                      isScanning = false;
                                      lastScanned = null;
                                    });
                                  },
                                  child: Text('終了'),
                                ),
                              ],
                            ),
                          );
                        }
                      }
                    },
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: Colors.blue,
                        ),
                        SizedBox(height: 32),
                        Text(
                          'バーコードをスキャンして\n商品情報を確認しましょう',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                  ),
          ),
          Container(
            padding: EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () {
                  setState(() {
                    isScanning = !isScanning;
                  });
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      isScanning ? Colors.red : Theme.of(context).primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isScanning ? Icons.stop : Icons.camera_alt,
                      color: Colors.white,
                    ),
                    SizedBox(width: 8),
                    Text(
                      isScanning ? 'スキャンを停止' : 'スキャンを開始',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
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
  }

  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }
}