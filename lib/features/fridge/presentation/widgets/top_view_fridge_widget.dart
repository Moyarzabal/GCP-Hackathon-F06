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

class _TopViewFridgeWidgetState extends ConsumerState<TopViewFridgeWidget>
    with TickerProviderStateMixin {

  // ホバー状態の管理
  OpenDrawerInfo? _hoveredDrawer;

  // タッチフィードバック用のアニメーションコントローラー
  late AnimationController _touchFeedbackController;
  late Animation<double> _touchScaleAnimation;
  late Animation<double> _touchOpacityAnimation;

  @override
  void initState() {
    super.initState();

    // タッチフィードバックアニメーション
    _touchFeedbackController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _touchScaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _touchFeedbackController,
      curve: Curves.easeInOut,
    ));

    _touchOpacityAnimation = Tween<double>(
      begin: 1.0,
      end: 0.8,
    ).animate(CurvedAnimation(
      parent: _touchFeedbackController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _touchFeedbackController.dispose();
    super.dispose();
  }

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
            // 冷蔵庫本体（上から見た形）
            Center(
              child: _buildTopViewFridge(constraints, drawerState),
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
    // 現実的な冷蔵庫の比率（幅：奥行き = 3:2）
    final maxSize = math.min(constraints.maxWidth * 0.8, constraints.maxHeight * 0.8);
    final fridgeWidth = maxSize;
    final fridgeHeight = maxSize * 0.67; // 3:2の比率

    return Container(
      width: fridgeWidth,
      height: fridgeHeight,
      child: CustomPaint(
        painter: EnhancedTopViewFridgePainter(
          openDrawer: drawerState.openDrawer,
        ),
        child: AnimatedBuilder(
          animation: Listenable.merge([_touchScaleAnimation, _touchOpacityAnimation]),
          builder: (context, child) {
            return Stack(
              children: [
                // 引き出し内部のタッチ領域
                if (drawerState.openDrawer != null)
                  _buildEnhancedDrawerTouchArea(fridgeWidth, fridgeHeight, drawerState.openDrawer!),
              ],
            );
          },
        ),
      ),
    );
  }

  /// 下方向に引き出された引き出しのタッチ領域
  Widget _buildEnhancedDrawerTouchArea(double fridgeWidth, double fridgeHeight, OpenDrawerInfo drawerInfo) {
    final isVegetableDrawer = drawerInfo.compartment == FridgeCompartment.vegetableDrawer;

    // 画面全体のサイズ
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    // 冷蔵庫本体のサイズと位置
    final actualFridgeWidth = screenWidth * 0.8;
    final actualFridgeLeft = screenWidth * 0.1;
    final actualFridgeHeight = screenHeight * 0.75;
    final actualFridgeTop = screenHeight * 0.02;

    // 引き出しエリアの位置（冷蔵庫の下部から下方向に延長）
    final drawerAreaTop = actualFridgeTop + actualFridgeHeight * 0.7;
    final drawerAreaHeight = actualFridgeHeight * 0.3;

    // 下方向に引き出された引き出しの位置
    final drawerTop = isVegetableDrawer
        ? drawerAreaTop + drawerAreaHeight * 0.3  // 野菜室
        : drawerAreaTop + drawerAreaHeight * 0.8; // 冷凍庫
    final drawerHeight = drawerAreaHeight * 1.1; // 下に延びた引き出しの高さ
    final isHovered = _hoveredDrawer == drawerInfo;

    return Positioned(
      left: actualFridgeLeft,
      top: drawerTop,
      width: actualFridgeWidth,
      height: drawerHeight,
      child: MouseRegion(
        onEnter: (_) => _handleHoverEnter(drawerInfo),
        onExit: (_) => _handleHoverExit(),
        child: AnimatedScale(
          scale: isHovered ? 1.02 : _touchScaleAnimation.value,
          duration: const Duration(milliseconds: 200),
          child: GestureDetector(
            onTapDown: (_) => _handleTapDown(),
            onTapUp: (_) => _handleTapUp(drawerInfo),
            onTapCancel: () => _handleTapCancel(),
            child: AnimatedOpacity(
              opacity: _touchOpacityAnimation.value,
              duration: const Duration(milliseconds: 150),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeInOutCubic,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: isHovered ? [
                      Colors.blue.withOpacity(0.2),
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.25),
                    ] : [
                      Colors.blue.withOpacity(0.1),
                      Colors.blue.withOpacity(0.05),
                      Colors.blue.withOpacity(0.15),
                    ],
                  ),
                  border: Border.all(
                    color: isHovered
                      ? Colors.blue.withOpacity(0.6)
                      : Colors.blue.withOpacity(0.4),
                    width: isHovered ? 3 : 2,
                  ),
                  borderRadius: BorderRadius.circular(UnifiedFridgeStyles.drawerBorderRadius),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.blue.withOpacity(isHovered ? 0.3 : 0.2),
                      blurRadius: isHovered ? 12 : 8,
                      spreadRadius: isHovered ? 3 : 2,
                      offset: isHovered ? const Offset(0, 6) : const Offset(0, 4),
                    ),
                  ],
                ),
                child: Center(
                  child: _buildInteractiveLabel(isVegetableDrawer, isHovered),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// インタラクティブなラベル
  Widget _buildInteractiveLabel(bool isVegetableDrawer, bool isHovered) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: EdgeInsets.symmetric(
        horizontal: isHovered ? 24 : 20,
        vertical: isHovered ? 14 : 12,
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isHovered ? [
            Colors.white.withOpacity(0.95),
            Colors.blue[50]!.withOpacity(0.9),
          ] : [
            Colors.white.withOpacity(0.9),
            Colors.blue[50]!.withOpacity(0.8),
          ],
        ),
        borderRadius: BorderRadius.circular(isHovered ? 28 : 25),
        border: Border.all(
          color: isHovered
            ? Colors.blue.withOpacity(0.4)
            : Colors.blue.withOpacity(0.3),
          width: isHovered ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isHovered ? 0.2 : 0.15),
            blurRadius: isHovered ? 6 : 4,
            offset: isHovered ? const Offset(0, 3) : const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isVegetableDrawer ? Icons.grass : Icons.ac_unit,
            color: Colors.blue[700],
            size: isHovered ? 18 : 16,
          ),
          const SizedBox(width: 8),
          AnimatedDefaultTextStyle(
            duration: const Duration(milliseconds: 300),
            style: TextStyle(
              color: Colors.blue[800],
              fontWeight: FontWeight.w600,
              fontSize: isHovered ? 15 : 14,
              shadows: [
                Shadow(
                  color: Colors.white.withOpacity(0.5),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            child: Text('タップして${isVegetableDrawer ? '野菜室' : '冷凍庫'}を見る'),
          ),
        ],
      ),
    );
  }

  /// ホバー開始処理
  void _handleHoverEnter(OpenDrawerInfo drawerInfo) {
    setState(() {
      _hoveredDrawer = drawerInfo;
    });
  }

  /// ホバー終了処理
  void _handleHoverExit() {
    setState(() {
      _hoveredDrawer = null;
    });
  }

  /// タップ開始処理
  void _handleTapDown() {
    HapticFeedback.lightImpact();
    _touchFeedbackController.forward();
  }

  /// タップ完了処理
  void _handleTapUp(OpenDrawerInfo drawerInfo) {
    _touchFeedbackController.reverse();

    // より強い触覚フィードバック
    HapticFeedback.mediumImpact();

    // タップ処理の実行
    ref.read(drawerStateProvider.notifier).tapDrawerInner();
    widget.onSectionTap(drawerInfo.compartment, drawerInfo.level);
  }

  /// タップキャンセル処理
  void _handleTapCancel() {
    _touchFeedbackController.reverse();
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
    final width = size.width;
    final height = size.height;

    // 参考画像のような真上からの冷蔵庫本体
    _drawTopDownFridgeBody(canvas, width, height);

    // 開いた引き出しを真上から見た状態
    if (openDrawer != null) {
      _drawOpenDrawerTopDown(canvas, width, height, openDrawer!);
    }
  }

  /// 正面UIと完全統一した上視点の冷蔵庫本体
  void _drawTopDownFridgeBody(Canvas canvas, double width, double height) {
    // 正面UIと完全に同じサイズ・比率・配置
    final fridgeRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        width * 0.1,      // 正面と同じ：左右の余白10%
        height * 0.02,    // 正面と同じ：上部余白2%
        width * 0.8,      // 正面と同じ：横幅80%
        height * 0.75,    // 正面と同じ：高さ75%
      ),
      const Radius.circular(12), // 正面と同じ：角丸12px
    );

    // 正面UIと完全に同じ7段階メタリックグラデーション
    final Paint bodyPaint = Paint()
      ..shader = LinearGradient(
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
      ).createShader(fridgeRect.outerRect);

    canvas.drawRRect(fridgeRect, bodyPaint);

    // 正面UIと同じ家電特有の表面テクスチャ
    final Paint texturePaint = Paint()
      ..shader = LinearGradient(
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
      ).createShader(fridgeRect.outerRect);

    canvas.drawRRect(fridgeRect, texturePaint);

    // 正面UIと同じブラシドアルミニウム効果（上視点では横方向のライン）
    for (int i = 0; i < 40; i++) {
      final double y = fridgeRect.top + (fridgeRect.height / 40) * i;
      final Paint brushPaint = Paint()
        ..color = Colors.grey[200]!.withOpacity(0.15)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;

      canvas.drawLine(
        Offset(fridgeRect.left + 5, y),
        Offset(fridgeRect.right - 5, y),
        brushPaint,
      );
    }

    // 正面UIと同じベベルエッジ効果
    final Paint bevelPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.grey[100]!.withOpacity(0.8),
          Colors.grey[300]!.withOpacity(0.6),
          Colors.grey[400]!.withOpacity(0.4),
          Colors.grey[200]!.withOpacity(0.7),
        ],
        stops: const [0.0, 0.3, 0.7, 1.0],
      ).createShader(fridgeRect.outerRect);

    final Paint bevelStrokePaint = Paint()
      ..shader = bevelPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    canvas.drawRRect(fridgeRect, bevelStrokePaint);

    // 正面UIと同じ内側ボーダー
    final Paint innerBorderPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final RRect innerBorder = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        fridgeRect.left + 2,
        fridgeRect.top + 2,
        fridgeRect.width - 4,
        fridgeRect.height - 4,
      ),
      const Radius.circular(10),
    );

    canvas.drawRRect(innerBorder, innerBorderPaint);

    // 上視点でのセクション分割線（扉の境界を表現）
    _drawTopViewSectionDividers(canvas, fridgeRect);
  }

  /// 上視点での扉・引き出しセクション分割線
  void _drawTopViewSectionDividers(Canvas canvas, RRect fridgeRect) {
    final Paint dividerPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.7)
      ..strokeWidth = 1.5;

    // 左右扉の中央分割線（縦線）
    canvas.drawLine(
      Offset(fridgeRect.center.dx, fridgeRect.top + 5),
      Offset(fridgeRect.center.dx, fridgeRect.top + fridgeRect.height * 0.7 - 5),
      dividerPaint,
    );

    // 扉と引き出しエリアの境界線（横線）
    canvas.drawLine(
      Offset(fridgeRect.left + 5, fridgeRect.top + fridgeRect.height * 0.7),
      Offset(fridgeRect.right - 5, fridgeRect.top + fridgeRect.height * 0.7),
      dividerPaint,
    );

    // 引き出しセクション間の境界線
    final drawerBoundaryY = fridgeRect.top + fridgeRect.height * 0.85;
    canvas.drawLine(
      Offset(fridgeRect.left + 5, drawerBoundaryY),
      Offset(fridgeRect.right - 5, drawerBoundaryY),
      dividerPaint,
    );
  }

  /// 下方向に引き出された状態の引き出しを上から見た表現
  void _drawOpenDrawerTopDown(Canvas canvas, double width, double height, OpenDrawerInfo drawerInfo) {
    final isVegetableDrawer = drawerInfo.compartment == FridgeCompartment.vegetableDrawer;

    // 冷蔵庫本体のサイズと位置
    final fridgeWidth = width * 0.8;
    final fridgeLeft = width * 0.1;
    final fridgeHeight = height * 0.75;
    final fridgeTop = height * 0.02;

    // 引き出しエリアの位置計算
    final drawerAreaTop = fridgeTop + fridgeHeight * 0.7;
    final drawerAreaHeight = fridgeHeight * 0.3;

    // 野菜室か冷凍庫かで位置を決定
    final drawerSlotTop = isVegetableDrawer
        ? drawerAreaTop
        : drawerAreaTop + drawerAreaHeight * 0.5;
    final drawerSlotHeight = drawerAreaHeight * 0.5;

    // 引き出しが下方向に引き出された状態を表現
    // 冷蔵庫本体から下に延びた引き出し
    final RRect drawerRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        fridgeLeft + (fridgeWidth * 0.1),   // 冷蔵庫の内側マージン
        drawerSlotTop + drawerSlotHeight * 0.3,  // 下方向に引き出された位置
        fridgeWidth * 0.8,                  // 引き出しの幅
        drawerSlotHeight * 2.2,             // 下に延びた引き出しの長さ（より長く）
      ),
      const Radius.circular(8),
    );

    // 下方向に引き出された引き出しの立体感を表現する影
    // 冷蔵庫本体の影（引き出しが抜けた部分）
    final Paint fridgeSlotShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.4)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0);

    final RRect fridgeSlotRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        fridgeLeft + (fridgeWidth * 0.1),
        drawerSlotTop,
        fridgeWidth * 0.8,
        drawerSlotHeight,
      ),
      const Radius.circular(8),
    );

    canvas.drawRRect(fridgeSlotRect, fridgeSlotShadowPaint);

    // 引き出し本体の影（下に落ちる影）
    final Paint drawerShadowPaint = Paint()
      ..color = Colors.black.withOpacity(0.25)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 12.0);

    canvas.drawRRect(
      drawerRect.shift(const Offset(3, 5)),
      drawerShadowPaint,
    );

    // 下方向に引き出された引き出しの立体感を表現するグラデーション
    final Paint drawerPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFFAFAFA),   // 上部（明るい）
          const Color(0xFFF0F0F0),   // 中間上
          const Color(0xFFE5E5E5),   // 中央
          const Color(0xFFD8D8D8),   // 中間下
          const Color(0xFFCCCCCC),   // 下部（より濃い影）
        ],
        stops: const [0.0, 0.25, 0.5, 0.75, 1.0],
      ).createShader(drawerRect.outerRect);

    canvas.drawRRect(drawerRect, drawerPaint);

    // 引き出しの立体感を表現する側面ハイライト
    final Paint leftHighlightPaint = Paint()
      ..color = Colors.white.withOpacity(0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    // 左側のハイライト
    canvas.drawLine(
      Offset(drawerRect.left, drawerRect.top),
      Offset(drawerRect.left, drawerRect.bottom),
      leftHighlightPaint,
    );

    // 右側の影
    final Paint rightShadowPaint = Paint()
      ..color = Colors.grey[400]!.withOpacity(0.5)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      Offset(drawerRect.right, drawerRect.top),
      Offset(drawerRect.right, drawerRect.bottom),
      rightShadowPaint,
    );

    // 外側境界線
    final Paint borderPaint = Paint()
      ..color = Colors.grey[600]!.withOpacity(0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    canvas.drawRRect(drawerRect, borderPaint);

    // 正面UIと同じ内部パネル（8px inset）
    final RRect innerPanelRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        drawerRect.left + 8,
        drawerRect.top + 8,
        drawerRect.width - 16,
        drawerRect.height - 16,
      ),
      const Radius.circular(4), // 正面UIと同じ4px
    );

    final Paint innerPanelPaint = Paint()
      ..color = Colors.white.withOpacity(0.9); // 正面UIと同じ透明度

    canvas.drawRRect(innerPanelRect, innerPanelPaint);

    // 内部パネル境界線（正面UIと同じ）
    final Paint innerPanelBorderPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;

    canvas.drawRRect(innerPanelRect, innerPanelBorderPaint);

    // 正面UIと同じゴムガスケット
    final RRect gasketOuterRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        drawerRect.left + 2,
        drawerRect.top + 2,
        drawerRect.width - 4,
        drawerRect.height - 4,
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

    // 下方向に引き出された引き出しのハンドル（上部に配置）
    final Rect handleRect = Rect.fromLTWH(
      drawerRect.left + (drawerRect.width / 2) - 30,
      drawerRect.top + 8,  // 引き出しの上部にハンドルを配置
      60, // ハンドル幅
      12, // ハンドル高さ
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

    // ハンドル内部（正面UIと同じ）
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

    // 空の引き出し内部のみ（食材は描画しない）
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