import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;
import '../providers/fridge_view_provider.dart';
import 'futuristic_3d_painter.dart';

/// 近未来的3D冷蔵庫ウィジェット（ホログラム風エフェクト、音響効果付き）
class Futuristic3DFridgeWidget extends ConsumerStatefulWidget {
  final void Function(FridgeCompartment compartment, int level) onSectionTap;

  const Futuristic3DFridgeWidget({super.key, required this.onSectionTap});

  @override
  ConsumerState<Futuristic3DFridgeWidget> createState() =>
      _Futuristic3DFridgeWidgetState();
}

class _Futuristic3DFridgeWidgetState
    extends ConsumerState<Futuristic3DFridgeWidget>
    with TickerProviderStateMixin {
  // アニメーションコントローラー
  late final AnimationController _leftDoorController;
  late final AnimationController _rightDoorController;
  late final AnimationController _vegDrawerController;
  late final AnimationController _freezerController;
  late final AnimationController _globalAnimController;
  late final AnimationController _particleController;

  // アニメーション値
  late final Animation<double> _leftDoorAngle;
  late final Animation<double> _rightDoorAngle;
  late final Animation<double> _vegDrawerOffset;
  late final Animation<double> _freezerOffset;
  late final Animation<double> _globalTime;

  // 状態管理
  bool _leftDoorOpen = false;
  bool _rightDoorOpen = false;
  bool _vegDrawerOpen = false;
  bool _freezerOpen = false;

  @override
  void initState() {
    super.initState();

    // コントローラー初期化
    _leftDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _rightDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _vegDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _freezerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _globalAnimController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
    _particleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    // アニメーション定義
    _leftDoorAngle = Tween<double>(
      begin: 0.0,
      end: 1.4, // 手前に開くように正の値に変更
    ).animate(CurvedAnimation(
      parent: _leftDoorController,
      curve: Curves.elasticOut,
    ));

    _rightDoorAngle = Tween<double>(
      begin: 0.0,
      end: -1.4, // 手前に開くように負の値に変更
    ).animate(CurvedAnimation(
      parent: _rightDoorController,
      curve: Curves.elasticOut,
    ));

    _vegDrawerOffset = Tween<double>(
      begin: 0.0,
      end: -80.0, // より大きなスライド距離
    ).animate(CurvedAnimation(
      parent: _vegDrawerController,
      curve: Curves.bounceOut,
    ));

    _freezerOffset = Tween<double>(
      begin: 0.0,
      end: -90.0,
    ).animate(CurvedAnimation(
      parent: _freezerController,
      curve: Curves.bounceOut,
    ));

    _globalTime = Tween<double>(
      begin: 0.0,
      end: 10.0,
    ).animate(_globalAnimController);
  }

  @override
  void dispose() {
    _leftDoorController.dispose();
    _rightDoorController.dispose();
    _vegDrawerController.dispose();
    _freezerController.dispose();
    _globalAnimController.dispose();
    _particleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(sectionCountsProvider);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: RepaintBoundary(
            child: Stack(
              children: [
                // メイン3D冷蔵庫
                AnimatedBuilder(
                  animation: Listenable.merge([
                    _leftDoorController,
                    _rightDoorController,
                    _vegDrawerController,
                    _freezerController,
                    _globalAnimController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: Futuristic3DFridgePainter(
                        colorScheme: Theme.of(context).colorScheme,
                        animationTime: _globalTime.value,
                        leftDoorAngle: _leftDoorAngle.value,
                        rightDoorAngle: _rightDoorAngle.value,
                        vegDrawerOffset: _vegDrawerOffset.value,
                        freezerOffset: _freezerOffset.value,
                      ),
                    );
                  },
                ),

                // インタラクション領域
                _buildInteractionZones(counts),

                // ホログラム風オーバーレイ
                _buildHologramOverlay(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionZones(Map<String, int> counts) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 左扉（サイズ拡大に合わせて調整）
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topLeft,
              widthFactor: 0.425,
              heightFactor: 0.5,
              onTap: () => _toggleLeftDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorLeft, 0),
              semanticsLabel: '左ドア',
              semanticsValue: _leftDoorOpen ? '開' : '閉',
              badge: _buildHologramBadge(counts, FridgeCompartment.doorLeft, 0),
            ),

            // 右扉（サイズ拡大に合わせて調整）
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topRight,
              widthFactor: 0.425,
              heightFactor: 0.5,
              onTap: () => _toggleRightDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorRight, 0),
              semanticsLabel: '右ドア',
              semanticsValue: _rightDoorOpen ? '開' : '閉',
              badge:
                  _buildHologramBadge(counts, FridgeCompartment.doorRight, 0),
            ),

            // 冷蔵室棚
            ...List.generate(3, (i) => _buildShelfZone(i, counts, constraints)),

            // 野菜室
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.bottomCenter,
              widthFactor: 0.75,
              heightFactor: 0.1,
              topOffset: 0.68,
              onTap: () => _toggleVegDrawer(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.vegetableDrawer, 0),
              semanticsLabel: '野菜室',
              semanticsValue: _vegDrawerOpen ? '開' : '閉',
              badge: _buildHologramBadge(
                  counts, FridgeCompartment.vegetableDrawer, 0),
            ),

            // 冷凍庫
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.bottomCenter,
              widthFactor: 0.75,
              heightFactor: 0.1,
              topOffset: 0.85,
              onTap: () => _toggleFreezer(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.freezer, 0),
              semanticsLabel: '冷凍庫',
              semanticsValue: _freezerOpen ? '開' : '閉',
              badge: _buildHologramBadge(counts, FridgeCompartment.freezer, 0),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTouchZone({
    required BoxConstraints constraints,
    required Alignment alignment,
    required double widthFactor,
    required double heightFactor,
    double topOffset = 0.0,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
    required String semanticsLabel,
    required String semanticsValue,
    Widget? badge,
  }) {
    final width = constraints.maxWidth * widthFactor;
    final height = constraints.maxHeight * heightFactor;
    final top = constraints.maxHeight * topOffset;

    Offset position;
    switch (alignment) {
      case Alignment.topLeft:
        position = Offset(0, top);
        break;
      case Alignment.topRight:
        position = Offset(constraints.maxWidth - width, top);
        break;
      case Alignment.bottomCenter:
        position = Offset((constraints.maxWidth - width) / 2, top);
        break;
      default:
        position = Offset.zero;
    }

    return Positioned(
      left: position.dx,
      top: position.dy,
      width: width,
      height: height,
      child: Semantics(
        label: semanticsLabel,
        value: semanticsValue,
        button: true,
        child: GestureDetector(
          onTap: onTap,
          onDoubleTap: onDoubleTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: badge ?? const SizedBox(),
          ),
        ),
      ),
    );
  }

  Widget _buildShelfZone(
      int level, Map<String, int> counts, BoxConstraints constraints) {
    final height = constraints.maxHeight;
    final top = height * (0.22 + level * 0.10);
    final shelfHeight = height * 0.08;

    return Positioned(
      left: constraints.maxWidth * 0.125,
      right: constraints.maxWidth * 0.125,
      top: top,
      height: shelfHeight,
      child: GestureDetector(
        onTap: () {
          _playFuturisticSound();
          widget.onSectionTap(FridgeCompartment.refrigerator, level);
        },
        child: Semantics(
          label: '冷蔵室 棚${level + 1}',
          button: true,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Stack(
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text(
                      '冷蔵室 棚${level + 1}',
                      style: TextStyle(
                        color: const Color(0xFF64FFDA),
                        fontSize: 12,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
                Positioned.fill(
                  child: _buildHologramBadge(
                    counts,
                    FridgeCompartment.refrigerator,
                    level,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHologramBadge(
      Map<String, int> counts, FridgeCompartment compartment, int level) {
    final key = '${compartment.name}:$level';
    final count = counts[key] ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topRight,
      child: AnimatedBuilder(
        animation: _particleController,
        builder: (context, _) {
          final glow =
              (math.sin(_particleController.value * 2 * math.pi) + 1) / 2;
          return Container(
            margin: const EdgeInsets.all(6),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFF00E5FF).withOpacity(0.8),
              borderRadius: BorderRadius.circular(999),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF00E5FF).withOpacity(0.6 * glow),
                  blurRadius: 8,
                  spreadRadius: 2,
                ),
              ],
              border: Border.all(
                color: const Color(0xFF64FFDA).withOpacity(0.8),
                width: 1,
              ),
            ),
            child: Text(
              '$count',
              style: TextStyle(
                color: Colors.white,
                fontSize: 11,
                fontWeight: FontWeight.bold,
                shadows: [
                  Shadow(
                    color: const Color(0xFF00E5FF),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHologramOverlay() {
    return AnimatedBuilder(
      animation: _globalAnimController,
      builder: (context, _) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: const Color(0xFF00E5FF).withOpacity(0.3),
              width: 1,
            ),
          ),
          child: Stack(
            children: [
              // スキャンライン
              _buildScanLine(),
              // コーナーアクセント
              _buildCornerAccents(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildScanLine() {
    return AnimatedBuilder(
      animation: _globalAnimController,
      builder: (context, _) {
        final progress = _globalTime.value % 3.0 / 3.0;
        return Positioned(
          left: 0,
          right: 0,
          top: MediaQuery.of(context).size.height * 0.7 * progress,
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.transparent,
                  const Color(0xFF18FFFF).withOpacity(0.8),
                  Colors.transparent,
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCornerAccents() {
    return Stack(
      children: [
        // 左上
        Positioned(
          left: 10,
          top: 10,
          child: _buildCornerAccent(),
        ),
        // 右上
        Positioned(
          right: 10,
          top: 10,
          child: Transform.rotate(
            angle: math.pi / 2,
            child: _buildCornerAccent(),
          ),
        ),
        // 左下
        Positioned(
          left: 10,
          bottom: 10,
          child: Transform.rotate(
            angle: -math.pi / 2,
            child: _buildCornerAccent(),
          ),
        ),
        // 右下
        Positioned(
          right: 10,
          bottom: 10,
          child: Transform.rotate(
            angle: math.pi,
            child: _buildCornerAccent(),
          ),
        ),
      ],
    );
  }

  Widget _buildCornerAccent() {
    return AnimatedBuilder(
      animation: _particleController,
      builder: (context, _) {
        final opacity =
            (math.sin(_particleController.value * 2 * math.pi) + 1) / 2;
        return Container(
          width: 20,
          height: 20,
          decoration: BoxDecoration(
            border: Border(
              left: BorderSide(
                color: const Color(0xFF64FFDA).withOpacity(0.6 + opacity * 0.4),
                width: 2,
              ),
              top: BorderSide(
                color: const Color(0xFF64FFDA).withOpacity(0.6 + opacity * 0.4),
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }

  // アニメーション制御メソッド
  void _toggleLeftDoor() {
    _playFuturisticSound();
    _triggerHapticFeedback();
    _leftDoorOpen = !_leftDoorOpen;
    if (_leftDoorOpen) {
      _leftDoorController.forward();
    } else {
      _leftDoorController.reverse();
    }
  }

  void _toggleRightDoor() {
    _playFuturisticSound();
    _triggerHapticFeedback();
    _rightDoorOpen = !_rightDoorOpen;
    if (_rightDoorOpen) {
      _rightDoorController.forward();
    } else {
      _rightDoorController.reverse();
    }
  }

  void _toggleVegDrawer() {
    _playFuturisticSound();
    _triggerHapticFeedback();
    _vegDrawerOpen = !_vegDrawerOpen;
    if (_vegDrawerOpen) {
      _vegDrawerController.forward();
    } else {
      _vegDrawerController.reverse();
    }
  }

  void _toggleFreezer() {
    _playFuturisticSound();
    _triggerHapticFeedback();
    _freezerOpen = !_freezerOpen;
    if (_freezerOpen) {
      _freezerController.forward();
    } else {
      _freezerController.reverse();
    }
  }

  void _playFuturisticSound() {
    // 近未来的な音響効果（プラットフォーム音を使用）
    HapticFeedback.lightImpact();
  }

  void _triggerHapticFeedback() {
    // より強い触覚フィードバック
    HapticFeedback.mediumImpact();
  }
}
