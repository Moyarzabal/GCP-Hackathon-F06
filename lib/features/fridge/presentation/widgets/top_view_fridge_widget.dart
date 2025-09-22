import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../shared/models/product.dart';
import '../providers/drawer_state_provider.dart';
import '../animations/drawer_animation_config.dart';
import '../styles/unified_fridge_styles.dart';

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
  Widget build(BuildContext context) {
    final drawerState = ref.watch(drawerStateProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 参考画像のような明るい背景
            Container(
              width: constraints.maxWidth,
              height: constraints.maxHeight,
              decoration: const BoxDecoration(
                // 参考画像のような非常に明るい、ほぼ白い背景
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFFFCFCFC),
                    Color(0xFFF8F8F8),
                    Color(0xFFF5F5F5),
                  ],
                ),
              ),
            ),
            // 冷蔵庫本体（上から見た形）を画面中央上部に配置
            Positioned.fill(
              child: Align(
                alignment: Alignment.center,
                child: _buildTopViewFridge(constraints, drawerState),
              ),
            ),
            // 戻るボタン
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.95),
                  borderRadius: BorderRadius.circular(25),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: IconButton(
                  onPressed: () {
                    ref.read(drawerStateProvider.notifier).backToFrontView();
                  },
                  icon: const Icon(Icons.arrow_back, color: Colors.black87),
                  iconSize: 24,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildTopViewFridge(BoxConstraints constraints, DrawerState drawerState) {
    // 冷蔵庫をより現実的な奥行きで表示
    final maxWidth = constraints.maxWidth * 0.9;
    final maxHeight = constraints.maxHeight * 0.95;
    final fridgeWidth = math.min(maxWidth, maxHeight * 0.7);  // 奥行きを優先
    final fridgeHeight = fridgeWidth * 1.3; // 幅に対してより深い奥行き（現実的な比率）

    return Container(
      width: fridgeWidth,
      height: fridgeHeight,
      child: GestureDetector(
        onTap: () {
          // 引き出しが開いている場合のみタップ処理
          if (drawerState.openDrawer != null) {
            HapticFeedback.mediumImpact();
            // 直接リスト画面に遷移
            widget.onSectionTap(
              drawerState.openDrawer!.compartment,
              drawerState.openDrawer!.level
            );
          }
        },
        child: CustomPaint(
          painter: EnhancedTopViewFridgePainter(
            openDrawer: drawerState.openDrawer,
          ),
          child: Container(
            // 全体をタッチ可能にするために透明なコンテナを配置
            color: Colors.transparent,
          ),
        ),
      ),
    );
  }



}

/// 完全に90度真上からの視点での冷蔵庫ペインター（参考画像準拠）
class EnhancedTopViewFridgePainter extends CustomPainter {
  final OpenDrawerInfo? openDrawer;

  EnhancedTopViewFridgePainter({
    this.openDrawer,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 引き出しのみ表示
    if (openDrawer != null) {
      _drawOpenDrawerTopDown(canvas, size.width, size.height, openDrawer!);
    }
  }


  /// 上から見た引き出しが手前に引き出された状態
  void _drawOpenDrawerTopDown(Canvas canvas, double width, double height, OpenDrawerInfo drawerInfo) {
    final isVegetableDrawer = drawerInfo.compartment == FridgeCompartment.vegetableDrawer;

    // 引き出しを画面幅を大きく使って横長に表示
    final drawerWidth = width * 0.85;  // 画面幅の85%を使用
    final drawerHeight = height * 0.45; // 高さをより広く
    final drawerLeft = (width - drawerWidth) / 2;
    final drawerTop = height * 0.275;   // 画面中央に配置

    // 引き出し本体（横長の長方形）
    final RRect pulledDrawerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(drawerLeft, drawerTop, drawerWidth, drawerHeight),
      const Radius.circular(8),
    );

    // 引き出し本体のシンプルなグラデーション
    final Paint drawerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white,                    // 左上ハイライト
          const Color(0xFFF0F0F0),        // 明るい面
          const Color(0xFFE0E0E0),        // 中間色
          const Color(0xFFD0D0D0),        // 影
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(pulledDrawerRect.outerRect);

    canvas.drawRRect(pulledDrawerRect, drawerPaint);

    // 引き出しの立体感を表現する枠線とハイライト
    // 上端のハイライト（光が当たる部分）
    final Paint topHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(pulledDrawerRect.left, pulledDrawerRect.top),
      Offset(pulledDrawerRect.right, pulledDrawerRect.top),
      topHighlightPaint,
    );

    // 左端のハイライト
    canvas.drawLine(
      Offset(pulledDrawerRect.left, pulledDrawerRect.top),
      Offset(pulledDrawerRect.left, pulledDrawerRect.bottom),
      topHighlightPaint,
    );

    // 外側境界線（全体の枠）
    final Paint borderPaint = Paint()
      ..color = Colors.grey[500]!.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawRRect(pulledDrawerRect, borderPaint);

