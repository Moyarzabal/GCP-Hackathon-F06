import 'package:flutter/material.dart';

/// 冷蔵庫筐体の質感と棚などの静的レイヤーを描画するペインター
class FridgeBodyPainter extends CustomPainter {
  final ColorScheme colorScheme;

  FridgeBodyPainter({required this.colorScheme});

  @override
  void paint(Canvas canvas, Size size) {
    final double radius = 16;

    // 本体のメタリックボディ
    final Rect bodyRect = Offset.zero & size;
    final RRect body =
        RRect.fromRectAndRadius(bodyRect, Radius.circular(radius));
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          colorScheme.surfaceContainerHighest.withOpacity(0.95),
          colorScheme.surfaceContainerHigh,
        ],
      ).createShader(bodyRect);
    canvas.drawRRect(body, bodyPaint);

    // 外枠ハイライト/シャドウ（立体感）
    final Paint edgeHighlight = Paint()
      ..color = Colors.white.withOpacity(0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    final Paint edgeShadow = Paint()
      ..color = Colors.black.withOpacity(0.10)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawRRect(body.deflate(0.5), edgeHighlight);
    canvas.drawRRect(body.inflate(0.5), edgeShadow);

    // 内部の仕切りライン（棚/室）
    final Paint dividerPaint = Paint()
      ..color = colorScheme.outlineVariant.withOpacity(0.9)
      ..strokeWidth = 1.0;

    // ドア領域は上部 18%（左右） → 内部は 20% 以降
    final double yStart = size.height * 0.22;
    // 冷蔵室の棚 3 本
    for (int i = 0; i < 3; i++) {
      final double y = size.height * (0.22 + i * 0.10);
      canvas.drawLine(Offset(12, y), Offset(size.width - 12, y), dividerPaint);
    }

    // 野菜室と冷凍庫の境界
    final double vegetableTop = size.height * 0.68;
    final double freezerTop = size.height * 0.85;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, vegetableTop, size.width - 24, size.height * 0.10),
        const Radius.circular(10),
      ),
      Paint()
        ..color = colorScheme.surfaceContainerHigh
        ..style = PaintingStyle.fill,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, freezerTop, size.width - 24, size.height * 0.10),
        const Radius.circular(10),
      ),
      Paint()
        ..color = colorScheme.surfaceContainerHigh
        ..style = PaintingStyle.fill,
    );

    // ガラス棚風のハイライト（半透明）
    final Paint glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.white.withOpacity(0.06),
          Colors.white.withOpacity(0.0),
        ],
      ).createShader(
          Rect.fromLTWH(12, yStart, size.width - 24, size.height * 0.44));
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(12, yStart, size.width - 24, size.height * 0.44),
        const Radius.circular(10),
      ),
      glassPaint,
    );
  }

  @override
  bool shouldRepaint(covariant FridgeBodyPainter oldDelegate) {
    return oldDelegate.colorScheme != colorScheme;
  }
}
