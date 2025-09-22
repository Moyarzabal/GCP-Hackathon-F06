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

    // レイヤー付き冷蔵庫ウィジェット側のアニメーション時間と同期
    const drawerAnimationDuration = Duration(milliseconds: 600);
    const additionalBuffer = Duration(milliseconds: 80);

    // アニメーション開始時点で対象の引き出し情報を保持
    state = state.copyWith(
      isAnimating: true,
      openDrawer: drawerInfo,
    );

    // 引き出しが完全に開くまで待機してから画面遷移
    await Future.delayed(drawerAnimationDuration + additionalBuffer);

    // 途中で閉じられている場合は遷移を行わない
    if (state.openDrawer != drawerInfo) {
      return;
    }

    state = state.copyWith(
      viewMode: DrawerViewMode.topView,
      isAnimating: false,
    );
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
