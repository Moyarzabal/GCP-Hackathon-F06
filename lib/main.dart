import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '冷蔵庫管理AI',
      theme: ThemeData(
        primaryColor: Color(0xFF0f172a),
        colorScheme: ColorScheme.fromSeed(
          seedColor: Color(0xFF3b82f6),
          primary: Color(0xFF3b82f6),
          secondary: Color(0xFF10b981),
          error: Color(0xFFef4444),
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: MainScreen(),
    );
  }
}

class MainScreen extends StatefulWidget {
  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  final List<Product> _scannedProducts = [];
  
  final List<Widget> _pages = [];
  
  @override
  void initState() {
    super.initState();
    _pages.addAll([
      HomeScreen(products: _scannedProducts, onProductTap: _showProductDetail),
      ScannerScreen(onProductScanned: _addProduct),
      HistoryScreen(products: _scannedProducts),
      SettingsScreen(),
    ]);
  }
  
  void _addProduct(Product product) {
    setState(() {
      _scannedProducts.insert(0, product);
    });
  }
  
  void _showProductDetail(Product product) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ProductDetailScreen(product: product),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'ホーム',
          ),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner_outlined),
            selectedIcon: Icon(Icons.qr_code_scanner),
            label: 'スキャン',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: '履歴',
          ),
          NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: '設定',
          ),
        ],
      ),
    );
  }
}

class Product {
  final String janCode;
  final String name;
  final DateTime scannedAt;
  final DateTime? expiryDate;
  final String category;
  final String? imageUrl;
  
  Product({
    required this.janCode,
    required this.name,
    required this.scannedAt,
    this.expiryDate,
    required this.category,
    this.imageUrl,
  });
  
  int get daysUntilExpiry {
    if (expiryDate == null) return 999;
    return expiryDate!.difference(DateTime.now()).inDays;
  }
  
  String get emotionState {
    final days = daysUntilExpiry;
    if (days > 7) return '😊';
    if (days > 3) return '😐';
    if (days > 1) return '😟';
    if (days > 0) return '😰';
    return '💀';
  }
  
  Color get statusColor {
    final days = daysUntilExpiry;
    if (days > 7) return Color(0xFF10b981);
    if (days > 3) return Color(0xFFf59e0b);
    return Color(0xFFef4444);
  }
}

class HomeScreen extends StatefulWidget {
  final List<Product> products;
  final Function(Product) onProductTap;
  
  HomeScreen({required this.products, required this.onProductTap});
  
