import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../providers/drawer_state_provider.dart';
import 'layered_3d_fridge_widget.dart';
import 'top_view_fridge_widget.dart';

class EnhancedFridgeWidget extends ConsumerWidget {
  final Function(FridgeCompartment compartment, int level) onSectionTap;

  const EnhancedFridgeWidget({
    Key? key,
    required this.onSectionTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final drawerState = ref.watch(drawerStateProvider);

    // 表示モードに応じてウィジェットを切り替え
    switch (drawerState.viewMode) {
      case DrawerViewMode.frontView:
        return Layered3DFridgeWidget(
          onSectionTap: onSectionTap,
        );
      case DrawerViewMode.topView:
        return TopViewFridgeWidget(
          onSectionTap: onSectionTap,
        );
      case DrawerViewMode.innerView:
        // 詳細ビューでは、セクションタップを呼んで元の画面遷移ロジックを使う
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (drawerState.openDrawer != null) {
            onSectionTap(drawerState.openDrawer!.compartment, drawerState.openDrawer!.level);
          }
        });
        return Container(); // 即座にリスト画面に遷移するので空コンテナ
    }
  }
}