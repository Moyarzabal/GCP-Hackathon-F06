import 'package:flutter/material.dart';
import '../../../../shared/models/product.dart' show FridgeCompartment;

class FridgeOverviewWidget extends StatelessWidget {
  final void Function(FridgeCompartment compartment, int level) onSectionTap;

  const FridgeOverviewWidget({
    super.key,
    required this.onSectionTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme;
    return AspectRatio(
      aspectRatio: 9 / 16,
      child: Stack(
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
          _buildTapArea(
            context,
            left: 0,
            top: 0,
            right: MediaQuery.sizeOf(context).width / 2,
            heightRatio: 0.18,
            label: '左ドア',
            onTap: () => onSectionTap(FridgeCompartment.doorLeft, 0),
          ),
          _buildTapArea(
            context,
            left: MediaQuery.sizeOf(context).width / 2,
            top: 0,
            right: 0,
            heightRatio: 0.18,
            label: '右ドア',
            onTap: () => onSectionTap(FridgeCompartment.doorRight, 0),
          ),

          // 中央上：冷蔵室 棚レベル0..2（簡易3段）
          _shelf(context, index: 0, onTap: () => onSectionTap(FridgeCompartment.refrigerator, 0)),
          _shelf(context, index: 1, onTap: () => onSectionTap(FridgeCompartment.refrigerator, 1)),
          _shelf(context, index: 2, onTap: () => onSectionTap(FridgeCompartment.refrigerator, 2)),

          // 中央下：野菜室
          _drawer(context,
              alignment: 0.68,
              label: '野菜室',
              onTap: () => onSectionTap(FridgeCompartment.vegetableDrawer, 0)),

          // 下段：冷凍庫
          _drawer(context,
              alignment: 0.85,
              label: '冷凍庫',
              onTap: () => onSectionTap(FridgeCompartment.freezer, 0)),
        ],
      ),
    );
  }

  Widget _buildTapArea(
    BuildContext context, {
    required double left,
    required double top,
    required double right,
    required double heightRatio,
    required String label,
    required VoidCallback onTap,
  }) {
    final color = Theme.of(context).colorScheme;
    return Positioned(
      left: left,
      right: right,
      top: MediaQuery.sizeOf(context).height * top,
      height: MediaQuery.sizeOf(context).height * heightRatio,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.surfaceContainerHigh,
            border: Border.all(color: color.outlineVariant),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: color.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }

  Widget _shelf(BuildContext context, {required int index, required VoidCallback onTap}) {
    final color = Theme.of(context).colorScheme;
    final topRatio = 0.22 + index * 0.10;
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.sizeOf(context).height * topRatio,
      height: MediaQuery.sizeOf(context).height * 0.08,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            color: color.surface,
            border: Border.all(color: color.outlineVariant),
          ),
          child: Center(
            child: Text('冷蔵室 棚${index}', style: TextStyle(color: color.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }

  Widget _drawer(BuildContext context, {required double alignment, required String label, required VoidCallback onTap}) {
    final color = Theme.of(context).colorScheme;
    return Positioned(
      left: 12,
      right: 12,
      top: MediaQuery.sizeOf(context).height * alignment,
      height: MediaQuery.sizeOf(context).height * 0.10,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.surfaceContainerLow,
            border: Border.all(color: color.outlineVariant),
          ),
          child: Center(
            child: Text(label, style: TextStyle(color: color.onSurfaceVariant)),
          ),
        ),
      ),
    );
  }
}


