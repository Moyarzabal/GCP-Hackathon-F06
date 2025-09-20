import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:math' as math;
import '../../../../shared/models/product.dart';

/// 安全なopacity値を返すヘルパー関数
double _safeOpacity(double value) {
  if (value.isNaN || value.isInfinite) return 0.0;
  return math.max(0.0, math.min(1.0, value));
}

/// 冷蔵庫の扉レイヤー（最前面に配置）
class FridgeDoorLayer extends StatelessWidget {
  final Animation<double> leftDoorAnimation;
  final Animation<double> rightDoorAnimation;
  final VoidCallback onLeftDoorTap;
  final VoidCallback onRightDoorTap;
  final Function(FridgeCompartment, int) onSectionTap;
  final Map<String, int> counts;

  const FridgeDoorLayer({
    Key? key,
    required this.leftDoorAnimation,
    required this.rightDoorAnimation,
    required this.onLeftDoorTap,
    required this.onRightDoorTap,
    required this.onSectionTap,
    required this.counts,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 左扉（3D変換付き）
            _build3DDoor(
              constraints: constraints,
              animation: leftDoorAnimation,
              isLeft: true,
              onTap: onLeftDoorTap,
              onDoubleTap: () => onSectionTap(FridgeCompartment.doorLeft, 0),
            ),
            // 右扉（3D変換付き）
            _build3DDoor(
              constraints: constraints,
              animation: rightDoorAnimation,
              isLeft: false,
              onTap: onRightDoorTap,
              onDoubleTap: () => onSectionTap(FridgeCompartment.doorRight, 0),
            ),
          ],
        );
      },
    );
  }

  Widget _build3DDoor({
    required BoxConstraints constraints,
    required Animation<double> animation,
    required bool isLeft,
    required VoidCallback onTap,
    required VoidCallback onDoubleTap,
  }) {
    // 冷蔵庫本体のサイズと位置に合わせる（layered_3d_fridge_widget.dartのFridgeBodyPainterと同じ）
    final double fridgeBodyLeft = constraints.maxWidth * 0.1;
    final double fridgeBodyWidth = constraints.maxWidth * 0.8;
    final double fridgeBodyTop = constraints.maxHeight * 0.02;
    final double fridgeBodyHeight = constraints.maxHeight * 0.75;

    // 冷蔵庫本体の正確な端の位置
    final double fridgeLeftEdge = fridgeBodyLeft;  // 冷蔵庫の左端
    final double fridgeRightEdge = fridgeBodyLeft + fridgeBodyWidth;  // 冷蔵庫の右端
    final double fridgeCenterX = fridgeBodyLeft + (fridgeBodyWidth / 2);  // 冷蔵庫の中央

    // 扉の幅を冷蔵庫本体の正確に半分にして軸のぶれを防ぐ
    final double width = fridgeBodyWidth * 0.5;  // 正確に半分
    // 扉の高さを冷蔵庫本体の50%に変更（新しい4段構成に対応）
    final double height = fridgeBodyHeight * 0.5; // 1段目: 50%
    // 扉の上部位置を冷蔵庫本体の上部位置に合わせる
    final double top = fridgeBodyTop;

    // Z移動を削除したため不要な変数も削除
    
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 3D回転の角度（ラジアン）
        final double rotationAngle = animation.value;
        
        // 回転の軸（左扉は左端、右扉は右端）
        final Alignment rotationAlignment = isLeft 
            ? Alignment.centerLeft 
            : Alignment.centerRight;
        
        // Z軸移動を削除してシンプルな回転のみにする（軸のぶれを防ぐ）
        
        // 扉の配置と回転の計算を単純化
        // 左扉：冷蔵庫の左端に配置、左端（左側）を軸に回転
        // 右扉：冷蔵庫の中央に配置、右端（右側）を軸に回転
        final double actualLeft = isLeft
            ? fridgeLeftEdge  // 左扉：左端から開始
            : fridgeCenterX;  // 右扉：中央から開始

        return Positioned(
          left: actualLeft,
          top: top,
          width: width,
          height: height,
          child: Transform(
            alignment: rotationAlignment,
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001) // パースペクティブ
              ..rotateY(isLeft ? rotationAngle : -rotationAngle),  // シンプルな回転のみ
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
                  borderRadius: BorderRadius.circular(6), // より現実的な角丸
                  // 影を削除してシンプルに
                  border: Border.all(
                    color: Colors.grey[400]!.withOpacity(_safeOpacity(0.6 + rotationAngle.abs() * 0.2)),
                    width: 2,
                  ),
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
                          // パネル内部の影も削除
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
                    // 扉のハンドル - リアルな3Dメタリック（扉の端に固定）
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
                          // ハンドルの影も削除
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
                    // 扉のガラス効果（開いている時に強調）
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
                    // 反射光効果 - 白い扉用
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