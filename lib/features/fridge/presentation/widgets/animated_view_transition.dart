import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../shared/models/product.dart';
import '../providers/drawer_state_provider.dart';
import 'layered_3d_fridge_widget.dart';
import 'top_view_fridge_widget.dart';

/// 正面ビューと上からの視点の間のアニメーション付きトランジション
class AnimatedViewTransition extends ConsumerStatefulWidget {
  final Function(FridgeCompartment compartment, int level) onSectionTap;

  const AnimatedViewTransition({
    Key? key,
    required this.onSectionTap,
  }) : super(key: key);

  @override
  ConsumerState<AnimatedViewTransition> createState() => _AnimatedViewTransitionState();
}

class _AnimatedViewTransitionState extends ConsumerState<AnimatedViewTransition>
    with TickerProviderStateMixin {

  late AnimationController _transitionController;
  late AnimationController _perspectiveController;
  late AnimationController _scaleController;

  late Animation<double> _transitionAnimation;
  late Animation<double> _perspectiveAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  @override
  void initState() {
    super.initState();

    // メインのトランジション制御
    _transitionController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );

    // パースペクティブ変化制御
    _perspectiveController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    // スケール変化制御
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );

    // トランジション進行（0.0 = 正面, 1.0 = 上視点）
    _transitionAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: Curves.easeInOutCubic,
    ));

    // パースペクティブ変化（カメラの角度変更）
    _perspectiveAnimation = Tween<double>(
      begin: 0.0,
      end: math.pi / 2, // 90度回転
    ).animate(CurvedAnimation(
      parent: _perspectiveController,
      curve: const Interval(0.2, 0.8, curve: Curves.easeInOutQuart),
    ));

    // スケール変化（ズーム効果）
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));

    // 回転アニメーション（3D効果）
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: -math.pi / 6, // -30度回転
    ).animate(CurvedAnimation(
      parent: _transitionController,
      curve: const Interval(0.3, 0.7, curve: Curves.easeInOut),
    ));
  }

  @override
  void dispose() {
    _transitionController.dispose();
    _perspectiveController.dispose();
    _scaleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final drawerState = ref.watch(drawerStateProvider);

    // ビューモードの変化を監視してアニメーションをトリガー
    ref.listen<DrawerState>(drawerStateProvider, (previous, current) {
      if (previous?.viewMode != current.viewMode) {
        _handleViewModeChange(current.viewMode);
      }
    });

    return AnimatedBuilder(
      animation: Listenable.merge([
        _transitionAnimation,
        _perspectiveAnimation,
        _scaleAnimation,
        _rotationAnimation,
      ]),
      builder: (context, child) {
        return _buildTransitionView(drawerState);
      },
    );
  }

  /// ビューモード変化のハンドリング
  void _handleViewModeChange(DrawerViewMode viewMode) {
    switch (viewMode) {
      case DrawerViewMode.frontView:
        _animateToFrontView();
        break;
      case DrawerViewMode.topView:
        _animateToTopView();
        break;
      case DrawerViewMode.innerView:
        // 内部ビューは別の画面に遷移するためアニメーション不要
        break;
    }
  }

  /// 正面ビューへのアニメーション
  void _animateToFrontView() async {
    // パラレルでアニメーション実行
    await Future.wait([
      _transitionController.reverse(),
      _perspectiveController.reverse(),
      _scaleController.reverse(),
    ]);
  }

  /// 上視点ビューへのアニメーション
  void _animateToTopView() async {
    // 段階的なアニメーション
    // 1. スケールダウン開始
    _scaleController.forward();

    // 2. わずかな遅延後にパースペクティブ変化開始
    await Future.delayed(const Duration(milliseconds: 200));
    _perspectiveController.forward();

    // 3. メイントランジション開始
    await Future.delayed(const Duration(milliseconds: 100));
    _transitionController.forward();
  }

  /// トランジションビューの構築
  Widget _buildTransitionView(DrawerState drawerState) {
    return Stack(
      children: [
        // 正面ビュー（フェードアウト）
        if (_transitionAnimation.value < 1.0)
          _buildFrontView(drawerState),

        // 上視点ビュー（フェードイン）
        if (_transitionAnimation.value > 0.0)
          _buildTopView(drawerState),

        // トランジション中のオーバーレイ効果
        if (_transitionController.isAnimating)
          _buildTransitionOverlay(),
      ],
    );
  }

  /// 正面ビューのレンダリング
  Widget _buildFrontView(DrawerState drawerState) {
    final opacity = (1.0 - _transitionAnimation.value).clamp(0.0, 1.0);
    final scale = _scaleAnimation.value;
    final rotation = _rotationAnimation.value;

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // パースペクティブ
          ..scale(scale)
          ..rotateY(rotation)
          ..rotateX(_perspectiveAnimation.value * 0.3),
        child: Layered3DFridgeWidget(
          onSectionTap: widget.onSectionTap,
        ),
      ),
    );
  }

  /// 上視点ビューのレンダリング
  Widget _buildTopView(DrawerState drawerState) {
    final opacity = _transitionAnimation.value.clamp(0.0, 1.0);
    final inverseScale = 1.0 - (_scaleAnimation.value * 0.2);
    final rotation = -_rotationAnimation.value;

    return Opacity(
      opacity: opacity,
      child: Transform(
        alignment: Alignment.center,
        transform: Matrix4.identity()
          ..setEntry(3, 2, 0.001) // パースペクティブ
          ..scale(inverseScale)
          ..rotateY(rotation)
          ..rotateX(-_perspectiveAnimation.value * 0.5)
          ..translate(0.0, -20.0 * _transitionAnimation.value, 0.0), // 上方向への移動
        child: TopViewFridgeWidget(
          onSectionTap: widget.onSectionTap,
        ),
      ),
    );
  }

  /// トランジション中のオーバーレイ効果
  Widget _buildTransitionOverlay() {
    final progress = _transitionAnimation.value;

    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 1.5,
          colors: [
            Colors.white.withOpacity(0.1 * progress),
            Colors.blue[50]!.withOpacity(0.05 * progress),
            Colors.transparent,
          ],
          stops: const [0.0, 0.5, 1.0],
        ),
      ),
      child: _buildTransitionParticles(),
    );
  }

  /// トランジション中のパーティクル効果
  Widget _buildTransitionParticles() {
    return CustomPaint(
      painter: TransitionParticlesPainter(
        progress: _transitionAnimation.value,
        rotation: _rotationAnimation.value,
      ),
      size: Size.infinite,
    );
  }
}

