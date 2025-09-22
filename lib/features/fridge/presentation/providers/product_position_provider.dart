import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
import '../utils/placement_algorithm.dart';
import '../utils/section_bounds_calculator.dart';

/// Result of the placement calculation for a single product.
class ProductCharacterPlacement {
  const ProductCharacterPlacement({
    required this.product,
    required this.position,
    required this.size,
    required this.sectionBounds,
    required this.compartment,
    required this.level,
  });

  final Product product;
  final Offset position;
  final Size size;
  final Rect sectionBounds;
  final FridgeCompartment compartment;
  final int level;

  /// Normalised position (0..1) within the section, useful when persisting.
  Offset get normalizedPosition {
    final width = sectionBounds.width - size.width;
    final height = sectionBounds.height - size.height;
    if (width <= 0 || height <= 0) {
      return const Offset(0.5, 0.5);
    }
    return Offset(
      (position.dx - sectionBounds.left) / width,
      (position.dy - sectionBounds.top) / height,
    );
  }
}

class ProductPositionNotifier
    extends StateNotifier<Map<String, ProductCharacterPlacement>> {
  ProductPositionNotifier(this._ref)
      : _placementAlgorithm = PlacementAlgorithm(),
        _boundsCalculator = const SectionBoundsCalculator(),
        super(const {}) {
    _products = _ref.read(productsProvider);

    final sub = _ref.listen<List<Product>>(productsProvider, (previous, next) {
      _products = next;
      _recalculate();
    });

    _ref.onDispose(sub.close);
  }

  final Ref _ref;
  final PlacementAlgorithm _placementAlgorithm;
  final SectionBoundsCalculator _boundsCalculator;

  Size? _fridgeSize;
  List<Product> _products = const [];
  FridgeViewPerspective _perspective = FridgeViewPerspective.front;

  static const int _sectionLimit = 10;
  static const Size _defaultCharacterSize = Size(60, 70);

  void updateFridgeSize(Size size) {
    // Recalculate only when the size meaningfully changes.
    if (_fridgeSize == size) return;
    _fridgeSize = size;
    _recalculate();
  }

  void updatePerspective(FridgeViewPerspective perspective) {
    if (_perspective == perspective) return;
    _perspective = perspective;
    _recalculate();
  }

  void _recalculate() {
    if (_fridgeSize == null) {
      state = const {};
      return;
    }

    final size = _fridgeSize!;
    final Map<String, ProductCharacterPlacement> placements = {};
    final Map<String, List<Rect>> occupiedBySection = {};

    for (final product in _products.where((p) => p.deletedAt == null)) {
      final location = product.location ??
          const ProductLocation(
            compartment: FridgeCompartment.refrigerator,
            level: 0,
          );

      final sectionKey = _sectionKey(location.compartment, location.level);
      final existingCount = placements.values
          .where((p) =>
              p.compartment == location.compartment &&
              p.level == location.level)
          .length;
      if (existingCount >= _sectionLimit) {
        continue;
      }

      final sectionBounds = _boundsCalculator.getBounds(
        compartment: location.compartment,
        level: location.level,
        widgetSize: size,
        perspective: _perspective,
      );

      final itemSize = _characterSizeForCompartment(location.compartment);
      final occupied = occupiedBySection.putIfAbsent(sectionKey, () => []);
      final preferred = location.position;
      final position = _placementAlgorithm.placeProduct(
        sectionBounds: sectionBounds,
        itemSize: itemSize,
        occupiedSpaces: occupied,
        preferredNormalizedPosition: preferred,
      );

      final placementRect = Rect.fromLTWH(
          position.dx, position.dy, itemSize.width, itemSize.height);
      occupied.add(placementRect);

      placements[product.id ?? product.name] = ProductCharacterPlacement(
        product: product,
        position: position,
        size: itemSize,
        sectionBounds: sectionBounds,
        compartment: location.compartment,
        level: location.level,
      );
    }

    state = placements;
  }

  Size _characterSizeForCompartment(FridgeCompartment compartment) {
    switch (compartment) {
      case FridgeCompartment.doorLeft:
      case FridgeCompartment.doorRight:
        return const Size(52, 60);
      case FridgeCompartment.vegetableDrawer:
      case FridgeCompartment.freezer:
        return const Size(68, 68);
      case FridgeCompartment.refrigerator:
      default:
        return _defaultCharacterSize;
    }
  }

  String _sectionKey(FridgeCompartment compartment, int level) =>
      '${compartment.name}::$level';
}

final productPositionProvider = StateNotifierProvider<ProductPositionNotifier,
    Map<String, ProductCharacterPlacement>>((ref) {
  return ProductPositionNotifier(ref);
});
