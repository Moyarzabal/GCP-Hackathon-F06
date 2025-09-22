import 'package:flutter/material.dart';

import 'package:barcode_scanner/shared/models/product.dart';
import '../../providers/product_position_provider.dart';
import 'food_character_widget.dart';

class DoorCharactersLayer extends StatelessWidget {
  const DoorCharactersLayer({
    super.key,
    required this.placements,
    required this.leftDoorProgress,
    required this.rightDoorProgress,
    required this.onTapProduct,
  });

  final Iterable<ProductCharacterPlacement> placements;
  final double leftDoorProgress;
  final double rightDoorProgress;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    final leftItems = placements
        .where(
            (placement) => placement.compartment == FridgeCompartment.doorLeft)
        .toList();
    final rightItems = placements
        .where(
            (placement) => placement.compartment == FridgeCompartment.doorRight)
        .toList();

    if (leftItems.isEmpty && rightItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Stack(
      children: [
        _DoorGroup(
          placements: leftItems,
          visibility: leftDoorProgress,
          onTapProduct: onTapProduct,
        ),
        _DoorGroup(
          placements: rightItems,
          visibility: rightDoorProgress,
          onTapProduct: onTapProduct,
        ),
      ],
    );
  }
}

class _DoorGroup extends StatelessWidget {
  const _DoorGroup({
    required this.placements,
    required this.visibility,
    required this.onTapProduct,
  });

  final List<ProductCharacterPlacement> placements;
  final double visibility;
  final ValueChanged<Product> onTapProduct;

  @override
  Widget build(BuildContext context) {
    if (placements.isEmpty) {
      return const SizedBox.shrink();
    }

    final clampedOpacity = visibility.clamp(0.0, 1.0);
    final interactive = clampedOpacity > 0.2;

    return IgnorePointer(
      ignoring: !interactive,
      child: AnimatedOpacity(
        opacity: clampedOpacity,
        duration: const Duration(milliseconds: 180),
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