/// トランジション中のパーティクル効果描画
class TransitionParticlesPainter extends CustomPainter {
  final double progress;
  final double rotation;

  TransitionParticlesPainter({
    required this.progress,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0.0 || progress >= 1.0) return;

    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.3 * progress)
      ..style = PaintingStyle.fill;

    // パーティクルの描画
    final random = math.Random(42); // 固定シードで一貫性を保つ
    for (int i = 0; i < 20; i++) {
      final x = size.width * random.nextDouble();
      final y = size.height * random.nextDouble();
      final radius = 2.0 * progress * (0.5 + random.nextDouble() * 0.5);

      // 回転に応じてパーティクルを移動
      final rotatedX = x + (rotation * 50 * random.nextDouble());
      final rotatedY = y + (progress * 30 * random.nextDouble());

      canvas.drawCircle(
        Offset(rotatedX, rotatedY),
        radius,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(TransitionParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.rotation != rotation;
  }
}

/// トランジション状態の管理用ミックスイン
mixin ViewTransitionMixin<T extends StatefulWidget> on State<T> {
  late AnimationController transitionController;
  late Animation<double> transitionCurve;

  @override
  void initState() {
    super.initState();
    transitionController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this as TickerProvider,
    );

    transitionCurve = CurvedAnimation(
      parent: transitionController,
      curve: Curves.easeInOutCubic,
    );
  }

  @override
  void dispose() {
    transitionController.dispose();
    super.dispose();
  }

  /// 滑らかなビュー切り替え
  Future<void> animateViewChange() async {
    await transitionController.forward();
    await Future.delayed(const Duration(milliseconds: 100));
    await transitionController.reverse();
  }
}