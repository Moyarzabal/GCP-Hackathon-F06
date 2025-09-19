import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

/// プラットフォームに応じて適応するナビゲーションバー
class AdaptiveNavigation extends StatelessWidget {
  const AdaptiveNavigation({
    Key? key,
    required this.selectedIndex,
    required this.destinations,
    required this.onDestinationSelected,
  }) : super(key: key);

  final int selectedIndex;
  final List<NavigationDestination> destinations;
  final ValueChanged<int> onDestinationSelected;

  @override
  Widget build(BuildContext context) {
    // 空のdestinationsの場合は空のContainerを返す
    if (destinations.isEmpty) {
      return const SizedBox.shrink();
    }

    if (PlatformInfo.isIOS) {
      return _buildCupertinoTabBar(context);
    } else {
      return _buildMaterialNavigationBar(context);
    }
  }

  Widget _buildCupertinoTabBar(BuildContext context) {
    return CupertinoTabBar(
      currentIndex: selectedIndex,
      onTap: onDestinationSelected,
      items: destinations.map((destination) => BottomNavigationBarItem(
        icon: destination.icon,
        activeIcon: destination.selectedIcon ?? destination.icon,
        label: destination.label,
      )).toList(),
      backgroundColor: CupertinoColors.systemBackground.resolveFrom(context),
      activeColor: CupertinoColors.activeBlue.resolveFrom(context),
      inactiveColor: CupertinoColors.inactiveGray.resolveFrom(context),
    );
  }

  Widget _buildMaterialNavigationBar(BuildContext context) {
    // MaterialのNavigationBarは少なくとも2つのdestinationsが必要
    if (destinations.length < 2) {
      return Container(
        height: 80,
        color: Theme.of(context).colorScheme.surface,
        child: const Center(
          child: Text('ナビゲーション項目が不足しています'),
        ),
      );
    }

    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onDestinationSelected,
      destinations: destinations,
    );
  }
}