import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math' as math;
import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../providers/fridge_view_provider.dart';
import 'fridge_shelf_layer.dart';
import 'fridge_door_layer.dart';

/// 安全なopacity値を返すヘルパー関数
double _safeOpacity(double value) {
  if (value.isNaN || value.isInfinite) return 0.0;
  return math.max(0.0, math.min(1.0, value));
}

/// 3Dレイヤー構造の冷蔵庫ウィジェット
class Layered3DFridgeWidget extends ConsumerStatefulWidget {
  final Function(FridgeCompartment compartment, int level) onSectionTap;

  const Layered3DFridgeWidget({
    Key? key,
    required this.onSectionTap,
  }) : super(key: key);

  @override
  ConsumerState<Layered3DFridgeWidget> createState() => _Layered3DFridgeWidgetState();
}

class _Layered3DFridgeWidgetState extends ConsumerState<Layered3DFridgeWidget>
    with TickerProviderStateMixin {
  // 1段目: 大扉のアニメーションコントローラー（固定・変更禁止）
  late AnimationController _leftDoorController;
  late AnimationController _rightDoorController;
  Animation<double>? _leftDoorAnimation;
  Animation<double>? _rightDoorAnimation;

  // 2段目: 左右分割セクションのアニメーションコントローラー
  late AnimationController _secondLeftController;
  late AnimationController _secondRightController;
  Animation<double>? _secondLeftAnimation;
  Animation<double>? _secondRightAnimation;

  // 3-4段目: 引き出しのアニメーションコントローラー
  late AnimationController _vegetableDrawerController;
  late AnimationController _freezerDrawerController;
  Animation<double>? _vegetableDrawerAnimation;
  Animation<double>? _freezerDrawerAnimation;

  // 開閉状態管理
  bool _leftDoorOpen = false;
  bool _rightDoorOpen = false;
  bool _secondLeftOpen = false;
  bool _secondRightOpen = false;
  bool _vegetableDrawerOpen = false;
  bool _freezerDrawerOpen = false;

  // アクティブな引き出しを追跡（最前面に表示するため）
  String? _activeDrawer;

  // アニメーションのゲッター（null安全）
  Animation<double> get leftDoorAnimation => _leftDoorAnimation ?? _createDefaultAnimation(_leftDoorController);
  Animation<double> get rightDoorAnimation => _rightDoorAnimation ?? _createDefaultAnimation(_rightDoorController);
  Animation<double> get secondLeftAnimation => _secondLeftAnimation ?? _createDefaultAnimation(_secondLeftController);
  Animation<double> get secondRightAnimation => _secondRightAnimation ?? _createDefaultAnimation(_secondRightController);
  Animation<double> get vegetableDrawerAnimation => _vegetableDrawerAnimation ?? _createDefaultAnimation(_vegetableDrawerController);
  Animation<double> get freezerDrawerAnimation => _freezerDrawerAnimation ?? _createDefaultAnimation(_freezerDrawerController);

  Animation<double> _createDefaultAnimation(AnimationController controller) {
    return Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: controller, curve: Curves.easeInOutCubic)
    );
  }

  /// 画面サイズに基づいた扉の最大開き角度を計算
  double _calculateMaxDoorAngle(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;
    
    // スマホサイズ（幅414px以下）では120度開く
    if (screenWidth <= 414) {
      return 2.1; // 約120度 - スマホ用
    }
    // タブレットサイズ（幅768px以下）では120度開く
    else if (screenWidth <= 768) {
      return 2.1; // 約120度 - タブレット用
    }
    // デスクトップサイズでは120度開く
    else {
      return 2.1; // 約120度 - デスクトップ用
    }
  }

  @override
  void initState() {
    super.initState();

    // 1段目: 大扉のアニメーション設定（固定・変更禁止）
    _leftDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // リアルな冷蔵庫扉の開閉時間
    );

    _rightDoorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200), // リアルな冷蔵庫扉の開閉時間
    );

    // 2段目: 左右分割セクションのアニメーション設定
    _secondLeftController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // より軽快な小扉
    );

    _secondRightController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800), // より軽快な小扉
    );

    // 3-4段目: 引き出しのアニメーション設定
    _vegetableDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 引き出しの滑らか動作
    );

    _freezerDrawerController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600), // 引き出しの滑らか動作
    );
    
    // 1段目: 大扉のデフォルトアニメーション（レスポンシブ対応は didChangeDependencies で処理）
    _leftDoorAnimation = Tween<double>(
      begin: 0.0,
      end: 2.1, // デフォルト値（120度 = 2.1ラジアン）
    ).animate(CurvedAnimation(
      parent: _leftDoorController,
      curve: const Interval(
        0.0, 1.0,
        curve: Cubic(0.25, 0.46, 0.45, 0.94), // リアルな冷蔵庫扉の抵抗感
      ),
    ));

    _rightDoorAnimation = Tween<double>(
      begin: 0.0,
      end: 2.1, // デフォルト値（120度 = 2.1ラジアン）
    ).animate(CurvedAnimation(
      parent: _rightDoorController,
      curve: const Interval(
        0.0, 1.0,
        curve: Cubic(0.25, 0.46, 0.45, 0.94), // リアルな冷蔵庫扉の抵抗感
      ),
    ));

    // 2段目: 左右分割セクションのアニメーション（引き出し）
    _secondLeftAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0, // 引き出し距離（ピクセル）
    ).animate(CurvedAnimation(
      parent: _secondLeftController,
      curve: Curves.easeInOutCubic,
    ));

    _secondRightAnimation = Tween<double>(
      begin: 0.0,
      end: 100.0, // 引き出し距離（ピクセル）
    ).animate(CurvedAnimation(
      parent: _secondRightController,
      curve: Curves.easeInOutCubic,
    ));

    // 3-4段目: 引き出しアニメーション
    _vegetableDrawerAnimation = Tween<double>(
      begin: 0.0,
      end: 120.0, // 引き出し距離（ピクセル）
    ).animate(CurvedAnimation(
      parent: _vegetableDrawerController,
      curve: Curves.easeInOutCubic,
    ));

    _freezerDrawerAnimation = Tween<double>(
      begin: 0.0,
      end: 120.0, // 引き出し距離（ピクセル）
    ).animate(CurvedAnimation(
      parent: _freezerDrawerController,
      curve: Curves.easeInOutCubic,
    ));
  }
  
  /// 画面サイズに応じてアニメーションを初期化
  void _initializeAnimations(BuildContext context) {
    final maxAngle = _calculateMaxDoorAngle(context);
    
    _leftDoorAnimation = Tween<double>(
      begin: 0.0,
      end: maxAngle,
    ).animate(CurvedAnimation(
      parent: _leftDoorController,
      curve: const Interval(
        0.0, 1.0,
        curve: Cubic(0.25, 0.46, 0.45, 0.94), // リアルな冷蔵庫扉の抵抗感
      ),
    ));
    
    _rightDoorAnimation = Tween<double>(
      begin: 0.0,
      end: maxAngle,
    ).animate(CurvedAnimation(
      parent: _rightDoorController,
      curve: const Interval(
        0.0, 1.0,
        curve: Cubic(0.25, 0.46, 0.45, 0.94), // リアルな冷蔵庫扉の抵抗感
      ),
    ));
  }

  @override
  void dispose() {
    _leftDoorController.dispose();
    _rightDoorController.dispose();
    _secondLeftController.dispose();
    _secondRightController.dispose();
    _vegetableDrawerController.dispose();
    _freezerDrawerController.dispose();
    super.dispose();
  }

  void _toggleBothDoors() async {
    // どちらか一方でも開いている場合は閉じる、両方閉じている場合は開く
    final bool shouldOpen = !_leftDoorOpen && !_rightDoorOpen;

    setState(() {
      _leftDoorOpen = shouldOpen;
      _rightDoorOpen = shouldOpen;
    });

    if (shouldOpen) {
      // 扉が開く時の微小な抵抗感をシミュレート
      await Future.delayed(const Duration(milliseconds: 50));
      // 左右の扉を同時に開く
      _leftDoorController.forward();
      _rightDoorController.forward();
    } else {
      // 扉が閉まる時はより素早く、同時に閉める
      _leftDoorController.reverse();
      _rightDoorController.reverse();
    }
  }

  // 後方互換性のため残しておく（統一されたハンドラーを呼び出す）
  void _toggleLeftDoor() {
    _toggleBothDoors();
  }

  void _toggleRightDoor() {
    _toggleBothDoors();
  }

  // 2段目: 左分割セクション開閉メソッド
  void _toggleSecondLeft() async {
    setState(() {
      _secondLeftOpen = !_secondLeftOpen;
      // タップされた引き出しをアクティブに設定
      _activeDrawer = _secondLeftOpen ? 'secondLeft' : null;
    });

    if (_secondLeftOpen) {
      await Future.delayed(const Duration(milliseconds: 30));
      _secondLeftController.forward();
    } else {
      _secondLeftController.reverse();
    }
  }

  // 2段目: 右分割セクション開閉メソッド
  void _toggleSecondRight() async {
    setState(() {
      _secondRightOpen = !_secondRightOpen;
      // タップされた引き出しをアクティブに設定
      _activeDrawer = _secondRightOpen ? 'secondRight' : null;
    });

    if (_secondRightOpen) {
      await Future.delayed(const Duration(milliseconds: 30));
      _secondRightController.forward();
    } else {
      _secondRightController.reverse();
    }
  }

  // 3段目: 野菜室引き出し開閉メソッド
  void _toggleVegetableDrawer() async {
    setState(() {
      _vegetableDrawerOpen = !_vegetableDrawerOpen;
      // タップされた引き出しをアクティブに設定
      _activeDrawer = _vegetableDrawerOpen ? 'vegetable' : null;
    });

    if (_vegetableDrawerOpen) {
      await Future.delayed(const Duration(milliseconds: 20));
      _vegetableDrawerController.forward();
    } else {
      _vegetableDrawerController.reverse();
    }
  }

  // 4段目: 冷凍庫引き出し開閉メソッド
  void _toggleFreezerDrawer() async {
    setState(() {
      _freezerDrawerOpen = !_freezerDrawerOpen;
      // タップされた引き出しをアクティブに設定
      _activeDrawer = _freezerDrawerOpen ? 'freezer' : null;
    });

    if (_freezerDrawerOpen) {
      await Future.delayed(const Duration(milliseconds: 20));
      _freezerDrawerController.forward();
    } else {
      _freezerDrawerController.reverse();
    }
  }

  @override  
  Widget build(BuildContext context) {
    final counts = ref.watch(sectionCountsProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    
    // 画面サイズに応じたコンテナサイズ調整
    double containerPadding = screenWidth <= 414 ? 16.0 : (screenWidth <= 768 ? 24.0 : 32.0);
    
    return Padding(
      padding: EdgeInsets.all(containerPadding),
      child: Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(-0.3, -0.4),
          radius: 1.5,
          colors: [
            Colors.white,
            const Color(0xFFFBFBFB),
            Colors.grey[50]!,
            Colors.grey[100]!.withOpacity(0.8),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
        borderRadius: BorderRadius.circular(20),
        // 全ての影を削除
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: Stack(
          children: [
            // 背景レイヤー（最下層）
            _buildBackgroundLayer(),
            
            // 冷蔵庫本体レイヤー
            _buildFridgeBodyLayer(),
            
            // 棚レイヤー（扉の奥、Z軸で後ろ）
            AnimatedBuilder(
              animation: Listenable.merge([leftDoorAnimation, rightDoorAnimation]),
              builder: (context, child) {
                // 扉の開き具合に応じて棚の明るさを調整
                final maxAngle = _calculateMaxDoorAngle(context);
                final totalMaxAngle = maxAngle * 2; // 左右の扉の最大角度の合計
                final brightness = (leftDoorAnimation.value + rightDoorAnimation.value) / totalMaxAngle;
                return Transform(
                  transform: Matrix4.identity()
                    ..translate(0.0, 0.0, -50.0) // Z軸で奥に配置
                    ..scale(1.0 - (0.02 * (1 - brightness))), // 奥行き感のためのスケール調整
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    // 暗くなるエフェクトを削除
                    child: FridgeShelfLayer(
                      onSectionTap: widget.onSectionTap,
                      counts: counts,
                      isVisible: _leftDoorOpen || _rightDoorOpen,
                    ),
                  ),
                );
              },
            ),
            
            // コントロールパネルを削除
            
            // 扉レイヤー（最前面、Z軸で手前）
            Transform(
              transform: Matrix4.identity()
                ..translate(0.0, 0.0, 100.0), // Z軸で大きく手前に配置して棚を確実にカバー
              child: FridgeDoorLayer(
                leftDoorAnimation: leftDoorAnimation,
                rightDoorAnimation: rightDoorAnimation,
                onLeftDoorTap: _toggleLeftDoor,
                onRightDoorTap: _toggleRightDoor,
                onSectionTap: widget.onSectionTap,
                counts: counts,
              ),
            ),
            
            // 新しい4段構成レイヤー（2-4段目）
            _buildUnifiedSectionsLayer(),
          ],
        ),
      ),
    ),
    );
  }

  Widget _buildBackgroundLayer() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: const Alignment(0.2, -0.3),
          radius: 2.0,
          colors: [
            Colors.grey[700]!.withOpacity(0.6), // より明るい中心部
            Colors.grey[800]!.withOpacity(0.8),
            Colors.grey[850]!.withOpacity(0.9),
            Colors.black.withOpacity(0.95),
          ],
          stops: const [0.0, 0.3, 0.7, 1.0],
        ),
      ),
      child: Stack(
        children: [
          // 環境光効果（キッチンの照明を想定）
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: 100,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.amber[50]!.withOpacity(0.15),
                    Colors.orange[50]!.withOpacity(0.1),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // 床面からの反射光
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            height: 80,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.grey[300]!.withOpacity(0.1),
                    Colors.grey[200]!.withOpacity(0.05),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          CustomPaint(
            painter: DepthShadowPainter(
              leftDoorOpen: _leftDoorOpen,
              rightDoorOpen: _rightDoorOpen,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFridgeBodyLayer() {
    return CustomPaint(
      size: Size.infinite,
      painter: FridgeBodyPainter(),
    );
  }

  /// 新しい統一された4段構成レイヤー（2-4段目）
  Widget _buildUnifiedSectionsLayer() {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 冷蔵庫本体のサイズと位置（FridgeBodyPainterと同じ比率）
        final double fridgeBodyLeft = constraints.maxWidth * 0.1;
        final double fridgeBodyWidth = constraints.maxWidth * 0.8;
        final double fridgeBodyTop = constraints.maxHeight * 0.02;
        final double fridgeBodyHeight = constraints.maxHeight * 0.95;

        // 1段目の高さ（扉領域、55%に調整）
        final double topSectionHeight = fridgeBodyHeight * 0.55;

        // 2-4段目の開始位置（1段目の下）
        final double sectionsStartY = fridgeBodyTop + topSectionHeight;
        final double sectionsHeight = fridgeBodyHeight * 0.45;

        // 各段の高さ配分
        final double section2Height = sectionsHeight * 0.4;  // 2段目: 40%
        final double section3Height = sectionsHeight * 0.3;  // 3段目: 30%
        final double section4Height = sectionsHeight * 0.3;  // 4段目: 30%

        // 各セクションの定義
        final Map<String, Widget> sections = {
          'secondSection': _buildSecondSection(
            left: fridgeBodyLeft,
            top: sectionsStartY,
            width: fridgeBodyWidth,
            height: section2Height,
          ),
          'vegetable': _buildThirdSection(
            left: fridgeBodyLeft,
            top: sectionsStartY + section2Height,
            width: fridgeBodyWidth,
            height: section3Height,
          ),
          'freezer': _buildFourthSection(
            left: fridgeBodyLeft,
            top: sectionsStartY + section2Height + section3Height,
            width: fridgeBodyWidth,
            height: section4Height,
          ),
        };

        // アクティブな引き出しを最前面に配置するための動的Stack
        List<Widget> stackChildren = [];

        // 非アクティブな引き出しを先に追加
        sections.forEach((key, widget) {
          if (_activeDrawer == null ||
              (_activeDrawer != key &&
               !(_activeDrawer == 'secondLeft' && key == 'secondSection') &&
               !(_activeDrawer == 'secondRight' && key == 'secondSection'))) {
            stackChildren.add(widget);
          }
        });

        // アクティブな引き出しを最後に追加（最前面に表示）
        if (_activeDrawer != null) {
          if (_activeDrawer == 'vegetable' && sections.containsKey('vegetable')) {
            stackChildren.add(sections['vegetable']!);
          } else if (_activeDrawer == 'freezer' && sections.containsKey('freezer')) {
            stackChildren.add(sections['freezer']!);
          } else if ((_activeDrawer == 'secondLeft' || _activeDrawer == 'secondRight') &&
                     sections.containsKey('secondSection')) {
            stackChildren.add(sections['secondSection']!);
          }
        }

        return Stack(children: stackChildren);
      },
    );
  }

  /// 2段目: 左右分割セクション（引き出し）
  Widget _buildSecondSection({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    // 左右の引き出しウィジェットを定義
    final leftDrawer = _buildDrawerSection(
      left: left,
      top: top,
      width: width / 2,
      height: height,
      animation: secondLeftAnimation,
      label: '冷凍庫',
      backgroundColor: Colors.white,
      onTap: _toggleSecondLeft,
      onDoubleTap: () => widget.onSectionTap(FridgeCompartment.freezer, 1),
      drawerKey: 'secondLeft',
    );

    final rightDrawer = _buildDrawerSection(
      left: left + width / 2,
      top: top,
      width: width / 2,
      height: height,
      animation: secondRightAnimation,
      label: '冷蔵室',
      backgroundColor: Colors.white,
      onTap: _toggleSecondRight,
      onDoubleTap: () => widget.onSectionTap(FridgeCompartment.refrigerator, 1),
      drawerKey: 'secondRight',
    );

    // アクティブな引き出しを最前面に配置するための動的Stack
    List<Widget> stackChildren = [];

    // アクティブでない引き出しを先に追加
    if (_activeDrawer != 'secondLeft') {
      stackChildren.add(leftDrawer);
    }
    if (_activeDrawer != 'secondRight') {
      stackChildren.add(rightDrawer);
    }

    // アクティブな引き出しを最後に追加（最前面に表示）
    if (_activeDrawer == 'secondLeft') {
      stackChildren.add(leftDrawer);
    } else if (_activeDrawer == 'secondRight') {
      stackChildren.add(rightDrawer);
    }

    return Stack(children: stackChildren);
  }

  /// 3段目: 野菜室（引き出しスタイル）
  Widget _buildThirdSection({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return _buildDrawerSection(
      left: left,
      top: top,
      width: width,
      height: height,
      animation: vegetableDrawerAnimation,
      label: '野菜室',
      backgroundColor: Colors.white,
      onTap: _toggleVegetableDrawer,
      onDoubleTap: () => widget.onSectionTap(FridgeCompartment.vegetableDrawer, 0),
      drawerKey: 'vegetable',
    );
  }

  /// 4段目: 冷凍庫（引き出しスタイル）
  Widget _buildFourthSection({
    required double left,
    required double top,
    required double width,
    required double height,
  }) {
    return _buildDrawerSection(
      left: left,
      top: top,
      width: width,
      height: height,
      animation: freezerDrawerAnimation,
      label: '冷凍庫',
      backgroundColor: Colors.white,
      onTap: _toggleFreezerDrawer,
      onDoubleTap: () => widget.onSectionTap(FridgeCompartment.freezer, 0),
      drawerKey: 'freezer',
    );
  }

  /// 引き出し用アニメーションセクション（3D引き出し）
  Widget _buildDrawerSection({
    required double left,
    required double top,
    required double width,
    required double height,
    required Animation<double> animation,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
    String? drawerKey, // アクティブ判定のためのキー
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double pullDistance = animation.value;
        final bool isActive = drawerKey != null && _activeDrawer == drawerKey;

        // アクティブな引き出しには追加のZ軸効果を適用
        final double additionalZ = isActive ? 50.0 : 0.0; // 最前面に配置するための追加Z軸移動
        final double perspective = isActive ? 0.003 : 0.002; // アクティブな引き出しはより強いパースペクティブ

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()
              ..setEntry(3, 2, perspective) // アクティブ時は強めのパースペクティブ
              ..translate(0.0, 0.0, -pullDistance - additionalZ) // Z軸方向を逆に（手前に引き出し）+ アクティブ時の追加移動
              ..scale(1.0 + (pullDistance * 0.002) + (isActive ? 0.05 : 0.0)), // 引き出すと少し大きくなる + アクティブ時の追加拡大
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              onDoubleTap: () {
                HapticFeedback.mediumImpact();
                onDoubleTap();
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                      Colors.grey[50]!,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: Colors.grey[400]!.withOpacity(_safeOpacity(0.6 + pullDistance * 0.01)),
                    width: 2,
                  ),
                  // 引き出し時の影効果（手前に出てくる影）
                  boxShadow: pullDistance > 0 ? [
                    BoxShadow(
                      color: Colors.black.withOpacity(_safeOpacity(0.3 * (pullDistance / 100))),
                      offset: Offset(0, pullDistance * 0.15), // 下向きの影
                      blurRadius: pullDistance * 0.3,
                      spreadRadius: pullDistance * 0.05,
                    ),
                    BoxShadow(
                      color: Colors.black.withOpacity(_safeOpacity(0.1 * (pullDistance / 100))),
                      offset: Offset(pullDistance * 0.05, pullDistance * 0.05), // 右下の影
                      blurRadius: pullDistance * 0.5,
                      spreadRadius: 0,
                    ),
                  ] : null,
                ),
                child: Stack(
                  children: [
                    // リアルな扉パネル効果
                    Positioned(
                      left: 8,
                      top: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey[300]!.withOpacity(0.6),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // 扉のゴムガスケット
                    Positioned(
                      left: 2,
                      top: 2,
                      right: 2,
                      bottom: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[600]!.withOpacity(0.8),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[500]!.withOpacity(0.6),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // 引き出し用水平ハンドル
                    Positioned(
                      left: width / 2 - 30,
                      top: height - 20,
                      child: Container(
                        width: 60,
                        height: 12,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              Colors.grey[200]!, // ハイライト
                              Colors.grey[400]!, // メイン
                              Colors.grey[600]!, // シャドウ
                            ],
                            stops: const [0.0, 0.5, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[200]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 2段目: アニメーション付きセクション（扉開閉）
  Widget _buildAnimatedSection({
    required double left,
    required double top,
    required double width,
    required double height,
    required Animation<double> animation,
    required bool isLeft,
    required String label,
    required Color backgroundColor,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        final double rotationAngle = animation.value;

        return Positioned(
          left: left,
          top: top,
          width: width,
          height: height,
          child: Transform(
            alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // パースペクティブ
              ..rotateY(isLeft ? rotationAngle : -rotationAngle),
            child: GestureDetector(
              onTap: () {
                HapticFeedback.lightImpact();
                onTap();
              },
              onDoubleTap: () {
                HapticFeedback.mediumImpact();
                onDoubleTap();
              },
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white,
                      Colors.grey[50]!,
                      Colors.grey[100]!,
                      Colors.grey[50]!,
                      Colors.white,
                    ],
                    stops: const [0.0, 0.2, 0.5, 0.8, 1.0],
                  ),
                  borderRadius: BorderRadius.circular(6), // 上部扉と同じ角丸
                  border: Border.all(
                    color: Colors.grey[400]!.withOpacity(0.6 + rotationAngle.abs() * 0.2),
                    width: 2,
                  ),
                ),
                child: Stack(
                  children: [
                    // リアルな扉パネル効果（上部扉と同じ）
                    Positioned(
                      left: 8,
                      top: 8,
                      right: 8,
                      bottom: 8,
                      child: Container(
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.9),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: Colors.grey[300]!.withOpacity(0.6),
                            width: 0.5,
                          ),
                        ),
                      ),
                    ),
                    // 扉のゴムガスケット（上部扉と同じ）
                    Positioned(
                      left: 2,
                      top: 2,
                      right: 2,
                      bottom: 2,
                      child: Container(
                        decoration: BoxDecoration(
                          border: Border.all(
                            color: Colors.grey[600]!.withOpacity(0.8),
                            width: 1.5,
                          ),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(1),
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: Colors.grey[500]!.withOpacity(0.6),
                              width: 0.5,
                            ),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                    // 扉のハンドル - リアルな3Dメタリック（上部扉と同じ）
                    Positioned(
                      left: isLeft ? width - 20 : 5, // 左扉は右端、右扉は左端にハンドル
                      top: height / 2 - 35,
                      child: Container(
                        width: 15,
                        height: 70,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              Colors.grey[200]!, // ハイライト
                              Colors.grey[400]!, // メイン
                              Colors.grey[600]!, // シャドウ
                              Colors.grey[300]!, // リフレクション
                            ],
                            stops: const [0.0, 0.3, 0.7, 1.0],
                          ),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Container(
                          margin: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.grey[300]!,
                                Colors.grey[200]!,
                                Colors.grey[300]!,
                              ],
                            ),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                    ),
                    // 扉のガラス効果（上部扉と同じ）
                    Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withOpacity(_safeOpacity(0.15 * (1.0 - rotationAngle.abs()))),
                            Colors.transparent,
                            Colors.white.withOpacity(_safeOpacity(0.1 * (1.0 - rotationAngle.abs()))),
                            Colors.transparent,
                            Colors.white.withOpacity(_safeOpacity(0.05 * (1.0 - rotationAngle.abs()))),
                          ],
                          stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    // 反射光効果 - 白い扉用（上部扉と同じ）
                    if (rotationAngle.abs() > 0.3)
                      Positioned(
                        top: height * 0.2,
                        left: isLeft ? width * 0.3 : width * 0.1,
                        child: Container(
                          width: width * 0.4,
                          height: height * 0.3,
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              colors: [
                                Colors.white.withOpacity(_safeOpacity(0.6 * rotationAngle.abs())),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

}

/// 冷蔵庫本体の描画
class FridgeBodyPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // 冷蔵庫本体の枠 - リアルな比率に調整
    final RRect body = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        size.width * 0.1, // 左右の余白
        size.height * 0.02, // 上部余白を少なく
        size.width * 0.8, // 横幅
        size.height * 0.75, // 高さを増加（実際の冷蔵庫は縦長）
      ),
      const Radius.circular(12), // より現実的な角丸
    );
    
    // 複数レイヤーの影を削除
    
    // 冷蔵庫本体 - リアルな家電素材
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
      ).createShader(body.outerRect);
    
    canvas.drawRRect(body, bodyPaint);
    
    // 家電特有の表面テクスチャ（微細な凹凸感）
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
      ).createShader(body.outerRect);
    
    canvas.drawRRect(body, texturePaint);
    
    // ブラシド仕上げ効果（縦方向の微細なライン）
    for (int i = 0; i < 40; i++) {
      final double x = body.left + (body.width / 40) * i;
      final Paint brushPaint = Paint()
        ..color = Colors.grey[200]!.withOpacity(0.15)
        ..strokeWidth = 0.5
        ..style = PaintingStyle.stroke;
      
      canvas.drawLine(
        Offset(x, body.top + 5),
        Offset(x, body.bottom - 5),
        brushPaint,
      );
    }
    
    // 金属エッジ加工（ベゼル効果）
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
      ).createShader(body.outerRect);
    
    // ベゼルエッジの描画（外側の枠）
    final Paint bevelStrokePaint = Paint()
      ..shader = bevelPaint.shader
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;
    
    canvas.drawRRect(body, bevelStrokePaint);
    
    // 内側ボーダー（プラスチック成型ライン）
    final Paint innerBorderPaint = Paint()
      ..color = Colors.grey[300]!.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;
    
    final RRect innerBorder = RRect.fromRectAndRadius(
      Rect.fromLTWH(
        body.left + 2,
        body.top + 2,
        body.width - 4,
        body.height - 4,
      ),
      const Radius.circular(10),
    );
    
    canvas.drawRRect(innerBorder, innerBorderPaint);
    
    // 高光沢仕上げ効果（光の反射）
    final Paint glossPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.centerRight,
        colors: [
          Colors.white.withOpacity(0.6),
          Colors.white.withOpacity(0.3),
          Colors.transparent,
          Colors.white.withOpacity(0.1),
        ],
        stops: const [0.0, 0.2, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(
        body.left,
        body.top,
        body.width * 0.4,
        body.height * 0.3,
      ));
    
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
          body.left,
          body.top,
          body.width * 0.4,
          body.height * 0.3,
        ),
        const Radius.circular(12),
      ),
      glossPaint,
    );
    
    // 内部の影（奥行き感） - より自然な陰影
    final Paint innerShadowPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(0.3, -0.3),
        radius: 1.2,
        colors: [
          Colors.transparent,
          Colors.grey[200]!.withOpacity(0.1),
          Colors.grey[300]!.withOpacity(0.2),
          Colors.grey[400]!.withOpacity(0.1),
        ],
        stops: const [0.0, 0.4, 0.8, 1.0],
      ).createShader(body.outerRect);
    
    canvas.drawRRect(body, innerShadowPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// 深度に応じた影の描画
class DepthShadowPainter extends CustomPainter {
  final bool leftDoorOpen;
  final bool rightDoorOpen;

  DepthShadowPainter({
    required this.leftDoorOpen,
    required this.rightDoorOpen,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 扉が開いている時のリアルな内部照明効果
    if (leftDoorOpen || rightDoorOpen) {
      // メイン照明 - 冷蔵庫内部の白色LED
      final Paint mainLightPaint = Paint()
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
        ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
      
      canvas.drawRect(
        Rect.fromLTWH(0, 0, size.width, size.height),
        mainLightPaint,
      );
      
      // 棚ライト効果 - 各棚に小さなライト
      for (int i = 0; i < 3; i++) {
        final double shelfY = size.height * (0.15 + i * 0.2);
        final Paint shelfLightPaint = Paint()
          ..shader = LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [
              Colors.transparent,
              Colors.blue[50]!.withOpacity(0.6),
              Colors.blue[50]!.withOpacity(0.6),
              Colors.transparent,
            ],
            stops: const [0.0, 0.2, 0.8, 1.0],
          ).createShader(Rect.fromLTWH(
            size.width * 0.1,
            shelfY,
            size.width * 0.8,
            4,
          ));
        
        canvas.drawRect(
          Rect.fromLTWH(
            size.width * 0.1,
            shelfY,
            size.width * 0.8,
            4,
          ),
          shelfLightPaint,
        );
      }
      
      // 背面ライト効果
      final Paint backLightPaint = Paint()
        ..shader = LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Colors.blue[50]!.withOpacity(0.3),
            Colors.blue[100]!.withOpacity(0.2),
            Colors.blue[50]!.withOpacity(0.3),
          ],
        ).createShader(Rect.fromLTWH(
          size.width * 0.15,
          size.height * 0.1,
          size.width * 0.7,
          size.height * 0.6,
        ));
      
      canvas.drawRect(
        Rect.fromLTWH(
          size.width * 0.15,
          size.height * 0.1,
          size.width * 0.7,
          size.height * 0.6,
        ),
        backLightPaint,
      );
    }
  }

  @override
  bool shouldRepaint(DepthShadowPainter oldDelegate) => 
      oldDelegate.leftDoorOpen != leftDoorOpen || 
      oldDelegate.rightDoorOpen != rightDoorOpen;
}