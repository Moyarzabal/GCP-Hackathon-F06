import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;
import '../providers/fridge_view_provider.dart';

class FridgeOverviewWidget extends ConsumerWidget {
  final void Function(FridgeCompartment compartment, int level) onSectionTap;

  const FridgeOverviewWidget({
    super.key,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = Theme.of(context).colorScheme;
    final counts = ref.watch(sectionCountsProvider);

    return AspectRatio(
      aspectRatio: 9 / 16,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth;
          final height = constraints.maxHeight;

          Widget badge(FridgeCompartment c, int level) {
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
                child: Text(
                  '$count',
                  style: TextStyle(color: color.onTertiary, fontSize: 11, fontWeight: FontWeight.bold),
                ),
              ),
            );
          }

          return Stack(
            children: [
              // 背景（冷蔵庫外枠）
              Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: color.outlineVariant),
                  color: color.surfaceContainerHighest,
                ),
              ),

              // 上段：両開きドアポケット（左/右）
              Positioned(
                left: 0,
                top: 0,
                width: width / 2,
                height: height * 0.18,
                child: _tapArea(context,
                  label: '左ドア',
                  onTap: () => onSectionTap(FridgeCompartment.doorLeft, 0),
                  child: badge(FridgeCompartment.doorLeft, 0),
                ),
              ),
              Positioned(
                left: width / 2,
                top: 0,
                width: width / 2,
                height: height * 0.18,
                child: _tapArea(context,
                  label: '右ドア',
                  onTap: () => onSectionTap(FridgeCompartment.doorRight, 0),
                  child: badge(FridgeCompartment.doorRight, 0),
                ),
              ),

              // 中央上：冷蔵室 棚レベル0..2（簡易3段）
              for (var i = 0; i < 3; i++)
                Positioned(
                  left: 12,
                  right: 12,
                  top: height * (0.22 + i * 0.10),
                  height: height * 0.08,
                  child: _tapArea(context,
                    label: '冷蔵室 棚$i',
                    onTap: () => onSectionTap(FridgeCompartment.refrigerator, i),
                    child: badge(FridgeCompartment.refrigerator, i),
                  ),
                ),

              // 中央下：野菜室
              Positioned(
                left: 12,
                right: 12,
                top: height * 0.68,
                height: height * 0.10,
                child: _tapArea(context,
                  label: '野菜室',
                  onTap: () => onSectionTap(FridgeCompartment.vegetableDrawer, 0),
                  child: badge(FridgeCompartment.vegetableDrawer, 0),
                ),
              ),

              // 下段：冷凍庫
              Positioned(
                left: 12,
                right: 12,
                top: height * 0.85,
                height: height * 0.10,
                child: _tapArea(context,
                  label: '冷凍庫',
                  onTap: () => onSectionTap(FridgeCompartment.freezer, 0),
                  child: badge(FridgeCompartment.freezer, 0),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _tapArea(BuildContext context, {required String label, required VoidCallback onTap, Widget? child}) {
    final color = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.surfaceContainerHigh,
          border: Border.all(color: color.outlineVariant),
        ),
        child: Stack(
          children: [
            Center(child: Text(label, style: TextStyle(color: color.onSurfaceVariant))),
            if (child != null) child,
          ],
        ),
      ),
    );
  }
}


