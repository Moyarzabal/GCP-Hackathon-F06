import 'package:flutter/material.dart';

/// 冷蔵庫UIの統一されたスタイルシステム
/// 正面ビューと上からの視点で同じ質感を提供
class UnifiedFridgeStyles {

  /// メタリック・ブラシドアルミニウム仕上げのグラデーション
  static LinearGradient get metallicBodyGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      const Color(0xFFFBFBFB), // 最明部（光の反射）
      const Color(0xFFF8F8F8), // ハイライト
      const Color(0xFFF2F2F2), // メイン表面
      const Color(0xFFEDEDED), // 中間トーン
      const Color(0xFFE8E8E8), // シャドウ開始
      const Color(0xFFE0E0E0), // 深いシャドウ
      const Color(0xFFF0F0F0), // エッジハイライト
    ],
    stops: const [0.0, 0.15, 0.35, 0.5, 0.65, 0.85, 1.0],
  );

  /// 高光沢反射効果のグラデーション（左上からの光）
  static LinearGradient get glossReflectionGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.centerRight,
    colors: [
      Colors.white.withOpacity(0.6),
      Colors.white.withOpacity(0.3),
      Colors.transparent,
      Colors.white.withOpacity(0.1),
    ],
    stops: const [0.0, 0.2, 0.6, 1.0],
  );

  /// ベベルエッジのグラデーション
  static LinearGradient get bevelEdgeGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.grey[100]!.withOpacity(0.8),
      Colors.grey[300]!.withOpacity(0.6),
      Colors.grey[400]!.withOpacity(0.4),
      Colors.grey[200]!.withOpacity(0.7),
    ],
    stops: const [0.0, 0.3, 0.7, 1.0],
  );

  /// 内部影効果（奥行き感）
  static RadialGradient get innerShadowGradient => RadialGradient(
    center: const Alignment(0.3, -0.3),
    radius: 1.2,
    colors: [
      Colors.transparent,
      Colors.grey[200]!.withOpacity(0.1),
      Colors.grey[300]!.withOpacity(0.2),
      Colors.grey[400]!.withOpacity(0.1),
    ],
    stops: const [0.0, 0.4, 0.8, 1.0],
  );

  /// 家電特有の表面テクスチャ（微細な凹凸感）
  static LinearGradient get surfaceTextureGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.white.withOpacity(0.05),
      Colors.transparent,
      Colors.grey[300]!.withOpacity(0.03),
      Colors.transparent,
      Colors.white.withOpacity(0.02),
    ],
    stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
  );

  /// 冷蔵庫内部の LED 照明効果
  static RadialGradient get interiorLightingGradient => RadialGradient(
    center: Alignment.topCenter,
    radius: 1.5,
    colors: [
      Colors.white.withOpacity(0.8),
      Colors.blue[50]!.withOpacity(0.4),
      Colors.blue[100]!.withOpacity(0.2),
      Colors.transparent,
    ],
    stops: const [0.0, 0.3, 0.6, 1.0],
  );

  /// 引き出し開放時の影効果
  static BoxShadow drawerOpenShadow(double pullDistance) => BoxShadow(
    color: Colors.black.withOpacity(0.3),
    blurRadius: 15.0 + (pullDistance * 0.3),
    spreadRadius: 5.0 + (pullDistance * 0.1),
    offset: Offset(0, 8.0 + (pullDistance * 0.15)),
  );

  /// プラスチック製仕切りのマテリアル
  static LinearGradient get plasticDividerGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Colors.white.withOpacity(0.9),
      Colors.grey[50]!.withOpacity(0.8),
      Colors.grey[100]!.withOpacity(0.6),
      Colors.grey[50]!.withOpacity(0.8),
    ],
    stops: const [0.0, 0.3, 0.7, 1.0],
  );

  /// 冷蔵庫本体の標準角丸
  static const double bodyBorderRadius = 12.0;

  /// 引き出しの標準角丸
  static const double drawerBorderRadius = 8.0;

  /// 内部コンポーネントの角丸
  static const double innerComponentRadius = 6.0;

  /// 標準的な境界線の色
  static Color get borderColor => Colors.grey[400]!.withOpacity(0.6);

  /// 内部境界線の色
  static Color get innerBorderColor => Colors.grey[300]!.withOpacity(0.5);

  /// ゴムガスケットの色
  static Color get gasketColor => Colors.grey[600]!.withOpacity(0.8);

  /// ハンドルのグラデーション
  static LinearGradient get handleGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.grey[200]!, // ハイライト
      Colors.grey[400]!, // メイン
      Colors.grey[600]!, // シャドウ
    ],
    stops: const [0.0, 0.5, 1.0],
  );

  /// ハンドル内部のグラデーション
  static LinearGradient get handleInnerGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.grey[300]!,
      Colors.grey[200]!,
    ],
  );

  /// 共通のブラシドアルミニウム効果を適用
  static void drawBrushedAluminumTexture(Canvas canvas, Rect rect, Paint paint) {
    // ブラシド仕上げ効果（縦方向の微細なライン）
    const int lineCount = 40;
    for (int i = 0; i < lineCount; i++) {
      final double x = rect.left + (rect.width / lineCount) * i;
      final Paint brushPaint = Paint()
        ..color = Colors.grey[200]!.withOpacity(0.15)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(x, rect.top + 5),
        Offset(x, rect.bottom - 5),
        brushPaint,
      );
    }
  }

  /// 共通のベベルエッジ効果
  static void drawBevelEdge(Canvas canvas, RRect rrect, Paint paint) {
    final Paint bevelStrokePaint = Paint()
      ..shader = bevelEdgeGradient.createShader(rrect.outerRect)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(rrect, bevelStrokePaint);
  }

  /// 共通の内部境界線
  static void drawInnerBorder(Canvas canvas, RRect rrect, Paint paint) {
    final Paint innerBorderPaint = Paint()
      ..color = innerBorderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final RRect innerBorder = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        rrect.left + 2,
        rrect.top + 2,
        rrect.width - 4,
        rrect.height - 4,
      ),
      Radius.circular(rrect.tlRadius.x - 2),
    );

    canvas.drawRRect(innerBorder, innerBorderPaint);
  }

  /// 背景グラデーション（キッチン環境）
  static RadialGradient get kitchenBackgroundGradient => RadialGradient(
    center: const Alignment(-0.3, -0.4),
    radius: 1.5,
    colors: [
      Colors.grey[700]!.withOpacity(0.6), // より明るい中心部
      Colors.grey[800]!.withOpacity(0.8),
      Colors.grey[850]!.withOpacity(0.9),
      Colors.black.withOpacity(0.95),
    ],
    stops: const [0.0, 0.3, 0.7, 1.0],
  );

  /// 環境光効果（キッチンの照明）
  static LinearGradient get ambientLightingGradient => LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Colors.amber[50]!.withOpacity(0.15),
      Colors.orange[50]!.withOpacity(0.1),
      Colors.transparent,
    ],
  );

  /// 床面からの反射光
  static LinearGradient get floorReflectionGradient => LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: [
      Colors.grey[300]!.withOpacity(0.1),
      Colors.grey[200]!.withOpacity(0.05),
      Colors.transparent,
    ],
  );
}