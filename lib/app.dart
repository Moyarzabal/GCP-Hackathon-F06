import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/scanner/presentation/pages/scanner_screen.dart';
import 'features/history/presentation/pages/history_screen.dart';
import 'features/settings/presentation/pages/settings_screen.dart';
import 'shared/providers/app_state_provider.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
      // 認証をバイパスして直接メイン機能にアクセス
      home: const MainScreen(),
    );
  }
}

class MainScreen extends ConsumerWidget {
  const MainScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appState = ref.watch(appStateProvider);
    final appNotifier = ref.watch(appStateProvider.notifier);
    
    final pages = [
      const HomeScreen(),
      const ScannerScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: appState.selectedBottomNavIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: appState.selectedBottomNavIndex,
        onDestinationSelected: (index) {
          appNotifier.setBottomNavIndex(index);
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