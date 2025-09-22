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
          children: [
            for (final placement in placements)
              Positioned(
                left: placement.position.dx,
                top: placement.position.dy,
                width: placement.size.width,
                height: placement.size.height,
                child: FoodCharacterWidget(
                  placement: placement,
                  onTap: () => onTapProduct(placement.product),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
