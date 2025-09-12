import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import '../styles/tesla_style_colors.dart';

/// テスラ風ミニマルデザインの3D冷蔵庫ペインター
/// 
/// テスラのデザイン哲学に基づいた：
/// - ミニマルで洗練されたデザイン
/// - 白と水色のカラーパレット
/// - リアリスティックな3D表現
/// - 過度なエフェクトを避けたシンプルな美学
class TeslaStyle3DFridgePainter extends CustomPainter {
  final ColorScheme colorScheme;
  final double animationTime;
  final double leftDoorAngle;
  final double rightDoorAngle;
  final double vegDrawerOffset;
  final double freezerOffset;

  TeslaStyle3DFridgePainter({
    required this.colorScheme,
    this.animationTime = 0.0,
    this.leftDoorAngle = 0.0,
    this.rightDoorAngle = 0.0,
    this.vegDrawerOffset = 0.0,
    this.freezerOffset = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    
    // テスラ風の背景グラデーション
    _drawTeslaBackground(canvas, size);
    
    // ソフトなドロップシャドウ
    _drawFridgeShadow(canvas, size);
    
    // メイン冷蔵庫本体（3D）
    _draw3DFridgeBody(canvas, size);
    
    // 内部照明（扉が開いている場合）
    _drawInteriorLighting(canvas, size);
    
    // 扉（3D回転）
    _draw3DDoors(canvas, size);
    
    // 引き出し（3Dスライド）
    _draw3DDrawers(canvas, size);
    
    // ハイライトとエッジ
    _drawEdgeHighlights(canvas, size);
  }

  void _drawTeslaBackground(Canvas canvas, Size size) {
    final Rect bgRect = Offset.zero & size;
    
    // テスラ風の微妙なグラデーション背景
    final Paint bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TeslaStyleColors.background,
          TeslaStyleColors.backgroundSecondary,
          TeslaStyleColors.surfaceVariant,
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(bgRect);
    
    canvas.drawRect(bgRect, bgPaint);
  }

  void _drawFridgeShadow(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double shadowY = size.height * 0.92;
    final double shadowWidth = size.width * 0.7;
    final double shadowHeight = size.height * 0.08;
    
    // ソフトなドロップシャドウ
    final RRect shadowRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, shadowY),
        width: shadowWidth,
        height: shadowHeight,
      ),
      const Radius.circular(40),
    );
    
    final Paint shadowPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 1.0,
        colors: [
          TeslaStyleColors.shadow.withOpacity(0.3),
          TeslaStyleColors.shadow.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(shadowRect.outerRect);
    
    canvas.drawRRect(shadowRect, shadowPaint);
  }

  void _draw3DFridgeBody(Canvas canvas, Size size) {
    final double width = size.width;
    final double height = size.height;
    final double fridgeWidth = width * 0.8;
    final double fridgeHeight = height * 0.85;
    final double centerX = width / 2;
    final double topY = height * 0.08;
    
    // メイン冷蔵庫本体
    final RRect fridgeBody = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight / 2),
        width: fridgeWidth,
        height: fridgeHeight,
      ),
      const Radius.circular(16),
    );
    
    // 本体のグラデーション
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.surface,
          TeslaStyleColors.fridgeDoor.withOpacity(0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(fridgeBody.outerRect);
    
    canvas.drawRRect(fridgeBody, bodyPaint);
    
    // サイドパネル（3D奥行き）
    _draw3DSidePanel(canvas, centerX - fridgeWidth/2, topY, fridgeHeight, 30);
    _draw3DSidePanel(canvas, centerX + fridgeWidth/2, topY, fridgeHeight, -30);
    
    // 天板（3D）
    _draw3DTopPanel(canvas, centerX - fridgeWidth/2, topY, fridgeWidth, 30);
  }

  void _draw3DSidePanel(Canvas canvas, double x, double y, double h, double depth) {
    final Path sidePath = Path()
      ..moveTo(x, y + 16) // 角の丸みを考慮
      ..lineTo(x + depth * 0.5, y - depth * 0.3 + 16)
      ..lineTo(x + depth * 0.5, y + h - depth * 0.3 - 16)
      ..lineTo(x, y + h - 16)
      ..close();
    
    final Paint sidePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.fridgeDoor.withOpacity(0.8),
          TeslaStyleColors.shadow.withOpacity(0.4),
        ],
      ).createShader(sidePath.getBounds());
    
    canvas.drawPath(sidePath, sidePaint);
  }

  void _draw3DTopPanel(Canvas canvas, double x, double y, double w, double depth) {
    final Path topPath = Path()
      ..moveTo(x + 16, y) // 角の丸みを考慮
      ..lineTo(x + w - 16, y)
      ..lineTo(x + w - 16 + depth * 0.5, y - depth * 0.3)
      ..lineTo(x + 16 + depth * 0.5, y - depth * 0.3)
      ..close();
    
    final Paint topPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.surface,
          TeslaStyleColors.fridgeDoor.withOpacity(0.9),
        ],
      ).createShader(topPath.getBounds());
    
    canvas.drawPath(topPath, topPaint);
  }

  void _drawInteriorLighting(Canvas canvas, Size size) {
    if (leftDoorAngle == 0 && rightDoorAngle == 0) return;
    
    final double centerX = size.width / 2;
    final double interiorY = size.height * 0.25;
    final double interiorWidth = size.width * 0.7;
    final double interiorHeight = size.height * 0.45;
    
    // 内部の柔らかい照明
    final Rect interiorRect = Rect.fromCenter(
      center: Offset(centerX, interiorY + interiorHeight / 2),
      width: interiorWidth,
      height: interiorHeight,
    );
    
    final Paint interiorPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          TeslaStyleColors.fridgeInterior,
          TeslaStyleColors.fridgeInterior.withOpacity(0.7),
          TeslaStyleColors.fridgeInterior.withOpacity(0.3),
        ],
        stops: const [0.0, 0.7, 1.0],
      ).createShader(interiorRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(interiorRect, const Radius.circular(12)),
      interiorPaint,
    );
    
    // 棚のライン
    for (int i = 1; i <= 3; i++) {
      final double shelfY = interiorY + (i * interiorHeight / 4);
      _drawShelfLine(canvas, centerX - interiorWidth/2 + 20, shelfY, 
                    centerX + interiorWidth/2 - 20, shelfY);
    }
  }

  void _drawShelfLine(Canvas canvas, double x1, double y1, double x2, double y2) {
    final Paint shelfPaint = Paint()
      ..color = TeslaStyleColors.primary.withOpacity(0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), shelfPaint);
  }

  void _draw3DDoors(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double doorWidth = size.width * 0.38;
    final double doorHeight = size.height * 0.5;
    final double topY = size.height * 0.08;
    
    // 左扉
    _draw3DDoor(canvas, centerX - doorWidth - 5, topY, doorWidth, doorHeight, leftDoorAngle, true);
    
    // 右扉
    _draw3DDoor(canvas, centerX + 5, topY, doorWidth, doorHeight, rightDoorAngle, false);
  }

  void _draw3DDoor(Canvas canvas, double x, double y, double w, double h, double angle, bool isLeft) {
    canvas.save();
    
    // 回転の中心点（ヒンジ位置）
    final double pivotX = isLeft ? x + w : x;
    final double pivotY = y + h / 2;
    
    canvas.translate(pivotX, pivotY);
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.001) // 3D透視効果
          ..rotateY(angle))
        .storage);
    canvas.translate(-pivotX, -pivotY);
    
    // 扉の面
    final RRect doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(14),
    );
    
    // 扉のメインカラー
    final Paint doorPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.surface,
          TeslaStyleColors.fridgeDoor.withOpacity(0.95),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawRRect(doorRect, doorPaint);
    
    // 扉のエッジ
    final Paint edgePaint = Paint()
      ..color = TeslaStyleColors.shadowLight
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(doorRect, edgePaint);
    
    // ハンドル
    _drawTeslaHandle(canvas, isLeft ? x + w - 12 : x + 8, y + h/2, isLeft);
    
    // 扉が開いている場合の3D効果
    if (angle.abs() > 0.1) {
      _drawDoorDepthEffect(canvas, x, y, w, h, angle, isLeft);
    }
    
    canvas.restore();
  }

  void _drawTeslaHandle(Canvas canvas, double x, double y, bool isLeft) {
    final Paint handlePaint = Paint()
      ..color = TeslaStyleColors.fridgeHandle
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    final double handleLength = 60;
    
    // メインハンドル
    canvas.drawLine(
      Offset(x, y - handleLength/2),
      Offset(x, y + handleLength/2),
      handlePaint,
    );
    
    // ハンドルの立体感
    final Paint highlightPaint = Paint()
      ..color = TeslaStyleColors.surface
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(x - 1, y - handleLength/2),
      Offset(x - 1, y + handleLength/2),
      highlightPaint,
    );
  }

  void _drawDoorDepthEffect(Canvas canvas, double x, double y, double w, double h, double angle, bool isLeft) {
    final double depth = 15 * angle.abs();
    final Path depthPath = Path();
    
    if (isLeft) {
      depthPath.moveTo(x + w, y + 14);
      depthPath.lineTo(x + w + depth * 0.7, y - depth * 0.3 + 14);
      depthPath.lineTo(x + w + depth * 0.7, y + h - depth * 0.3 - 14);
      depthPath.lineTo(x + w, y + h - 14);
    } else {
      depthPath.moveTo(x, y + 14);
      depthPath.lineTo(x - depth * 0.7, y - depth * 0.3 + 14);
      depthPath.lineTo(x - depth * 0.7, y + h - depth * 0.3 - 14);
      depthPath.lineTo(x, y + h - 14);
    }
    depthPath.close();
    
    final Paint depthPaint = Paint()
      ..color = TeslaStyleColors.shadow.withOpacity(0.4);
    
    canvas.drawPath(depthPath, depthPaint);
  }

  void _draw3DDrawers(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double drawerWidth = size.width * 0.75;
    final double drawerHeight = size.height * 0.12;
    
    // 野菜室（中段）
    final double vegY = size.height * 0.65;
    _draw3DDrawer(canvas, centerX - drawerWidth/2, vegY + vegDrawerOffset, 
                  drawerWidth, drawerHeight, vegDrawerOffset, TeslaStyleColors.primary);
    
    // 冷凍庫（下段）
    final double freezerY = size.height * 0.8;
    _draw3DDrawer(canvas, centerX - drawerWidth/2, freezerY + freezerOffset, 
                  drawerWidth, drawerHeight, freezerOffset, TeslaStyleColors.accent);
  }

  void _draw3DDrawer(Canvas canvas, double x, double y, double w, double h, double offset, Color accentColor) {
    // 引き出しの面
    final RRect drawerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(10),
    );
    
    final Paint drawerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TeslaStyleColors.fridgeDoor,
          TeslaStyleColors.surface.withOpacity(0.95),
          TeslaStyleColors.fridgeDoor.withOpacity(0.9),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawRRect(drawerRect, drawerPaint);
    
    // 引き出しのエッジ
    final Paint edgePaint = Paint()
      ..color = TeslaStyleColors.shadowLight
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(drawerRect, edgePaint);
    
    // 取っ手（テスラ風シンプル）
    _drawDrawerHandle(canvas, x + w/2, y + h/2, accentColor, offset);
    
    // 奥行きエフェクト（引き出されている場合）
    if (offset.abs() > 1.0) {
      _drawDrawerDepthEffect(canvas, x, y, w, h, offset);
    }
  }

  void _drawDrawerHandle(Canvas canvas, double centerX, double centerY, Color accentColor, double offset) {
    final double handleWidth = 80;
    final double intensity = 1.0 + offset.abs() * 0.01;
    
    final Paint handlePaint = Paint()
      ..color = accentColor.withOpacity(0.8 * intensity)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    // 水平ハンドル
    canvas.drawLine(
      Offset(centerX - handleWidth/2, centerY),
      Offset(centerX + handleWidth/2, centerY),
      handlePaint,
    );
    
    // ハンドルのハイライト
    final Paint highlightPaint = Paint()
      ..color = TeslaStyleColors.surface
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(centerX - handleWidth/2, centerY - 1),
      Offset(centerX + handleWidth/2, centerY - 1),
      highlightPaint,
    );
  }

  void _drawDrawerDepthEffect(Canvas canvas, double x, double y, double w, double h, double offset) {
    final double depth = offset.abs() * 0.5;
    
    // 上面
    final Path topPath = Path()
      ..moveTo(x + 10, y)
      ..lineTo(x + w - 10, y)
      ..lineTo(x + w - 10 - depth * 0.3, y - depth * 0.8)
      ..lineTo(x + 10 - depth * 0.3, y - depth * 0.8)
      ..close();
    
    final Paint topPaint = Paint()
      ..color = TeslaStyleColors.fridgeDoor.withOpacity(0.7);
    
    canvas.drawPath(topPath, topPaint);
    
    // 側面
    final Path sidePath = Path()
      ..moveTo(x + w, y + 10)
      ..lineTo(x + w, y + h - 10)
      ..lineTo(x + w - depth * 0.3, y + h - 10 - depth * 0.8)
      ..lineTo(x + w - depth * 0.3, y + 10 - depth * 0.8)
      ..close();
    
    final Paint sidePaint = Paint()
      ..color = TeslaStyleColors.shadow.withOpacity(0.3);
    
    canvas.drawPath(sidePath, sidePaint);
  }

  void _drawEdgeHighlights(Canvas canvas, Size size) {
    final double centerX = size.width / 2;
    final double fridgeWidth = size.width * 0.8;
    final double fridgeHeight = size.height * 0.85;
    final double topY = size.height * 0.08;
    
    // 冷蔵庫本体の上部ハイライト
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          TeslaStyleColors.surface,
          Colors.transparent,
        ],
        stops: const [0.0, 0.3],
      ).createShader(Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight * 0.15),
        width: fridgeWidth * 0.9,
        height: fridgeHeight * 0.3,
      ));
    
    final RRect highlightRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(centerX, topY + fridgeHeight * 0.15),
        width: fridgeWidth * 0.9,
        height: fridgeHeight * 0.3,
      ),
      const Radius.circular(14),
    );
    
    canvas.drawRRect(highlightRect, highlightPaint);
  }

  @override
  bool shouldRepaint(covariant TeslaStyle3DFridgePainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
           oldDelegate.leftDoorAngle != leftDoorAngle ||
           oldDelegate.rightDoorAngle != rightDoorAngle ||
           oldDelegate.vegDrawerOffset != vegDrawerOffset ||
           oldDelegate.freezerOffset != freezerOffset;
  }
}