import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';

/// 引き出しの表示モード
enum DrawerViewMode {
  /// 正面ビュー（通常の冷蔵庫表示）
  frontView,
  /// 上から見たビュー（引き出しが開いた状態）
  topView,
  /// 引き出し内部の詳細ビュー（商品一覧）
  innerView,
}

/// 開いている引き出しの情報
class OpenDrawerInfo {
  final FridgeCompartment compartment;
  final int level;

  const OpenDrawerInfo({
    required this.compartment,
    required this.level,
  });

  @override
  bool operator ==(Object other) {
    return other is OpenDrawerInfo &&
        other.compartment == compartment &&
        other.level == level;
  }

  @override
  int get hashCode => Object.hash(compartment, level);
}

/// 引き出しの状態
@immutable
class DrawerState {
  final DrawerViewMode viewMode;
  final OpenDrawerInfo? openDrawer;
  final bool isAnimating;

  const DrawerState({
    this.viewMode = DrawerViewMode.frontView,
    this.openDrawer,
    this.isAnimating = false,
  });

  DrawerState copyWith({
    DrawerViewMode? viewMode,
    OpenDrawerInfo? openDrawer,
    bool? isAnimating,
  }) {
    return DrawerState(
      viewMode: viewMode ?? this.viewMode,
      openDrawer: openDrawer ?? this.openDrawer,
      isAnimating: isAnimating ?? this.isAnimating,
    );
  }
}

/// 引き出し状態の管理
class DrawerStateNotifier extends StateNotifier<DrawerState> {
  DrawerStateNotifier() : super(const DrawerState());

  /// 引き出しを開く（アニメーション付き）
  Future<void> openDrawer(FridgeCompartment compartment, int level) async {
    final drawerInfo = OpenDrawerInfo(compartment: compartment, level: level);

    // アニメーション開始
    state = state.copyWith(isAnimating: true);

    // 短い遅延でトップビューに遷移
    await Future.delayed(const Duration(milliseconds: 100));
    state = state.copyWith(
      viewMode: DrawerViewMode.topView,
      openDrawer: drawerInfo,
    );

    // アニメーション終了
    await Future.delayed(const Duration(milliseconds: 500));
    state = state.copyWith(isAnimating: false);
  }

  /// 引き出し内部をタップ（詳細ビューに遷移）
  void tapDrawerInner() {
    if (state.openDrawer != null) {
      state = state.copyWith(viewMode: DrawerViewMode.innerView);
    }
  }

  /// 正面ビューに戻る
  void backToFrontView() {
    state = state.copyWith(
      viewMode: DrawerViewMode.frontView,
      openDrawer: null,
      isAnimating: false,
    );
  }

  /// トップビューに戻る（詳細ビューから）
  void backToTopView() {
    if (state.openDrawer != null) {
      state = state.copyWith(viewMode: DrawerViewMode.topView);
    }
  }
}

/// 引き出し状態プロバイダー
final drawerStateProvider = StateNotifierProvider<DrawerStateNotifier, DrawerState>((ref) {
  return DrawerStateNotifier();
});