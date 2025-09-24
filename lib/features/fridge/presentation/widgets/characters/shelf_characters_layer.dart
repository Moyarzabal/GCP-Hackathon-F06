import 'package:flutter/material.dart';

import 'package:barcode_scanner/shared/models/product.dart';
import '../../providers/product_position_provider.dart';
import 'food_character_widget.dart';

class ShelfCharactersLayer extends StatelessWidget {
  const ShelfCharactersLayer({
    super.key,
    required this.placements,
    required this.isVisible,
    required this.onTapProduct,
  });

  final Iterable<ProductCharacterPlacement> placements;
  final bool isVisible;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    final items = placements
        .where((placement) =>
            placement.compartment == FridgeCompartment.refrigerator)
        .toList();

    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: !isVisible,
      child: AnimatedOpacity(
        opacity: isVisible ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 250),
        child: Stack(
          children: [
            for (final placement in items)
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
