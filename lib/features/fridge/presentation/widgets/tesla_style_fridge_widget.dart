import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;
import '../providers/fridge_view_provider.dart';
import '../styles/tesla_style_colors.dart';

/// テスラ風シンプル3D冷蔵庫ウィジェット（ミニマルデザイン、清潔感のあるUI）
class TeslaStyleFridgeWidget extends ConsumerStatefulWidget {
  final void Function(FridgeCompartment compartment, int level) onSectionTap;

  const TeslaStyleFridgeWidget({super.key, required this.onSectionTap});

  @override
  ConsumerState<TeslaStyleFridgeWidget> createState() =>
      _TeslaStyleFridgeWidgetState();
}

class _TeslaStyleFridgeWidgetState extends ConsumerState<TeslaStyleFridgeWidget>
    with TickerProviderStateMixin {
  // アニメーションコントローラー
  late final AnimationController _leftDoorController;
  late final AnimationController _rightDoorController;
  late final AnimationController _vegDrawerController;
  late final AnimationController _freezerController;
  late final AnimationController _pulseController;

  // アニメーション値
  late final Animation<double> _leftDoorAngle;
  late final Animation<double> _rightDoorAngle;
  late final Animation<double> _vegDrawerOffset;
  late final Animation<double> _freezerOffset;
  late final Animation<double> _pulseValue;

  // 状態管理
  bool _leftDoorOpen = false;
  bool _rightDoorOpen = false;
  bool _vegDrawerOpen = false;
  bool _freezerOpen = false;

  @override
  void initState() {
    super.initState();

    // コントローラー初期化（テスラ風のスムーズなアニメーション）
    _leftDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _rightDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _vegDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _freezerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    // アニメーション定義（テスラ風のなめらかな動き）
    _leftDoorAngle = Tween<double>(
      begin: 0.0,
      end: -1.2,
    ).animate(CurvedAnimation(
      parent: _leftDoorController,
      curve: Curves.easeInOut,
    ));

    _rightDoorAngle = Tween<double>(
      begin: 0.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _rightDoorController,
      curve: Curves.easeInOut,
    ));

    _vegDrawerOffset = Tween<double>(
      begin: 0.0,
      end: -70.0,
    ).animate(CurvedAnimation(
      parent: _vegDrawerController,
      curve: Curves.easeInOut,
    ));

    _freezerOffset = Tween<double>(
      begin: 0.0,
      end: -80.0,
    ).animate(CurvedAnimation(
      parent: _freezerController,
      curve: Curves.easeInOut,
    ));

    _pulseValue = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _leftDoorController.dispose();
    _rightDoorController.dispose();
    _vegDrawerController.dispose();
    _freezerController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final counts = ref.watch(sectionCountsProvider);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Container(
        decoration: BoxDecoration(
          color: TeslaStyleColors.background,
          borderRadius: BorderRadius.circular(24),
          boxShadow: TeslaStyleColors.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
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
                    _pulseController,
                  ]),
                  builder: (context, _) {
                    return CustomPaint(
                      size: Size.infinite,
                      painter: TeslaStyleFridgePainter(
                        leftDoorAngle: _leftDoorAngle.value,
                        rightDoorAngle: _rightDoorAngle.value,
                        vegDrawerOffset: _vegDrawerOffset.value,
                        freezerOffset: _freezerOffset.value,
                        pulseValue: _pulseValue.value,
                      ),
                    );
                  },
                ),

                // インタラクション領域
                _buildInteractionZones(counts),
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
            // 左扉
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topLeft,
              widthFactor: 0.5,
              heightFactor: 0.2,
              topOffset: 0.05,
              onTap: () => _toggleLeftDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorLeft, 0),
              semanticsLabel: '左ドア',
              semanticsValue: _leftDoorOpen ? '開' : '閉',
              badge: _buildTeslaBadge(counts, FridgeCompartment.doorLeft, 0),
            ),

            // 右扉
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topRight,
              widthFactor: 0.5,
              heightFactor: 0.2,
              topOffset: 0.05,
              onTap: () => _toggleRightDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorRight, 0),
              semanticsLabel: '右ドア',
              semanticsValue: _rightDoorOpen ? '開' : '閉',
              badge: _buildTeslaBadge(counts, FridgeCompartment.doorRight, 0),
            ),

            // 冷蔵室棚
            ...List.generate(3, (i) => _buildShelfZone(i, counts, constraints)),

            // 野菜室
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.bottomCenter,
              widthFactor: 0.8,
              heightFactor: 0.12,
              topOffset: 0.7,
              onTap: () => _toggleVegDrawer(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.vegetableDrawer, 0),
              semanticsLabel: '野菜室',
              semanticsValue: _vegDrawerOpen ? '開' : '閉',
              badge:
                  _buildTeslaBadge(counts, FridgeCompartment.vegetableDrawer, 0),
            ),

            // 冷凍庫
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.bottomCenter,
              widthFactor: 0.8,
              heightFactor: 0.12,
              topOffset: 0.85,
              onTap: () => _toggleFreezer(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.freezer, 0),
              semanticsLabel: '冷凍庫',
              semanticsValue: _freezerOpen ? '開' : '閉',
              badge: _buildTeslaBadge(counts, FridgeCompartment.freezer, 0),
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
              borderRadius: BorderRadius.circular(16),
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
    final top = height * (0.28 + level * 0.12);
    final shelfHeight = height * 0.1;

    return Positioned(
      left: constraints.maxWidth * 0.15,
      right: constraints.maxWidth * 0.15,
      top: top,
      height: shelfHeight,
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          widget.onSectionTap(FridgeCompartment.refrigerator, level);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(12),
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
                      color: TeslaStyleColors.textSecondary,
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: _buildTeslaBadge(
                    counts, FridgeCompartment.refrigerator, level),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeslaBadge(
      Map<String, int> counts, FridgeCompartment compartment, int level) {
    final key = '${compartment.name}:$level';
    final count = counts[key] ?? 0;
    if (count == 0) return const SizedBox.shrink();

    return Align(
      alignment: Alignment.topRight,
      child: AnimatedBuilder(
        animation: _pulseController,
        builder: (context, _) {
          final pulse = (math.sin(_pulseValue.value * 2 * math.pi) + 1) / 2;
          return Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: TeslaStyleColors.badgeBackground,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: TeslaStyleColors.primary.withOpacity(0.3 + pulse * 0.2),
                  blurRadius: 12 + pulse * 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              '$count',
              style: const TextStyle(
                color: TeslaStyleColors.badgeText,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          );
        },
      ),
    );
  }

  // アニメーション制御メソッド
  void _toggleLeftDoor() {
    _triggerHapticFeedback();
    _leftDoorOpen = !_leftDoorOpen;
    if (_leftDoorOpen) {
      _leftDoorController.forward();
    } else {
      _leftDoorController.reverse();
    }
  }

  void _toggleRightDoor() {
    _triggerHapticFeedback();
    _rightDoorOpen = !_rightDoorOpen;
    if (_rightDoorOpen) {
      _rightDoorController.forward();
    } else {
      _rightDoorController.reverse();
    }
  }

  void _toggleVegDrawer() {
    _triggerHapticFeedback();
    _vegDrawerOpen = !_vegDrawerOpen;
    if (_vegDrawerOpen) {
      _vegDrawerController.forward();
    } else {
      _vegDrawerController.reverse();
    }
  }

  void _toggleFreezer() {
    _triggerHapticFeedback();
    _freezerOpen = !_freezerOpen;
    if (_freezerOpen) {
      _freezerController.forward();
    } else {
      _freezerController.reverse();
    }
  }

  void _triggerHapticFeedback() {
    HapticFeedback.mediumImpact();
  }
}

