import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/scanner/presentation/pages/scanner_screen.dart';
import 'features/history/presentation/pages/history_screen.dart';
import 'features/settings/presentation/pages/settings_screen.dart';
import 'features/products/presentation/pages/product_detail_screen.dart';
import 'features/auth/presentation/pages/login_screen.dart';
import 'features/household/presentation/pages/household_screen.dart';
import 'shared/models/product.dart';
import 'shared/providers/auth_provider.dart';
import 'shared/providers/household_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authStateProvider);
    
    return MaterialApp(
      title: '冷蔵庫管理AI',
      theme: ThemeData(
        primaryColor: AppColors.primary,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.accent,
          primary: AppColors.accent,
          secondary: AppColors.secondary,
          error: AppColors.error,
        ),
        useMaterial3: true,
        fontFamily: 'SF Pro Display',
      ),
      home: authState.when(
        data: (user) {
          if (user == null) {
            return const LoginScreen();
          }
          return const AuthenticatedWrapper();
        },
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (error, stack) => Scaffold(
          body: Center(child: Text('Error: $error')),
        ),
      ),
    );
  }
}

class AuthenticatedWrapper extends ConsumerWidget {
  const AuthenticatedWrapper({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final householdAsync = ref.watch(userHouseholdProvider);
    
    return householdAsync.when(
      data: (household) {
        if (household == null || !household.exists) {
          return const HouseholdScreen();
        }
        return const MainScreen();
      },
      loading: () => const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (error, stack) => Scaffold(
        body: Center(child: Text('Error: $error')),
      ),
    );
  }
}

class MainScreen extends ConsumerStatefulWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  ConsumerState<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends ConsumerState<MainScreen> {
  int _selectedIndex = 0;
  final List<Product> _scannedProducts = [];
  
  late final List<Widget> _pages;
  
  @override
  void initState() {
    super.initState();
    _pages = [
      HomeScreen(products: _scannedProducts, onProductTap: _showProductDetail),
      ScannerScreen(onProductScanned: _addProduct),
      HistoryScreen(products: _scannedProducts),
      const SettingsScreen(),
    ];
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
        destinations: const [
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