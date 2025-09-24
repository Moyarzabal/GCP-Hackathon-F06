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
    this.isTopView = false,
  });

  final Iterable<ProductCharacterPlacement> placements;
  final bool vegetableDrawerOpen;
  final bool freezerDrawerOpen;
  final ValueChanged<Product> onTapProduct;
  final bool isTopView;

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
          isTopView: isTopView,
        ),
        _DrawerGroup(
          placements: freezerItems,
          isVisible: freezerDrawerOpen,
          onTapProduct: onTapProduct,
          isTopView: isTopView,
        ),
      ],
    );
  }
}

class _DrawerGroup extends StatefulWidget {
  const _DrawerGroup({
    required this.placements,
    required this.isVisible,
    required this.onTapProduct,
    this.isTopView = false,
  });

  final List<ProductCharacterPlacement> placements;
  final bool isVisible;
  final ValueChanged<Product> onTapProduct;
  final bool isTopView;

  @override
  State<_DrawerGroup> createState() => _DrawerGroupState();
}

class _DrawerGroupState extends State<_DrawerGroup> {
  bool _showCharacters = false;

  @override
  void initState() {
    super.initState();
    // TopView で最初から isVisible=true の場合は即座に表示
    if (widget.isTopView && widget.isVisible) {
      _showCharacters = true;
    }
  }

  @override
  void didUpdateWidget(_DrawerGroup oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 引き出しが開き始めたとき
    if (widget.isVisible && !oldWidget.isVisible) {
      if (widget.isTopView) {
        // TopView では引き出しアニメーションは既に完了しているため即座に表示
        _showCharacters = true;
      } else {
        // FrontView では引き出しアニメーション完了後にキャラクターを表示
        _showCharacters = false;
        // DrawerStateProvider と同じ timing: 600ms + 80ms
        Future.delayed(const Duration(milliseconds: 680), () {
          if (mounted && widget.isVisible) {
            setState(() {
              _showCharacters = true;
            });
          }
        });
      }
    }
    // 引き出しが閉じたとき
    else if (!widget.isVisible && oldWidget.isVisible) {
      _showCharacters = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.placements.isEmpty) {
      return const SizedBox.shrink();
    }

    return IgnorePointer(
      ignoring: !widget.isVisible,
      child: AnimatedOpacity(
        opacity: _showCharacters ? 1.0 : 0.0,
        duration: const Duration(milliseconds: 300),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (final placement in widget.placements)
              Positioned(
                left: placement.position.dx,
                top: placement.position.dy,
                width: placement.size.width,
                height: placement.size.height,
                child: FoodCharacterWidget(
                  placement: placement,
                  onTap: () => widget.onTapProduct(placement.product),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
