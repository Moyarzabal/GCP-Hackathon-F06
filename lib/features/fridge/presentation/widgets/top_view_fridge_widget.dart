import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart';
import '../providers/drawer_state_provider.dart';
import '../animations/drawer_animation_config.dart';

/// 上から見た冷蔵庫のウィジェット
class TopViewFridgeWidget extends ConsumerStatefulWidget {
  final Function(FridgeCompartment compartment, int level) onSectionTap;

  const TopViewFridgeWidget({
    Key? key,
    required this.onSectionTap,
  }) : super(key: key);

  @override
  ConsumerState<TopViewFridgeWidget> createState() => _TopViewFridgeWidgetState();
}

class _TopViewFridgeWidgetState extends ConsumerState<TopViewFridgeWidget> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final drawerState = ref.watch(drawerStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 背景
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Color(0xFFF5F5F5),
                    Color(0xFFE8E8E8),
                  ],
                ),
              ),
            ),
            // 冷蔵庫本体（上から見た形）
            Center(
              child: _buildTopViewFridge(constraints, drawerState),
            ),
            // 戻るボタン
            Positioned(
              top: 40,
              left: 20,
              child: FloatingActionButton(
                mini: true,
                onPressed: () {
                  ref.read(drawerStateProvider.notifier).backToFrontView();
                },
                backgroundColor: Colors.white.withOpacity(0.9),
                child: const Icon(Icons.arrow_back, color: Colors.black87),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopViewFridge(BoxConstraints constraints, DrawerState drawerState) {
    final fridgeWidth = constraints.maxWidth * 0.6;
    final fridgeHeight = constraints.maxHeight * 0.8;

    return Container(
      width: fridgeWidth,
      height: fridgeHeight,
      child: CustomPaint(
        painter: TopViewFridgePainter(
          openDrawer: drawerState.openDrawer,
        ),
        child: Stack(
          children: [
            // 引き出し内部のタッチ領域
            if (drawerState.openDrawer != null)
              _buildDrawerTouchArea(fridgeWidth, fridgeHeight, drawerState.openDrawer!),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerTouchArea(double fridgeWidth, double fridgeHeight, OpenDrawerInfo drawerInfo) {
    // 引き出しの位置を計算
    final isVegetableDrawer = drawerInfo.compartment == FridgeCompartment.vegetableDrawer;
    final drawerTop = isVegetableDrawer ? fridgeHeight * 0.45 : fridgeHeight * 0.65;
    final drawerHeight = fridgeHeight * 0.15;

    return Positioned(
      left: fridgeWidth * 0.1,
      top: drawerTop,
      width: fridgeWidth * 0.8,
      height: drawerHeight,
      child: GestureDetector(
        onTap: () {
          ref.read(drawerStateProvider.notifier).tapDrawerInner();
          widget.onSectionTap(drawerInfo.compartment, drawerInfo.level);
        },
        child: Container(
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(
              color: Colors.blue.withOpacity(0.3),
              width: 2,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'タップして${isVegetableDrawer ? '野菜室' : '冷凍庫'}を見る',
                style: const TextStyle(
                  color: Colors.blue,
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 上から見た冷蔵庫を描画するCustomPainter
class TopViewFridgePainter extends CustomPainter {
  final OpenDrawerInfo? openDrawer;

  TopViewFridgePainter({
    this.openDrawer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint();
    final width = size.width;
    final height = size.height;

    // 冷蔵庫本体の外形
    _drawFridgeBody(canvas, paint, width, height);

    // 扉の境界線
    _drawDoorDividers(canvas, paint, width, height);

    // 引き出しセクション
    _drawDrawerSections(canvas, paint, width, height);

    // 開いた引き出しを描画
    if (openDrawer != null) {
      _drawOpenDrawer(canvas, paint, width, height, openDrawer!);
    }
  }

  void _drawFridgeBody(Canvas canvas, Paint paint, double width, double height) {
    // 冷蔵庫本体
    paint.color = Colors.white;
    paint.style = PaintingStyle.fill;
    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, width, height),
      const Radius.circular(12),
    );
    canvas.drawRRect(bodyRect, paint);

    // 外枠
    paint.color = Colors.grey[400]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawRRect(bodyRect, paint);
  }

  void _drawDoorDividers(Canvas canvas, Paint paint, double width, double height) {
    paint.color = Colors.grey[300]!;
    paint.strokeWidth = 1;

    // 上段扉の中央分割線
    final topDividerY = height * 0.35;
    canvas.drawLine(
      Offset(width * 0.5, 0),
      Offset(width * 0.5, topDividerY),
      paint,
    );

    // 上段と引き出しセクションの境界
    canvas.drawLine(
      Offset(0, topDividerY),
      Offset(width, topDividerY),
      paint,
    );

    // 引き出しセクション間の境界
    final middleDividerY = height * 0.6;
    canvas.drawLine(
      Offset(0, middleDividerY),
      Offset(width, middleDividerY),
      paint,
    );
  }

  void _drawDrawerSections(Canvas canvas, Paint paint, double width, double height) {
    // 野菜室（2段目）
    _drawDrawerSection(
      canvas, paint, width, height,
      top: height * 0.35,
      sectionHeight: height * 0.25,
      label: '野菜室',
      isOpen: openDrawer?.compartment == FridgeCompartment.vegetableDrawer,
    );

    // 冷凍庫（3段目）
    _drawDrawerSection(
      canvas, paint, width, height,
      top: height * 0.6,
      sectionHeight: height * 0.4,
      label: '冷凍庫',
      isOpen: openDrawer?.compartment == FridgeCompartment.freezer,
    );
  }

  void _drawDrawerSection(
    Canvas canvas, Paint paint, double width, double height,
    {required double top, required double sectionHeight, required String label, required bool isOpen}
  ) {
    if (isOpen) return; // 開いている引き出しは別途描画

    // 引き出しの背景
    paint.color = Colors.grey[100]!;
    paint.style = PaintingStyle.fill;
    final drawerRect = Rect.fromLTWH(
      width * 0.05,
      top + sectionHeight * 0.1,
      width * 0.9,
      sectionHeight * 0.8,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawerRect, const Radius.circular(8)),
      paint,
    );

    // 引き出しの境界
    paint.color = Colors.grey[400]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1;
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawerRect, const Radius.circular(8)),
      paint,
    );

    // ハンドル
    paint.color = Colors.grey[500]!;
    paint.style = PaintingStyle.fill;
    final handleRect = Rect.fromLTWH(
      width * 0.4,
      top + height * 0.8,
      width * 0.2,
      height * 0.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(4)),
      paint,
    );
  }

  void _drawOpenDrawer(Canvas canvas, Paint paint, double width, double height, OpenDrawerInfo drawerInfo) {
    final isVegetableDrawer = drawerInfo.compartment == FridgeCompartment.vegetableDrawer;
    final baseTop = isVegetableDrawer ? height * 0.35 : height * 0.6;
    final sectionHeight = isVegetableDrawer ? height * 0.25 : height * 0.4;

    // 引き出し本体（静的位置）
    final drawerRect = Rect.fromLTWH(
      width * 0.05,
      baseTop + sectionHeight * 0.1,
      width * 0.9,
      sectionHeight * 0.8,
    );

    // 引き出し背景色
    paint.color = Colors.grey[50]!;
    paint.style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawerRect, const Radius.circular(8)),
      paint,
    );

    // 引き出しの縁
    paint.color = Colors.grey[400]!;
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 2;
    canvas.drawRRect(
      RRect.fromRectAndRadius(drawerRect, const Radius.circular(8)),
      paint,
    );

    // 内部の仕切り（格子模様）
    _drawDrawerDividers(canvas, paint, drawerRect);

    // ハンドル
    paint.color = Colors.grey[600]!;
    paint.style = PaintingStyle.fill;
    final handleRect = Rect.fromLTWH(
      width * 0.4,
      baseTop + sectionHeight * 0.85,
      width * 0.2,
      sectionHeight * 0.1,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(4)),
      paint,
    );
  }

  void _drawDrawerDividers(Canvas canvas, Paint paint, Rect drawerRect) {
    paint.color = Colors.grey[300]!;
    paint.strokeWidth = 1;

    // 縦の仕切り
    for (int i = 1; i < 3; i++) {
      final x = drawerRect.left + (drawerRect.width / 3) * i;
      canvas.drawLine(
        Offset(x, drawerRect.top + drawerRect.height * 0.1),
        Offset(x, drawerRect.bottom - drawerRect.height * 0.1),
        paint,
      );
    }

    // 横の仕切り
    for (int i = 1; i < 2; i++) {
      final y = drawerRect.top + (drawerRect.height / 2) * i;
      canvas.drawLine(
        Offset(drawerRect.left + drawerRect.width * 0.1, y),
        Offset(drawerRect.right - drawerRect.width * 0.1, y),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant TopViewFridgePainter oldDelegate) {
    return oldDelegate.openDrawer != openDrawer;
  }
}