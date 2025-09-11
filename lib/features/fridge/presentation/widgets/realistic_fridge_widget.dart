import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;
import '../providers/fridge_view_provider.dart';
import 'realistic_fridge_painter.dart';

/// 実機ライクな冷蔵庫俯瞰ウィジェット（扉/引き出しアニメーション含む）
class RealisticFridgeWidget extends ConsumerStatefulWidget {
  final void Function(FridgeCompartment compartment, int level) onSectionTap;

  const RealisticFridgeWidget({super.key, required this.onSectionTap});

  @override
  ConsumerState<RealisticFridgeWidget> createState() => _RealisticFridgeWidgetState();
}

class _RealisticFridgeWidgetState extends ConsumerState<RealisticFridgeWidget> with TickerProviderStateMixin {
  late final AnimationController _leftDoorCtr;
  late final AnimationController _rightDoorCtr;
  late final AnimationController _vegDrawerCtr;
  late final AnimationController _freezerCtr;

  @override
  void initState() {
    super.initState();
    _leftDoorCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _rightDoorCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
    _vegDrawerCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 240));
    _freezerCtr = AnimationController(vsync: this, duration: const Duration(milliseconds: 260));
  }

  @override
  void dispose() {
    _leftDoorCtr.dispose();
    _rightDoorCtr.dispose();
    _vegDrawerCtr.dispose();
    _freezerCtr.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    final counts = ref.watch(sectionCountsProvider);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: RepaintBoundary(
        child: Stack(
          children: [
            // 本体（静的）
            CustomPaint(size: Size.infinite, painter: FridgeBodyPainter(colorScheme: color)),

            // ドア（左右）
            _buildDoor(
              alignment: Alignment.topLeft,
              isLeft: true,
              controller: _leftDoorCtr,
              onTap: () => _toggle(_leftDoorCtr),
              semanticsLabel: '左ドア',
              badge: _buildBadge(counts, FridgeCompartment.doorLeft, 0, color),
            ),
            _buildDoor(
              alignment: Alignment.topRight,
              isLeft: false,
              controller: _rightDoorCtr,
              onTap: () => _toggle(_rightDoorCtr),
              semanticsLabel: '右ドア',
              badge: _buildBadge(counts, FridgeCompartment.doorRight, 0, color),
            ),

            // 冷蔵室の棚（タップでズームビューへ）
            ...List.generate(3, (i) => _buildShelfTap(i, color, counts)),

            // 野菜室 引き出し
            _buildDrawer(
              topFactor: 0.68,
              heightFactor: 0.10,
              controller: _vegDrawerCtr,
              color: color,
              semanticsLabel: '野菜室',
              onTap: () => _toggle(_vegDrawerCtr),
              badge: _buildBadge(counts, FridgeCompartment.vegetableDrawer, 0, color),
            ),

            // 冷凍庫 引き出し
            _buildDrawer(
              topFactor: 0.85,
              heightFactor: 0.10,
              controller: _freezerCtr,
              color: color,
              semanticsLabel: '冷凍庫',
              onTap: () => _toggle(_freezerCtr),
              badge: _buildBadge(counts, FridgeCompartment.freezer, 0, color),
            ),
          ],
        ),
      ),
    );
  }

  void _toggle(AnimationController c) {
    if (c.status == AnimationStatus.completed || c.value >= 0.99) {
      c.reverse();
    } else {
      c.forward();
    }
  }

  Widget _buildBadge(Map<String, int> counts, FridgeCompartment c, int level, ColorScheme color) {
    final key = '${c.name}:$level';
    final count = counts[key] ?? 0;
    if (count == 0) return const SizedBox.shrink();
    return Align(
      alignment: Alignment.topRight,
      child: Container(
        margin: const EdgeInsets.all(6),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: color.tertiary,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text('$count', style: TextStyle(color: color.onTertiary, fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildDoor({
    required Alignment alignment,
    required bool isLeft,
    required AnimationController controller,
    required VoidCallback onTap,
    required String semanticsLabel,
    required Widget badge,
  }) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight * 0.18;
          final doorWidth = width / 2;
          final originX = isLeft ? 0.0 : doorWidth;
          final originY = 0.0;
          final angle = Tween<double>(begin: 0.0, end: isLeft ? -1.25 : 1.25)
              .chain(CurveTween(curve: Curves.easeOutCubic))
              .animate(controller);

          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(children: [
                Positioned(
                  left: isLeft ? 0 : doorWidth,
                  top: 0,
                  width: doorWidth,
                  height: height,
                  child: Semantics(
                    label: semanticsLabel,
                    value: controller.value > 0.01 ? '開' : '閉',
                    button: true,
                    child: GestureDetector(
                      onTap: onTap,
                      onDoubleTap: () => widget.onSectionTap(
                        isLeft ? FridgeCompartment.doorLeft : FridgeCompartment.doorRight,
                        0,
                      ),
                      child: Stack(children: [
                        // ヒンジ回転（擬似的な3D回転をTransformで表現）
                        Transform(
                          alignment: isLeft ? Alignment.centerLeft : Alignment.centerRight,
                          transform: Matrix4.identity()
                            ..setEntry(3, 2, 0.0015)
                            ..rotateY(angle.value),
                          child: _buildDoorPanel(isLeft),
                        ),
                        Positioned.fill(child: badge),
                      ]),
                    ),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }

  Widget _buildDoorPanel(bool isLeft) {
    final color = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.horizontal(
          left: Radius.circular(isLeft ? 12 : 0),
          right: Radius.circular(isLeft ? 0 : 12),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            color.surfaceVariant.withOpacity(0.9),
            color.surfaceContainerHigh,
          ],
        ),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.10), blurRadius: 6, offset: const Offset(0, 2)),
        ],
        border: Border.all(color: color.outlineVariant),
      ),
      child: Align(
        alignment: isLeft ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          width: 6,
          height: 42,
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: color.outlineVariant,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
      ),
    );
  }

  Widget _buildShelfTap(int level, ColorScheme color, Map<String, int> counts) {
    return Positioned.fill(
      child: LayoutBuilder(builder: (context, constraints) {
        final height = constraints.maxHeight;
        final top = height * (0.22 + level * 0.10);
        final shelfHeight = height * 0.08;
        return Positioned(
          left: 12,
          right: 12,
          top: top,
          height: shelfHeight,
          child: GestureDetector(
            onTap: () => widget.onSectionTap(FridgeCompartment.refrigerator, level),
            child: Container(
              decoration: BoxDecoration(
                color: color.surface.withOpacity(0.02),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Stack(children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Text('冷蔵室 棚$level', style: TextStyle(color: color.onSurfaceVariant)),
                  ),
                ),
                Positioned.fill(child: _buildBadge(counts, FridgeCompartment.refrigerator, level, color)),
              ]),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildDrawer({
    required double topFactor,
    required double heightFactor,
    required AnimationController controller,
    required ColorScheme color,
    required String semanticsLabel,
    required VoidCallback onTap,
    required Widget badge,
  }) {
    return Positioned.fill(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight * heightFactor;
          final top = constraints.maxHeight * topFactor;
          final offsetY = Tween<double>(begin: 0.0, end: -constraints.maxHeight * 0.22)
              .chain(CurveTween(curve: Curves.easeOut))
              .animate(controller);
          return AnimatedBuilder(
            animation: controller,
            builder: (context, _) {
              return Stack(children: [
                Positioned(
                  left: 12,
                  top: top + offsetY.value,
                  width: width - 24,
                  height: height,
                  child: Semantics(
                    label: semanticsLabel,
                    value: controller.value > 0.01 ? '開' : '閉',
                    button: true,
                    child: GestureDetector(
                      onTap: onTap,
                      onDoubleTap: () {
                        if (semanticsLabel == '野菜室') {
                          widget.onSectionTap(FridgeCompartment.vegetableDrawer, 0);
                        } else {
                          widget.onSectionTap(FridgeCompartment.freezer, 0);
                        }
                      },
                      child: Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              color.surfaceContainerHighest,
                              color.surfaceContainerHigh,
                            ],
                          ),
                          border: Border.all(color: color.outlineVariant),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 8, offset: const Offset(0, 3)),
                          ],
                        ),
                        child: Stack(children: [
                          Align(
                            alignment: Alignment.topCenter,
                            child: Container(
                              width: 48,
                              height: 4,
                              margin: const EdgeInsets.only(top: 8),
                              decoration: BoxDecoration(
                                color: color.outlineVariant,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
                          ),
                          Positioned.fill(child: badge),
                        ]),
                      ),
                    ),
                  ),
                ),
              ]);
            },
          );
        },
      ),
    );
  }
}


