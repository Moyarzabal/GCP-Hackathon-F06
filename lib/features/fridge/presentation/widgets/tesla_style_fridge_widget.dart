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
    // 左ドア（左端が軸）：正の値で右側（中央側）が手前に開く
    _leftDoorAngle = Tween<double>(
      begin: 0.0,
      end: 1.3,
    ).animate(CurvedAnimation(
      parent: _leftDoorController,
      curve: Curves.easeInOut,
    ));

    // 右ドア（右端が軸）：負の値で左側（中央側）が手前に開く
    _rightDoorAngle = Tween<double>(
      begin: 0.0,
      end: -1.3,
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
            // 冷蔵室棚（最下層に配置、IgnorePointerで扉が閉じている時はタップを無視）
            ...List.generate(3, (i) => _buildShelfZone(i, counts, constraints)),

            // 左扉（棚の上に配置、常にタップ可能）
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topLeft,
              widthFactor: 0.45,  // 扉の幅
              heightFactor: 0.58,  // 扉の高さ（0.05 + 0.58 = 0.63）
              topOffset: 0.05,
              onTap: () => _toggleLeftDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorLeft, 0),
              semanticsLabel: '左ドア',
              semanticsValue: _leftDoorOpen ? '開' : '閉',
              badge: _buildTeslaBadge(counts, FridgeCompartment.doorLeft, 0),
            ),

            // 右扉（棚の上に配置、常にタップ可能）
            _buildTouchZone(
              constraints: constraints,
              alignment: Alignment.topRight,
              widthFactor: 0.45,  // 扉の幅
              heightFactor: 0.58,  // 扉の高さ（0.05 + 0.58 = 0.63）
              topOffset: 0.05,
              onTap: () => _toggleRightDoor(),
              onDoubleTap: () =>
                  widget.onSectionTap(FridgeCompartment.doorRight, 0),
              semanticsLabel: '右ドア',
              semanticsValue: _rightDoorOpen ? '開' : '閉',
              badge: _buildTeslaBadge(counts, FridgeCompartment.doorRight, 0),
            ),

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
    // 扉の範囲（0.05～0.63）を完全に活用するよう棚を配置
    // 扉の上端0.05から開始し、下端0.63まで使う（高さ0.58）
    // 3つの棚を隙間なく配置
    final double shelfSpacing = 0.58 / 3;  // 約0.193333
    final top = height * (0.05 + level * shelfSpacing);  // 0.05, 0.243333, 0.436666
    final shelfHeight = height * shelfSpacing;  // 各棚の高さ

    return Positioned(
      left: constraints.maxWidth * 0.10,  // 扉の幅に合わせて棚の幅も拡大
      right: constraints.maxWidth * 0.10,
      top: top,
      height: shelfHeight,
      child: IgnorePointer(
        // 両方の扉が開いていない時はタップを無効化
        ignoring: !(_leftDoorOpen && _rightDoorOpen),
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
            child: _buildTeslaBadge(
                counts, FridgeCompartment.refrigerator, level),
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

    // リアルな冷蔵庫の棚を描画
    _drawRealisticInterior(canvas, size);

    // 引き出し（3Dスライド）
    _draw3DDrawers(canvas, size);

    // 扉（3D回転）を最後に描画（最前面）
    _draw3DDoors(canvas, size);

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

    // サイドパネルは削除（シンプルなフラット冷蔵庫）

    // 微細なエッジハイライト
    final Paint edgePaint = Paint()
      ..color = TeslaStyleColors.primary.withOpacity(0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    canvas.drawRRect(mainBody, edgePaint);
  }

  // _drawSidePanelは削除（シンプルなフラット冷蔵庫）

  void _draw3DDoors(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double doorWidth = size.width * 0.45;  // タッチゾーンと同じ幅に統一
    final double doorHeight = size.height * 0.58;  // 扉の高さ（0.05から0.63まで）
    final double topY = size.height * 0.05;

    // 左扉（左側に配置、左端が軸）
    _draw3DDoor(canvas, centerX - doorWidth, topY, doorWidth, doorHeight,
        leftDoorAngle, true);

    // 右扉（右側に配置、右端が軸）
    _draw3DDoor(
        canvas, centerX, topY, doorWidth, doorHeight, rightDoorAngle, false);
  }

  void _draw3DDoor(Canvas canvas, double x, double y, double w, double h,
      double angle, bool isLeft) {
    canvas.save();

    // 回転の中心点（冷蔵庫の外側が軸）
    // 左ドア（isLeft=true）: 左端(x)が軸で、右側（中央側）が手前に開く
    // 右ドア（isLeft=false）: 右端(x+w)が軸で、左側（中央側）が手前に開く
    final double pivotX = isLeft ? x : (x + w);
    final double pivotY = y + h / 2;

    canvas.translate(pivotX, pivotY);
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.001)  // 透視投影
          ..rotateY(angle))  // angleをそのまま使用
        .storage);
    canvas.translate(-pivotX, -pivotY);

    // 扉面
    final RRect doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(16),
    );

    // 扉が開いているかどうかで描画を変える
    if (angle.abs() > 0.1) {
      // 扉が開いている場合、裏側（内側）をシンプルな単色で描画
      final Paint backPaint = Paint()
        ..color = const Color(0xFFF5F5F5); // シンプルな白系の色

      canvas.drawRRect(doorRect, backPaint);
    } else {
      // 扉が閉じている場合、表側のグラデーション
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

      // エッジライン（表面のみ）
      final Paint edgePaint = Paint()
        ..color = TeslaStyleColors.primary.withOpacity(0.4)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawRRect(doorRect, edgePaint);
    }

    // 扉の厚み効果は削除（シンプルなフラット扉）

    // ハンドル（扉が閉じている場合のみ表示）
    if (angle.abs() <= 0.1) {
      _drawMinimalistHandle(canvas, isLeft ? x + w - 20 : x + 20, y + h / 2);
    }

    canvas.restore();
  }

  // _drawDoorDepthは削除（シンプルなフラット扉）

  void _drawMinimalistHandle(Canvas canvas, double x, double y) {
    // 安全性チェック
    if (!x.isFinite || !y.isFinite) return;

    final Paint handlePaint = Paint()
      ..color = const Color(0xFFCBD5E1) // 直接色を指定
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final double handleLength = 28;
    final Offset start = Offset(x, y - handleLength / 2);
    final Offset end = Offset(x, y + handleLength / 2);

    // Offsetの値をチェック
    if (!start.isFinite || !end.isFinite) return;

    canvas.drawLine(start, end, handlePaint);
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
      ..color = accentColor.withOpacity(math.min(0.8 + offset.abs() * 0.001, 1.0))
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

    // 引き出しの奥行きエフェクトは削除（シンプルなフラット引き出し）
  }

  void _drawRealisticInterior(Canvas canvas, Size size) {
    if (leftDoorAngle == 0.0 && rightDoorAngle == 0.0) return;

    final double centerX = size.width / 2;
    final double topY = size.height * 0.05;
    final double interiorWidth = size.width * 0.8;
    final double interiorHeight = size.height * 0.58;

    // 内部背景（白い内壁）
    final Rect interiorRect = Rect.fromCenter(
      center: Offset(centerX, topY + interiorHeight / 2),
      width: interiorWidth,
      height: interiorHeight,
    );

    final Paint interiorPaint = Paint()
      ..color = const Color(0xFFF8F9FA);

    canvas.drawRRect(
      RRect.fromRectAndRadius(interiorRect, const Radius.circular(8)),
      interiorPaint,
    );

    // 棚板を描画（3つの棚）
    _drawShelves(canvas, centerX, topY, interiorWidth, interiorHeight);

    // ドアポケットは削除（シンプルな扉のみ）
  }

  void _drawShelves(Canvas canvas, double centerX, double topY, double width, double height) {
    final double shelfSpacing = height / 3;
    final double shelfLeft = centerX - width / 2 + 8;
    final double shelfRight = centerX + width / 2 - 8;
    final double shelfDepth = 6; // 棚板の厚み

    for (int i = 1; i < 3; i++) {
      final double shelfY = topY + i * shelfSpacing;

      // 棚板の影は削除（シンプルなフラット棚）

      // 棚板本体（シンプルなガラス棚）
      final Paint shelfPaint = Paint()
        ..color = const Color(0xFFE8F4F8).withOpacity(0.8);

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTRB(shelfLeft, shelfY, shelfRight, shelfY + shelfDepth),
          const Radius.circular(3),
        ),
        shelfPaint,
      );

      // 反射エフェクトは削除（シンプルな棚板）

      // 棚板の前面エッジ（強調）
      final Paint frontEdgePaint = Paint()
        ..color = const Color(0xFF90CAF9).withOpacity(0.6)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(shelfLeft, shelfY + shelfDepth),
        Offset(shelfRight, shelfY + shelfDepth),
        frontEdgePaint,
      );

      // 棚の支持具（左右に小さな支柱）
      _drawShelfSupport(canvas, shelfLeft - 3, shelfY, shelfDepth);
      _drawShelfSupport(canvas, shelfRight + 3, shelfY, shelfDepth);
    }
  }

  void _drawShelfSupport(Canvas canvas, double x, double y, double depth) {
    final Paint supportPaint = Paint()
      ..color = const Color(0xFFCFD8DC).withOpacity(0.8);

    // 小さな支持具
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(x - 1, y - 2, 2, depth + 4),
        const Radius.circular(1),
      ),
      supportPaint,
    );
  }

  // _drawDoorPocketsは削除（シンプルな扉のみ）

  // _drawDoorPocket, _drawBottleHolders, _drawPocketLabelは削除（シンプルな扉のみ）

  void _drawSubtleShadows(Canvas canvas, Size size) {
    // 全ての影は削除（シンプルなフラットデザイン）
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