import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:barcode_scanner/shared/models/product.dart';
import '../../providers/product_position_provider.dart';
import 'food_character_widget.dart';

class DrawerCharactersLayer extends StatelessWidget {
  const DrawerCharactersLayer({
    super.key,
    required this.placements,
    required this.vegetableDrawerOpen,
    required this.freezerDrawerOpen,
    required this.onTapProduct,
  });

  final Iterable<ProductCharacterPlacement> placements;
  final bool vegetableDrawerOpen;
  final bool freezerDrawerOpen;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    final vegetableItems = placements
        .where((placement) =>
            placement.compartment == FridgeCompartment.vegetableDrawer)
        .toList();
    final freezerItems = placements
        .where(
            (placement) => placement.compartment == FridgeCompartment.freezer)
        .toList();

    if (vegetableItems.isEmpty && freezerItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _DrawerGroup(
          placements: vegetableItems,
          isVisible: vegetableDrawerOpen,
          onTapProduct: onTapProduct,
        ),
        _DrawerGroup(
          placements: freezerItems,
          isVisible: freezerDrawerOpen,
          onTapProduct: onTapProduct,
        ),
      ],
    );
  }
}

class _DrawerGroup extends StatelessWidget {
  const _DrawerGroup({
    required this.placements,
    required this.isVisible,
    required this.onTapProduct,
  });

  final List<ProductCharacterPlacement> placements;
  final bool isVisible;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    if (placements.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 220),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final layout in _arrangePlacements(placements))
              Positioned(
                left: layout.offset.dx,
                top: layout.offset.dy,
                width: layout.placement.size.width,
                height: layout.placement.size.height,
                child: FoodCharacterWidget(
                  placement: layout.placement,
                  onTap: () => onTapProduct(layout.placement.product),
                ),
              ),
          ],
        ),
      ),
    );
  }

  List<_ArrangedPlacement> _arrangePlacements(
      List<ProductCharacterPlacement> items) {
    if (items.isEmpty) {
      return const [];
    }

    final List<ProductCharacterPlacement> sorted = List.of(items)
      ..sort((a, b) {
        final dxCompare = a.position.dx.compareTo(b.position.dx);
        if (dxCompare != 0) {
          return dxCompare;
        }
        return (a.product.name).compareTo(b.product.name);
      });

    final Rect section = sorted.first.sectionBounds;
    final double itemWidth = sorted.first.size.width;
    final double itemHeight = sorted.first.size.height;
    final double availableWidth = section.width;

    const double minHorizontalGap = 10.0;
    const double maxHorizontalGap = 26.0;
    const double verticalGap = 12.0;

    // Determine how many columns fit while keeping the minimum gap.
    final int maxColumns = math.max(
      1,
      ((availableWidth + minHorizontalGap) / (itemWidth + minHorizontalGap))
          .floor(),
    );

    int columns = math.min(maxColumns, sorted.length);
    final int fullRows = sorted.length ~/ columns;
    final int remainder = sorted.length % columns;

    final List<_RowInfo> rows = [];
    int startIndex = 0;
    if (remainder > 0) {
      rows.add(_RowInfo(startIndex, remainder));
      startIndex += remainder;
    }
    for (var i = 0; i < fullRows; i++) {
      rows.add(_RowInfo(startIndex, columns));
      startIndex += columns;
    }

    // Lay out from bottom row upwards so the lowest row sits on the drawer floor.
    final List<_ArrangedPlacement> arranged = [];
    final double baseTop = section.bottom - itemHeight;

    for (var rowIndex = rows.length - 1; rowIndex >= 0; rowIndex--) {
      final _RowInfo row = rows[rowIndex];
      final List<ProductCharacterPlacement> rowItems = sorted
          .sublist(row.start, row.start + row.count);

      final int count = rowItems.length;
      final double gap = count <= 1
          ? 0.0
          : ((availableWidth - count * itemWidth) / (count - 1))
              .clamp(minHorizontalGap, maxHorizontalGap);
      final double rowContentWidth =
          count * itemWidth + (count - 1) * gap;
      final double startX = section.left +
          math.max(0.0, (availableWidth - rowContentWidth) / 2);
      final double top =
          baseTop - (rows.length - 1 - rowIndex) * (itemHeight + verticalGap);

      for (var i = 0; i < count; i++) {
        final double left = startX + i * (itemWidth + gap);
        arranged.add(
          _ArrangedPlacement(
            placement: rowItems[i],
            offset: Offset(left, top),
          ),
        );
      }
    }

    return arranged;
  }
}

class _ArrangedPlacement {
  const _ArrangedPlacement({
    required this.placement,
    required this.offset,
  });

  final ProductCharacterPlacement placement;
  final Offset offset;
}

class _RowInfo {
  const _RowInfo(this.start, this.count);

  final int start;
  final int count;
}
