import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/material.dart';

/// 3D遠近法とホログラム風エフェクトを使った近未来的冷蔵庫ペインター
class Futuristic3DFridgePainter extends CustomPainter {
  final ColorScheme colorScheme;
  final double animationTime;
  final double leftDoorAngle;
  final double rightDoorAngle;
  final double vegDrawerOffset;
  final double freezerOffset;

  // 近未来カラーパレット
  static const Color neonBlue = Color(0xFF00E5FF);
  static const Color neonGreen = Color(0xFF64FFDA);
  static const Color darkMetal = Color(0xFF263238);
  static const Color hologramCyan = Color(0xFF18FFFF);
  static const Color glowWhite = Color(0xFFE3F2FD);

  Futuristic3DFridgePainter({
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
    
    // 3D遠近法の設定
    final double perspective = 0.002;
    final double vanishingY = height * 0.85;
    
    // 背景グラデーション（宇宙空間風）
    _drawSpaceBackground(canvas, size);
    
    // メイン冷蔵庫本体（3D）
    _draw3DFridgeBody(canvas, size, perspective, vanishingY);
    
    // 内部照明とグロー効果（扉の後ろに描画）
    _drawInteriorLighting(canvas, size, perspective, vanishingY);
    
    // 引き出し（3Dスライド）
    _draw3DDrawers(canvas, size, perspective, vanishingY);
    
    // 扉（3D回転）- 最後に描画して前面に配置
    _draw3DDoors(canvas, size, perspective, vanishingY);
    
    // ホログラム風UI要素
    _drawHologramUI(canvas, size);
    
    // パーティクルエフェクト
    _drawParticleEffects(canvas, size);
    
    // エッジライト
    _drawEdgeLights(canvas, size);
  }

  void _drawSpaceBackground(Canvas canvas, Size size) {
    final Rect bgRect = Offset.zero & size;
    final Paint bgPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.4),
        radius: 1.2,
        colors: [
          const Color(0xFF0D1B2A),
          const Color(0xFF1B263B),
          const Color(0xFF0A0E1A),
        ],
        stops: const [0.0, 0.6, 1.0],
      ).createShader(bgRect);
    canvas.drawRect(bgRect, bgPaint);
    