/// テスラ風シンプル3D冷蔵庫ペインター
class TeslaStyleFridgePainter extends CustomPainter {
  final double leftDoorAngle;
  final double rightDoorAngle;
  final double vegDrawerOffset;
  final double freezerOffset;
  final double pulseValue;

  TeslaStyleFridgePainter({
    this.leftDoorAngle = 0.0,
    this.rightDoorAngle = 0.0,
    this.vegDrawerOffset = 0.0,
    this.freezerOffset = 0.0,
    this.pulseValue = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;

    // 3D遠近法の設定
    final double perspective = 0.001;

    // 背景
    _drawBackground(canvas, size);

    // メイン冷蔵庫本体
    _draw3DFridgeBody(canvas, size);

    // 扉（3D回転）
    _draw3DDoors(canvas, size);

    // 引き出し（3Dスライド）
    _draw3DDrawers(canvas, size);

    // 内部照明
    _drawInteriorLighting(canvas, size);

    // 微細な影とハイライト
    _drawSubtleShadows(canvas, size);
  }

  void _drawBackground(Canvas canvas, Size size) {
    final Rect bgRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = TeslaStyleColors.subtleGradient.createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);
  }

  void _draw3DFridgeBody(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double fridgeWidth = width * 0.8;
    final double fridgeHeight = height * 0.9;
    final double centerX = width / 2;
    final double topY = height * 0.05;

    // 冷蔵庫本体
    final RRect mainBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight / 2),
        width: fridgeWidth,
        height: fridgeHeight,
      ),
      const Radius.circular(20),
    );

    // メインボディのグラデーション
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.backgroundSecondary,
          TeslaStyleColors.surface,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(mainBody.outerRect);

    canvas.drawRRect(mainBody, bodyPaint);

    // サイドパネル（3D効果）
    _drawSidePanel(canvas, centerX - fridgeWidth / 2, topY, fridgeHeight);
    _drawSidePanel(canvas, centerX + fridgeWidth / 2, topY, fridgeHeight);

    // 微細なエッジハイライト
    final Paint edgePaint = Paint()
      ..color = TeslaStyleColors.primary.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(mainBody, edgePaint);
  }

  void _drawSidePanel(Canvas canvas, double x, double y, double h) {
    final double depth = 40;
    final Path sidePath = Path()
      ..moveTo(x, y)
      ..lineTo(x + depth * 0.4, y - depth * 0.2)
      ..lineTo(x + depth * 0.4, y + h - depth * 0.2)
      ..lineTo(x, y + h)
      ..close();

    final Paint sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.shadow.withOpacity(0.3),
          TeslaStyleColors.shadow.withOpacity(0.1),
        ],
      ).createShader(sidePath.getBounds());

    canvas.drawPath(sidePath, sidePaint);
  }

  void _draw3DDoors(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double doorWidth = size.width * 0.38;
    final double doorHeight = size.height * 0.2;
    final double topY = size.height * 0.05;

    // 左扉
    _draw3DDoor(canvas, centerX - doorWidth, topY, doorWidth, doorHeight,
        leftDoorAngle, true);

    // 右扉
    _draw3DDoor(
        canvas, centerX, topY, doorWidth, doorHeight, rightDoorAngle, false);
  }

  void _draw3DDoor(Canvas canvas, double x, double y, double w, double h,
      double angle, bool isLeft) {
    canvas.save();

    // 回転の中心点
    final double pivotX = isLeft ? x + w : x;
    final double pivotY = y + h / 2;

    canvas.translate(pivotX, pivotY);
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle))
        .storage);
    canvas.translate(-pivotX, -pivotY);

    // 扉面
    final RRect doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(16),
    );

    // 扉のグラデーション
    final Paint doorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.surface,
          TeslaStyleColors.backgroundSecondary,
        ],
      ).createShader(Rect.fromLTWH(x, y, w, h));

    canvas.drawRRect(doorRect, doorPaint);

    // エッジライン
    final Paint edgePaint = Paint()
      ..color = TeslaStyleColors.primary.withOpacity(0.4 + angle.abs() * 0.3)
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(doorRect, edgePaint);

    // ハンドル
    _drawMinimalistHandle(canvas, isLeft ? x + w - 12 : x + 8, y + h / 2);

    canvas.restore();
  }

  void _drawMinimalistHandle(Canvas canvas, double x, double y) {
    final Paint handlePaint = Paint()
      ..color = TeslaStyleColors.fridgeHandle
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double handleLength = 28;
    canvas.drawLine(
      Offset(x, y - handleLength / 2),
      Offset(x, y + handleLength / 2),
      handlePaint,
    );
  }

  void _draw3DDrawers(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double drawerWidth = size.width * 0.72;
    final double drawerHeight = size.height * 0.1;

    // 野菜室
    final double vegY = size.height * 0.7 + vegDrawerOffset;
    _draw3DDrawer(canvas, centerX - drawerWidth / 2, vegY, drawerWidth,
        drawerHeight, vegDrawerOffset, TeslaStyleColors.accent);

    // 冷凍庫
    final double freezerY = size.height * 0.85 + freezerOffset;
    _draw3DDrawer(canvas, centerX - drawerWidth / 2, freezerY, drawerWidth,
        drawerHeight, freezerOffset, TeslaStyleColors.primary);
  }

  void _draw3DDrawer(Canvas canvas, double x, double y, double w, double h,
      double offset, Color accentColor) {
    // 引き出し面
    final RRect drawerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(14),
    );

    final Paint drawerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.surface,
          accentColor.withOpacity(0.1),
        ],
      ).createShader(Rect.fromLTWH(x, y, w, h));

    canvas.drawRRect(drawerRect, drawerPaint);

    // 取っ手
    final double handleY = y + h / 2;
    final Paint handlePaint = Paint()
      ..color = accentColor.withOpacity(math.min(0.8 + offset.abs() * 0.01, 1.0))
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(
      Offset(x + w / 2 - 20, handleY),
      Offset(x + w / 2 + 20, handleY),
      handlePaint,
    );

    // 奥行きエフェクト
    if (offset != 0) {
      _drawDrawerDepth(canvas, x, y, w, h, offset, accentColor);
    }

    // エッジライン
    final Paint edgePaint = Paint()
      ..color = accentColor.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    canvas.drawRRect(drawerRect, edgePaint);
  }

  void _drawDrawerDepth(Canvas canvas, double x, double y, double w, double h,
      double offset, Color color) {
    final Path depthPath = Path()
      ..moveTo(x, y)
      ..lineTo(x - offset * 0.2, y - offset * 0.15)
      ..lineTo(x + w - offset * 0.2, y - offset * 0.15)
      ..lineTo(x + w, y)
      ..close();

    final Paint depthPaint = Paint()
      ..color = TeslaStyleColors.shadow.withOpacity(0.3);

    canvas.drawPath(depthPath, depthPaint);
  }

  void _drawInteriorLighting(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double topY = size.height * 0.25;
    final double interiorWidth = size.width * 0.7;
    final double interiorHeight = size.height * 0.4;

    // 内部の柔らかい光
    final Rect interiorRect = Rect.fromCenter(
      center: Offset(centerX, topY + interiorHeight / 2),
      width: interiorWidth,
      height: interiorHeight,
    );

    final Paint interiorGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.9,
        colors: [
          TeslaStyleColors.fridgeInterior,
          TeslaStyleColors.primary.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(interiorRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(interiorRect, const Radius.circular(12)),
      interiorGlow,
    );

    // 棚のライン（微細）
    for (int i = 0; i < 3; i++) {
      final double shelfY = topY + (i + 1) * (interiorHeight / 4);
      _drawShelfLine(canvas, centerX - interiorWidth / 2 + 15, shelfY,
          centerX + interiorWidth / 2 - 15, shelfY);
    }
  }

  void _drawShelfLine(Canvas canvas, double x1, double y1, double x2, double y2) {
    final Paint shelfPaint = Paint()
      ..color = TeslaStyleColors.primary.withOpacity(0.2)
      ..strokeWidth = 1.0
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), shelfPaint);
  }

  void _drawSubtleShadows(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double fridgeWidth = size.width * 0.8;
    final double fridgeHeight = size.height * 0.9;
    final double topY = size.height * 0.05;

    // 底面の影
    final Paint shadowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          TeslaStyleColors.shadow.withOpacity(0.2),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight + 20),
        width: fridgeWidth * 0.9,
        height: 40,
      ));

    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight + 20),
        width: fridgeWidth * 0.9,
        height: 40,
      ),
      shadowPaint,
    );
  }

  @override
  bool shouldRepaint(covariant TeslaStyleFridgePainter oldDelegate) {
    return oldDelegate.leftDoorAngle != leftDoorAngle ||
        oldDelegate.rightDoorAngle != rightDoorAngle ||
        oldDelegate.vegDrawerOffset != vegDrawerOffset ||
        oldDelegate.freezerOffset != freezerOffset ||
        oldDelegate.pulseValue != pulseValue;
  }
}