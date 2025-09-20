import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../shared/models/product.dart';

/// 冷蔵庫の棚レイヤー（扉の奥に配置）
class FridgeShelfLayer extends StatelessWidget {
  final Function(FridgeCompartment, int) onSectionTap;
  final Map<String, int> counts;
  final bool isVisible; // 扉が開いているかどうか

  const FridgeShelfLayer({
    Key? key,
    required this.onSectionTap,
    required this.counts,
    required this.isVisible,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return AnimatedOpacity(
      opacity: isVisible ? 1.0 : 0.0,
      duration: const Duration(milliseconds: 300),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return CustomPaint(
            size: Size(constraints.maxWidth, constraints.maxHeight),
            painter: ShelfPainter(isVisible: isVisible),
            child: Stack(
              children: _buildShelfTouchZones(constraints),
            ),
          );
        },
      ),
    );
  }

  List<Widget> _buildShelfTouchZones(BoxConstraints constraints) {
    final List<Widget> shelves = [];
    final double height = constraints.maxHeight;
    final double width = constraints.maxWidth;

    // 冷蔵庫本体のサイズと位置に合わせる
    final double fridgeBodyLeft = width * 0.1;
    final double fridgeBodyWidth = width * 0.8;
    final double fridgeBodyTop = height * 0.02;
    final double fridgeBodyHeight = height * 0.95;

    // 棚は1段目（大扉）の領域内に配置（バランス調整対応）
    final double shelfAreaHeight = fridgeBodyHeight * 0.55; // 1段目: 55%

    // 3つの棚を均等に配置
    for (int i = 0; i < 3; i++) {
      final double top = fridgeBodyTop + (shelfAreaHeight / 3) * i;
      final double shelfHeight = shelfAreaHeight / 3;

      shelves.add(
        Positioned(
          left: fridgeBodyLeft,
          right: width - fridgeBodyLeft - fridgeBodyWidth,
          top: top,
          height: shelfHeight,
          child: GestureDetector(
            onTap: isVisible ? () {
              HapticFeedback.lightImpact();
              onSectionTap(FridgeCompartment.refrigerator, i);
            } : null,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border(
                  bottom: BorderSide(
                    color: Colors.blue.withOpacity(0.3),
                    width: 2,
                  ),
                ),
              ),
              child: Center(
                child: Text(
                  '冷蔵室 棚${i + 1}',
                  style: TextStyle(
                    color: Colors.grey[600]!.withOpacity(isVisible ? 0.8 : 0),
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ),
          ),
        ),
      );
    }
    
    return shelves;
  }
}

/// 棚の視覚的な描画
class ShelfPainter extends CustomPainter {
  final bool isVisible;
  
  ShelfPainter({required this.isVisible});
  
  @override
  void paint(Canvas canvas, Size size) {
    // 冷蔵庫本体のサイズと位置に合わせる
    final double fridgeBodyLeft = size.width * 0.1;
    final double fridgeBodyWidth = size.width * 0.8;
    final double fridgeBodyTop = size.height * 0.02;
    final double fridgeBodyHeight = size.height * 0.95;

    // 冷蔵庫内部の背景 - 白い冷蔵庫用
    final Paint backgroundPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.grey[50]!.withOpacity(0.8),
          Colors.grey[100]!.withOpacity(0.7),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final RRect background = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        fridgeBodyLeft,
        fridgeBodyTop,
        fridgeBodyWidth,
        fridgeBodyHeight * 0.55, // 1段目: 55%
      ),
      const Radius.circular(12),
    );
    
    canvas.drawRRect(background, backgroundPaint);
    
    // LED照明効果
    if (isVisible) {
      final Paint lightPaint = Paint()
        ..shader = RadialGradient(
          center: const Alignment(0, -0.5),
          radius: 1.5,
          colors: [
            Colors.white.withOpacity(0.3),
            Colors.blue.withOpacity(0.1),
            Colors.transparent,
          ],
        ).createShader(background.outerRect);
      
      canvas.drawRRect(background, lightPaint);
    }
    
    // 棚板の描画（メタリック質感）
    final double shelfAreaHeight = fridgeBodyHeight * 0.55; // 1段目: 55%
    for (int i = 0; i < 3; i++) {
      final double y = fridgeBodyTop + (shelfAreaHeight / 3) * i;
      final double shelfHeight = shelfAreaHeight / 3;

      // 棚板の本体
      final Rect shelfRect = Rect.fromLTWH(
        fridgeBodyLeft,
        y,
        fridgeBodyWidth,
        shelfHeight - 2,
      );
      
      // 棚板のグラデーション - クリアガラス風
      final Paint shelfPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.8),
            Colors.grey[100]!.withOpacity(0.6),
            Colors.white.withOpacity(0.8),
          ],
        ).createShader(shelfRect);
      
      canvas.drawRect(shelfRect, shelfPaint);
      
      // 棚板のエッジ（クリアガラス風）
      final Paint edgePaint = Paint()
        ..color = Colors.grey[300]!.withOpacity(0.8)
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(fridgeBodyLeft, y + shelfHeight - 2),
        Offset(fridgeBodyLeft + fridgeBodyWidth, y + shelfHeight - 2),
        edgePaint,
      );
      
      // 棚板の反射光
      final Paint reflectionPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.white.withOpacity(0.1),
            Colors.transparent,
          ],
        ).createShader(Rect.fromLTWH(
          shelfRect.left,
          shelfRect.top,
          shelfRect.width,
          10,
        ));
      
      canvas.drawRect(
        Rect.fromLTWH(
          shelfRect.left,
          shelfRect.top,
          shelfRect.width,
          10,
        ),
        reflectionPaint,
      );
      
      // 棚板の影
      final Paint shadowPaint = Paint()
        ..color = Colors.black.withOpacity(0.3)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
      
      canvas.drawRect(
        Rect.fromLTWH(
          shelfRect.left,
          shelfRect.bottom - 5,
          shelfRect.width,
          5,
        ),
        shadowPaint,
      );
    }
  }

  @override
  bool shouldRepaint(ShelfPainter oldDelegate) => 
      oldDelegate.isVisible != isVisible;
}