    // 星のパーティクル
    _drawStars(canvas, size);
  }

  void _drawStars(Canvas canvas, Size size) {
    final Paint starPaint = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 1.0;
    
    final random = math.Random(42);
    for (int i = 0; i < 50; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double twinkle = (math.sin(animationTime * 3 + i) + 1) / 2;
      starPaint.color = Colors.white.withOpacity(0.3 + twinkle * 0.4);
      canvas.drawCircle(Offset(x, y), 0.8, starPaint);
    }
  }

  void _draw3DFridgeBody(Canvas canvas, Size size, double perspective, double vanishingY) {
    final double width = size.width;
    final double height = size.height;
    final double fridgeWidth = width * 0.85;
    final double fridgeHeight = height * 0.9;
    final double centerX = width / 2;
    final double topY = height * 0.05;
    
    // 3D変形行列
    final Matrix4 transform = Matrix4.identity()
      ..setEntry(3, 2, perspective)
      ..rotateX(-0.1)
      ..rotateY(0.05);
    
    // 冷蔵庫本体の面を3D描画
    _draw3DFace(canvas, centerX - fridgeWidth/2, topY, fridgeWidth, fridgeHeight, transform, true);
    
    // サイドパネル（奥行き表現）
    _draw3DSidePanel(canvas, centerX - fridgeWidth/2, topY, fridgeHeight, transform);
    _draw3DSidePanel(canvas, centerX + fridgeWidth/2, topY, fridgeHeight, transform);
  }

  void _draw3DFace(Canvas canvas, double x, double y, double w, double h, Matrix4 transform, bool isFront) {
    final Path facePath = Path()
      ..addRRect(RRect.fromRectAndRadius(
        Rect.fromLTWH(x, y, w, h),
        const Radius.circular(20),
      ));
    
    // メタリック表面
    final Paint facePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkMetal.withOpacity(0.9),
          const Color(0xFF37474F),
          darkMetal.withOpacity(0.7),
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawPath(facePath, facePaint);
    
    // ハイライト反射
    final Paint highlightPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          glowWhite.withOpacity(0.3),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, y, w * 0.6, h * 0.3));
    
    canvas.drawPath(facePath, highlightPaint);
  }

  void _draw3DSidePanel(Canvas canvas, double x, double y, double h, Matrix4 transform) {
    final double depth = 60;
    final Path sidePath = Path()
      ..moveTo(x, y)
      ..lineTo(x + depth * 0.5, y - depth * 0.3)
      ..lineTo(x + depth * 0.5, y + h - depth * 0.3)
      ..lineTo(x, y + h)
      ..close();
    
    final Paint sidePaint = Paint()
      ..color = darkMetal.withOpacity(0.4);
    
    canvas.drawPath(sidePath, sidePaint);
  }

  void _drawInteriorLighting(Canvas canvas, Size size, double perspective, double vanishingY) {
    final double centerX = size.width / 2;
    final double topY = size.height * 0.22;
    final double interiorWidth = size.width * 0.75;
    final double interiorHeight = size.height * 0.5;
    
    // 内部の青白い光
    final Rect interiorRect = Rect.fromCenter(
      center: Offset(centerX, topY + interiorHeight / 2),
      width: interiorWidth,
      height: interiorHeight,
    );
    
    final Paint interiorGlow = Paint()
      ..shader = RadialGradient(
        center: Alignment.center,
        radius: 0.8,
        colors: [
          neonBlue.withOpacity(0.2),
          hologramCyan.withOpacity(0.1),
          Colors.transparent,
        ],
      ).createShader(interiorRect);
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(interiorRect, const Radius.circular(15)),
      interiorGlow,
    );
    
    // 棚のライン（発光）
    for (int i = 0; i < 3; i++) {
      final double shelfY = topY + (i + 1) * (interiorHeight / 4);
      _drawGlowLine(canvas, centerX - interiorWidth/2 + 20, shelfY, 
                   centerX + interiorWidth/2 - 20, shelfY, neonBlue, 2.0);
    }
  }

  void _drawGlowLine(Canvas canvas, double x1, double y1, double x2, double y2, Color color, double width) {
    final Paint glowPaint = Paint()
      ..color = color.withOpacity(0.8)
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;
    
    // 外側のグロー
    final Paint outerGlow = Paint()
      ..color = color.withOpacity(0.3)
      ..strokeWidth = width * 3
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), outerGlow);
    canvas.drawLine(Offset(x1, y1), Offset(x2, y2), glowPaint);
  }

  void _draw3DDoors(Canvas canvas, Size size, double perspective, double vanishingY) {
    final double centerX = size.width / 2;
    final double doorWidth = size.width * 0.425; // 扉を大きくして棚を覆うように
    final double doorHeight = size.height * 0.5; // 扉の高さを拡大して棚全体を覆う
    final double topY = size.height * 0.05;
    
    // 左扉
    _draw3DDoor(canvas, centerX - doorWidth, topY, doorWidth, doorHeight, leftDoorAngle, true);
    
    // 右扉  
    _draw3DDoor(canvas, centerX, topY, doorWidth, doorHeight, rightDoorAngle, false);
  }

  void _draw3DDoor(Canvas canvas, double x, double y, double w, double h, double angle, bool isLeft) {
    canvas.save();
    
    // 回転の中心点（左扉は左端、右扉は右端を軸に）
    final double pivotX = isLeft ? x : x + w;
    final double pivotY = y + h / 2;
    
    canvas.translate(pivotX, pivotY);
    canvas.transform((Matrix4.identity()
          ..setEntry(3, 2, 0.001)
          ..rotateY(angle))
        .storage);
    canvas.translate(-pivotX, -pivotY);
    
    // 扉面（奥行きと立体感を強調）
    final RRect doorRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(15),
    );
    
    // メタリック素材と半透明ガラスの組み合わせ
    final Paint doorBasePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          darkMetal.withOpacity(0.85),
          const Color(0xFF37474F).withOpacity(0.8),
          darkMetal.withOpacity(0.75),
        ],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawRRect(doorRect, doorBasePaint);
    
    // ガラス風オーバーレイ
    final Paint glassPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          hologramCyan.withOpacity(0.2),
          neonBlue.withOpacity(0.15),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawRRect(doorRect, glassPaint);
    
    // エッジ発光
    final Paint edgePaint = Paint()
      ..color = neonBlue.withOpacity(0.8 + angle.abs() * 0.2)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    canvas.drawRRect(doorRect, edgePaint);
    
    // 扉の厚み（3D奥行き表現）
    if (angle.abs() > 0.1) {
      _drawDoorDepth(canvas, x, y, w, h, angle, isLeft);
    }
    
    // ハンドル（位置調整）
    _drawFuturisticHandle(canvas, isLeft ? x + w - 20 : x + 20, y + h/2, isLeft);
    
    canvas.restore();
  }

  void _drawDoorDepth(Canvas canvas, double x, double y, double w, double h, double angle, bool isLeft) {
    // 扉の厚み（手前に開く扉の側面）
    final double thickness = 15;
    final double offsetX = math.sin(angle) * thickness;
    final double offsetZ = math.cos(angle) * thickness - thickness;
    
    final Path depthPath = Path();
    if (isLeft) {
      // 左扉の側面
      depthPath.moveTo(x, y);
      depthPath.lineTo(x + offsetX, y + offsetZ);
      depthPath.lineTo(x + offsetX, y + h + offsetZ);
      depthPath.lineTo(x, y + h);
      depthPath.close();
    } else {
      // 右扉の側面
      depthPath.moveTo(x + w, y);
      depthPath.lineTo(x + w + offsetX, y + offsetZ);
      depthPath.lineTo(x + w + offsetX, y + h + offsetZ);
      depthPath.lineTo(x + w, y + h);
      depthPath.close();
    }
    
    final Paint depthPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          darkMetal.withOpacity(0.9),
          const Color(0xFF37474F).withOpacity(0.7),
        ],
      ).createShader(depthPath.getBounds());
    
    canvas.drawPath(depthPath, depthPaint);
  }

  void _drawFuturisticHandle(Canvas canvas, double x, double y, bool isLeft) {
    final Paint handlePaint = Paint()
      ..color = hologramCyan
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round;
    
    final double handleLength = 30;
    canvas.drawLine(
      Offset(x, y - handleLength/2),
      Offset(x, y + handleLength/2),
      handlePaint,
    );
    
    // グロー効果
    final Paint glowPaint = Paint()
      ..color = hologramCyan.withOpacity(0.5)
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(x, y - handleLength/2),
      Offset(x, y + handleLength/2),
      glowPaint,
    );
  }

  void _draw3DDrawers(Canvas canvas, Size size, double perspective, double vanishingY) {
    final double centerX = size.width / 2;
    final double drawerWidth = size.width * 0.75;
    final double drawerHeight = size.height * 0.1;
    
    // 野菜室
    final double vegY = size.height * 0.68 + vegDrawerOffset;
    _draw3DDrawer(canvas, centerX - drawerWidth/2, vegY, drawerWidth, drawerHeight, vegDrawerOffset, neonGreen);
    
    // 冷凍庫
    final double freezerY = size.height * 0.85 + freezerOffset;
    _draw3DDrawer(canvas, centerX - drawerWidth/2, freezerY, drawerWidth, drawerHeight, freezerOffset, neonBlue);
  }

  void _draw3DDrawer(Canvas canvas, double x, double y, double w, double h, double offset, Color accentColor) {
    // 引き出し面
    final RRect drawerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(x, y, w, h),
      const Radius.circular(12),
    );
    
    final Paint drawerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          darkMetal.withOpacity(0.8),
          accentColor.withOpacity(0.2),
          darkMetal.withOpacity(0.6),
        ],
      ).createShader(Rect.fromLTWH(x, y, w, h));
    
    canvas.drawRRect(drawerRect, drawerPaint);
    
    // 取っ手（ホログラム風）
    final double handleY = y + h/2;
    final Paint handlePaint = Paint()
      ..color = accentColor.withOpacity(0.8 + offset.abs() * 0.01)
      ..strokeWidth = 4.0
      ..strokeCap = StrokeCap.round;
    
    canvas.drawLine(
      Offset(x + w/2 - 25, handleY),
      Offset(x + w/2 + 25, handleY),
      handlePaint,
    );
    
    // 奥行きエフェクト
    if (offset != 0) {
      _drawDrawerDepth(canvas, x, y, w, h, offset, accentColor);
    }
  }

  void _drawDrawerDepth(Canvas canvas, double x, double y, double w, double h, double offset, Color color) {
    final Path depthPath = Path()
      ..moveTo(x, y)
      ..lineTo(x - offset * 0.3, y - offset * 0.2)
      ..lineTo(x + w - offset * 0.3, y - offset * 0.2)
      ..lineTo(x + w, y)
      ..close();
    
    final Paint depthPaint = Paint()
      ..color = color.withOpacity(0.3);
    
    canvas.drawPath(depthPath, depthPaint);
  }

  void _drawHologramUI(Canvas canvas, Size size) {
    final double time = animationTime;
    
    // スキャンライン
    final double scanY = (size.height * (time % 3.0) / 3.0);
    final Paint scanPaint = Paint()
      ..color = hologramCyan.withOpacity(0.6)
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(0, scanY),
      Offset(size.width, scanY),
      scanPaint,
    );
    
    // 浮遊データ表示
    _drawFloatingDataElements(canvas, size, time);
  }

  void _drawFloatingDataElements(Canvas canvas, Size size, double time) {
    final Paint dataPaint = Paint()
      ..color = neonGreen.withOpacity(0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    // 浮遊する六角形
    for (int i = 0; i < 3; i++) {
      final double x = size.width * 0.1 + i * size.width * 0.35;
      final double y = size.height * 0.3 + math.sin(time + i) * 20;
      final double radius = 15;
      
      _drawHexagon(canvas, x, y, radius, dataPaint);
    }
  }

  void _drawHexagon(Canvas canvas, double centerX, double centerY, double radius, Paint paint) {
    final Path hexPath = Path();
    for (int i = 0; i < 6; i++) {
      final double angle = (i * math.pi) / 3;
      final double x = centerX + radius * math.cos(angle);
      final double y = centerY + radius * math.sin(angle);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();
    canvas.drawPath(hexPath, paint);
  }

  void _drawParticleEffects(Canvas canvas, Size size) {
    final Paint particlePaint = Paint()
      ..color = hologramCyan.withOpacity(0.6);
    
    final random = math.Random(42);
    for (int i = 0; i < 20; i++) {
      final double x = random.nextDouble() * size.width;
      final double y = random.nextDouble() * size.height;
      final double phase = animationTime * 2 + i;
      final double opacity = (math.sin(phase) + 1) / 2;
      
      particlePaint.color = hologramCyan.withOpacity(opacity * 0.4);
      canvas.drawCircle(Offset(x, y), 1.5, particlePaint);
    }
  }

  void _drawEdgeLights(Canvas canvas, Size size) {
    final Paint edgePaint = Paint()
      ..color = neonBlue.withOpacity(0.8)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
    
    // 冷蔵庫外周のエッジライト
    final RRect outerEdge = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.075, 
        size.height * 0.05,
        size.width * 0.85, 
        size.height * 0.9,
      ),
      const Radius.circular(20),
    );
    
    canvas.drawRRect(outerEdge, edgePaint);
  }

  @override
  bool shouldRepaint(covariant Futuristic3DFridgePainter oldDelegate) {
    return oldDelegate.animationTime != animationTime ||
           oldDelegate.leftDoorAngle != leftDoorAngle ||
           oldDelegate.rightDoorAngle != rightDoorAngle ||
           oldDelegate.vegDrawerOffset != vegDrawerOffset ||
           oldDelegate.freezerOffset != freezerOffset;
  }
}