    // 引き出し内部パネル（食材を配置する広いスペース）
    final RRect innerPanelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pulledDrawerRect.left + 16,
        pulledDrawerRect.top + 16,
        pulledDrawerRect.width - 32,
        pulledDrawerRect.height - 32,
      ),
      const Radius.circular(4),
    );

    // 引き出し内部の奥行きを表現する影のグラデーション
    final Paint innerDepthPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[200]!,           // 手前側（明るい）
          Colors.grey[100]!,           // 中間
          Colors.white,                // 底部（最も明るい）
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(innerPanelRect.outerRect);

    canvas.drawRRect(innerPanelRect, innerDepthPaint);

    // 引き出しの壁面に影を追加（奥行き感）
    final Paint wallShadowPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.6)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    // 左壁の影
    canvas.drawLine(
      Offset(innerPanelRect.left, innerPanelRect.top),
      Offset(innerPanelRect.left, innerPanelRect.bottom),
      wallShadowPaint,
    );

    // 右壁の影
    canvas.drawLine(
      Offset(innerPanelRect.right, innerPanelRect.top),
      Offset(innerPanelRect.right, innerPanelRect.bottom),
      wallShadowPaint,
    );

    // 奥壁の影
    canvas.drawLine(
      Offset(innerPanelRect.left, innerPanelRect.bottom),
      Offset(innerPanelRect.right, innerPanelRect.bottom),
      wallShadowPaint,
    );

    // 内部パネル境界線
    final Paint innerPanelBorderPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    canvas.drawRRect(innerPanelRect, innerPanelBorderPaint);

    // 引き出しのゴムガスケット
    final RRect gasketOuterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        pulledDrawerRect.left + 2,
        pulledDrawerRect.top + 2,
        pulledDrawerRect.width - 4,
        pulledDrawerRect.height - 4,
      ),
      const Radius.circular(5),
    );

    final Paint gasketOuterPaint = Paint()
      ..color = Colors.grey[600]!.withOpacity(0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    canvas.drawRRect(gasketOuterRect, gasketOuterPaint);

    final RRect gasketInnerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        gasketOuterRect.left + 1,
        gasketOuterRect.top + 1,
        gasketOuterRect.width - 2,
        gasketOuterRect.height - 2,
      ),
      const Radius.circular(4),
    );

    final Paint gasketInnerPaint = Paint()
      ..color = Colors.grey[500]!.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(gasketInnerRect, gasketInnerPaint);

    // 上から見た引き出しのハンドル（手前端に配置）
    final Rect handleRect = Rect.fromLTWH(
      pulledDrawerRect.left + (pulledDrawerRect.width / 2) - 50,
      pulledDrawerRect.top + 8,  // 引き出しの手前端
      100, // ハンドル幅
      20,  // ハンドル高さ
    );

    final Paint handlePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[200]!, // ハイライト
          Colors.grey[400]!, // メイン
          Colors.grey[600]!, // シャドウ
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(handleRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(handleRect, const Radius.circular(6)),
      handlePaint,
    );

    // ハンドル内部
    final Rect handleInnerRect = Rect.fromLTWH(
      handleRect.left + 1,
      handleRect.top + 1,
      handleRect.width - 2,
      handleRect.height - 2,
    );

    final Paint handleInnerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          Colors.grey[300]!,
          Colors.grey[200]!,
        ],
      ).createShader(handleInnerRect);

    canvas.drawRRect(
      RRect.fromRectAndRadius(handleInnerRect, const Radius.circular(5)),
      handleInnerPaint,
    );

    // 空の引き出し内部（食材配置エリア）
    _drawEmptyDrawerInterior(canvas, innerPanelRect.outerRect);
  }

  /// 空の引き出し内部の描画
  void _drawEmptyDrawerInterior(Canvas canvas, Rect innerRect) {
    // 正面UIと統一したプラスチック製仕切りのマテリアル
    final Paint dividerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.9),
          Colors.grey[50]!.withOpacity(0.8),
          Colors.grey[100]!.withOpacity(0.6),
          Colors.grey[50]!.withOpacity(0.8),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(innerRect);

    // 清潔で空の引き出し内部（白い背景）
    final Paint cleanInteriorPaint = Paint()
      ..color = Colors.white;

    canvas.drawRect(innerRect, cleanInteriorPaint);

    // 微細な仕切り線（正面UIと統一したスタイル）
    final Paint subtleDividerPaint = Paint()
      ..color = Colors.grey[200]!.withOpacity(0.4)
      ..strokeWidth = 0.5;

    // 横方向の区切り線（整理用）
    final midY = innerRect.top + innerRect.height * 0.5;
    canvas.drawLine(
      Offset(innerRect.left + 10, midY),
      Offset(innerRect.right - 10, midY),
      subtleDividerPaint,
    );

    // 縦方向の区切り線
    final midX = innerRect.left + innerRect.width * 0.5;
    canvas.drawLine(
      Offset(midX, innerRect.top + 10),
      Offset(midX, innerRect.bottom - 10),
      subtleDividerPaint,
    );

    // 正面UIと同じ内部照明効果
    final Paint lightingPaint = Paint()
      ..shader = RadialGradient(
        center: Alignment.topCenter,
        radius: 1.5,
        colors: [
          Colors.white.withOpacity(0.8),
          Colors.blue[50]!.withOpacity(0.4),
          Colors.blue[100]!.withOpacity(0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 0.6, 1.0],
      ).createShader(innerRect);

    canvas.drawRect(innerRect, lightingPaint);

    // 清潔感を演出する微細な反射
    final Paint reflectionPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.3),
          Colors.white.withOpacity(0.1),
          Colors.transparent,
        ],
        stops: const [0.0, 0.3, 1.0],
      ).createShader(innerRect);

    canvas.drawRect(innerRect, reflectionPaint);
  }


  @override
  bool shouldRepaint(covariant EnhancedTopViewFridgePainter oldDelegate) {
    return oldDelegate.openDrawer != openDrawer;
  }
}