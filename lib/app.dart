import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/constants/app_colors.dart';
import 'core/platform/platform_info.dart';
import 'features/home/presentation/pages/home_screen.dart';
import 'features/scanner/presentation/pages/scanner_screen.dart';
import 'features/history/presentation/pages/history_screen.dart';
import 'features/settings/presentation/pages/settings_screen.dart';
import 'features/meal_planning/presentation/pages/meal_plan_screen.dart';
import 'shared/providers/app_state_provider.dart';
import 'shared/widgets/adaptive/adaptive_navigation.dart';
import 'shared/widgets/adaptive/adaptive_scaffold.dart';

class MyApp extends ConsumerWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // すべてのプラットフォームでMaterialAppを使用（NavigationDestinationのため）
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
        fontFamily: PlatformInfo.isIOS ? 'SF Pro Display' : null,
      ),
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
      const MealPlanScreen(),
      const ScannerScreen(),
      const HistoryScreen(),
      const SettingsScreen(),
    ];

    const destinations = [
      NavigationDestination(
        icon: Icon(Icons.home_outlined),
        selectedIcon: Icon(Icons.home),
        label: 'ホーム',
      ),
      NavigationDestination(
        icon: Icon(Icons.restaurant_menu_outlined),
        selectedIcon: Icon(Icons.restaurant_menu),
        label: '献立',
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
    ];

    return AdaptiveScaffold(
      body: IndexedStack(
        index: appState.selectedBottomNavIndex,
        children: pages,
      ),
      bottomNavigationBar: AdaptiveNavigation(
        selectedIndex: appState.selectedBottomNavIndex,
        onDestinationSelected: (index) {
          appNotifier.setBottomNavIndex(index);
        },
        destinations: destinations,
      ),
    );
  }
}