  @override
  _HomeScreenState createState() => _HomeScreenState();
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
      filtered.sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    }
    
    return filtered;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          '冷蔵庫の中身',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.surface,
        actions: [
          IconButton(
            icon: Icon(Icons.search),
            onPressed: () {
              showSearch(
                context: context,
                delegate: ProductSearchDelegate(widget.products),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: Icon(Icons.sort),
            onSelected: (value) {
              setState(() {
                _sortBy = value;
              });
            },
            itemBuilder: (context) => [
              PopupMenuItem(value: 'expiry', child: Text('賞味期限順')),
              PopupMenuItem(value: 'name', child: Text('名前順')),
              PopupMenuItem(value: 'date', child: Text('登録日順')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: 50,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: categories.length,
              itemBuilder: (context, index) {
                final category = categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: EdgeInsets.only(right: 8),
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
                        SizedBox(height: 16),
                        Text(
                          '冷蔵庫は空です',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(height: 8),
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
                    padding: EdgeInsets.all(16),
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

class ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onTap;
  
  ProductCard({required this.product, required this.onTap});
  
  @override
  Widget build(BuildContext context) {
    return Card(
      margin: EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: product.statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    product.emotionState,
                    style: TextStyle(fontSize: 32),
                  ),
                ),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.category, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          product.category,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        SizedBox(width: 12),
                        Icon(Icons.access_time, size: 14, color: Colors.grey),
                        SizedBox(width: 4),
                        Text(
                          product.expiryDate != null
                              ? '${product.daysUntilExpiry}日後'
                              : '期限なし',
                          style: TextStyle(
                            fontSize: 12,
                            color: product.statusColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: Colors.grey[400],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ScannerScreen extends StatefulWidget {
  final Function(Product) onProductScanned;
  
  ScannerScreen({required this.onProductScanned});
  
  @override
  _ScannerScreenState createState() => _ScannerScreenState();
}

class _ScannerScreenState extends State<ScannerScreen> {
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

  String? lastScanned;
  bool isScanning = false;
  MobileScannerController controller = MobileScannerController();

  void _showProductDialog(String janCode, Map<String, String> productInfo) {
    DateTime? selectedDate;
    
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: Text('商品情報'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
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
                        SizedBox(height: 4),
                        Text(
                          productInfo['name']!,
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 16),
                  Row(
                    children: [
                      Icon(Icons.calendar_today, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '賞味期限',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                  SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: selectedDate ?? DateTime.now().add(Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
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
                          Icon(Icons.edit_calendar, size: 20, color: Colors.grey),
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
                  setState(() {
                    lastScanned = null;
                  });
                },
                child: Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  final product = Product(
                    janCode: janCode,
                    name: productInfo['name']!,
                    category: productInfo['category']!,
                    scannedAt: DateTime.now(),
                    expiryDate: selectedDate,
                  );
                  widget.onProductScanned(product);
                  Navigator.pop(context);
                  setState(() {
                    isScanning = false;
                    lastScanned = null;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${productInfo['name']} を追加しました'),
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                    ),
                  );
                },
                child: Text('保存'),
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
            title: Text('手動で商品を追加'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextField(
                    controller: nameController,
                    decoration: InputDecoration(
                      labelText: '商品名',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedCategory,
                    decoration: InputDecoration(
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
                  SizedBox(height: 16),
                  InkWell(
                    onTap: () async {
                      final date = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(Duration(days: 7)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(Duration(days: 365)),
                      );
                      if (date != null) {
                        setState(() {
                          selectedDate = date;
                        });
                      }
                    },
                    child: Container(
                      padding: EdgeInsets.all(12),
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
                          Icon(Icons.calendar_today, size: 20),
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
                child: Text('キャンセル'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (nameController.text.isNotEmpty) {
                    final product = Product(
                      janCode: 'MANUAL_${DateTime.now().millisecondsSinceEpoch}',
                      name: nameController.text,
                      category: selectedCategory,
                      scannedAt: DateTime.now(),
                      expiryDate: selectedDate,
                    );
                    widget.onProductScanned(product);
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${nameController.text} を追加しました'),
                        backgroundColor: Theme.of(context).colorScheme.secondary,
                      ),
                    );
                  }
                },
                child: Text('追加'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('バーコードスキャン'),
        actions: [
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: _showManualInput,
            tooltip: '手動入力',
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: isScanning
                ? Stack(
                    children: [
                      MobileScanner(
                        controller: controller,
                        onDetect: (capture) {
                          final List<Barcode> barcodes = capture.barcodes;
                          for (final barcode in barcodes) {
                            if (barcode.rawValue != null &&
                                barcode.rawValue != lastScanned) {
                              lastScanned = barcode.rawValue;
                              final productInfo = products[barcode.rawValue];
                              
                              if (productInfo != null) {
                                _showProductDialog(barcode.rawValue!, productInfo);
                              } else {
                                showDialog(
                                  context: context,
                                  builder: (context) => AlertDialog(
                                    title: Text('商品が見つかりません'),
                                    content: Text('JANコード: ${barcode.rawValue}\n\nこの商品はまだデータベースに登録されていません。'),
                                    actions: [
                                      TextButton(
                                        onPressed: () {
                                          Navigator.pop(context);
                                          setState(() {
                                            lastScanned = null;
                                          });
                                        },
                                        child: Text('OK'),
                                      ),
                                    ],
                                  ),
                                );
                              }
                            }
                          }
                        },
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Container(
                          padding: EdgeInsets.all(16),
                          color: Colors.black54,
                          child: Text(
                            'バーコードを枠内に合わせてください',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.qr_code_scanner,
                          size: 100,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                        SizedBox(height: 32),
                        Text(
                          'バーコードをスキャンして\n商品を冷蔵庫に追加',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[700],
                          ),
                        ),
                        SizedBox(height: 48),
                        OutlinedButton.icon(
                          onPressed: _showManualInput,
                          icon: Icon(Icons.edit),
                          label: Text('手動で追加'),
                          style: OutlinedButton.styleFrom(
                            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
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
                  backgroundColor: isScanning 
                    ? Theme.of(context).colorScheme.error 
                    : Theme.of(context).colorScheme.primary,
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

class HistoryScreen extends StatelessWidget {
  final List<Product> products;
  
  HistoryScreen({required this.products});
  
  @override
  Widget build(BuildContext context) {
    final sortedProducts = List<Product>.from(products)
      ..sort((a, b) => b.scannedAt.compareTo(a.scannedAt));
    
    return Scaffold(
      appBar: AppBar(
        title: Text('スキャン履歴'),
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
                  SizedBox(height: 16),
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
              padding: EdgeInsets.all(16),
              itemCount: sortedProducts.length,
              itemBuilder: (context, index) {
                final product = sortedProducts[index];
                return Card(
                  margin: EdgeInsets.only(bottom: 8),
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
                          style: TextStyle(fontSize: 24),
                        ),
                      ),
                    ),
                    title: Text(product.name),
                    subtitle: Text(
                      '${product.scannedAt.year}/${product.scannedAt.month}/${product.scannedAt.day} ${product.scannedAt.hour}:${product.scannedAt.minute.toString().padLeft(2, '0')}',
                    ),
                    trailing: Chip(
                      label: Text(
                        product.category,
                        style: TextStyle(fontSize: 12),
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

class SettingsScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('設定'),
      ),
      body: ListView(
        children: [
          ListTile(
            leading: Icon(Icons.notifications),
            title: Text('通知設定'),
            subtitle: Text('賞味期限の通知を管理'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.family_restroom),
            title: Text('家族共有'),
            subtitle: Text('家族メンバーを管理'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          ListTile(
            leading: Icon(Icons.category),
            title: Text('カテゴリ管理'),
            subtitle: Text('商品カテゴリをカスタマイズ'),
            trailing: Icon(Icons.chevron_right),
            onTap: () {},
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.info),
            title: Text('アプリについて'),
            subtitle: Text('バージョン 1.0.0'),
            onTap: () {},
          ),
        ],
      ),
    );
  }
}

class ProductDetailScreen extends StatelessWidget {
  final Product product;
  
  ProductDetailScreen({required this.product});
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('商品詳細'),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
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
                    style: TextStyle(fontSize: 64),
                  ),
                ),
              ),
            ),
            SizedBox(height: 24),
            Text(
              product.name,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 24),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    _DetailRow(
                      icon: Icons.category,
                      label: 'カテゴリ',
                      value: product.category,
                    ),
                    Divider(),
                    _DetailRow(
                      icon: Icons.qr_code,
                      label: 'JANコード',
                      value: product.janCode,
                    ),
                    Divider(),
                    _DetailRow(
                      icon: Icons.calendar_today,
                      label: '賞味期限',
                      value: product.expiryDate != null
                          ? '${product.expiryDate!.year}/${product.expiryDate!.month}/${product.expiryDate!.day}'
                          : '未設定',
                      valueColor: product.statusColor,
                    ),
                    Divider(),
                    _DetailRow(
                      icon: Icons.access_time,
                      label: '残り日数',
                      value: product.expiryDate != null
                          ? '${product.daysUntilExpiry}日'
                          : '—',
                      valueColor: product.statusColor,
                    ),
                    Divider(),
                    _DetailRow(
                      icon: Icons.add_circle,
                      label: '登録日',
                      value: '${product.scannedAt.year}/${product.scannedAt.month}/${product.scannedAt.day}',
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
  
  _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 14,
            ),
          ),
          Spacer(),
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

class ProductSearchDelegate extends SearchDelegate<Product?> {
  final List<Product> products;
  
  ProductSearchDelegate(this.products);
  
  @override
  List<Widget> buildActions(BuildContext context) {
    return [
      IconButton(
        icon: Icon(Icons.clear),
        onPressed: () {
          query = '';
        },
      ),
    ];
  }
  
  @override
  Widget buildLeading(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back),
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
          leading: Text(product.emotionState, style: TextStyle(fontSize: 24)),
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
          leading: Text(product.emotionState, style: TextStyle(fontSize: 24)),
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