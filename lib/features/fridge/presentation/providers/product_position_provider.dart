import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../shared/models/product.dart';
import '../../../../shared/providers/app_state_provider.dart';
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
      : _boundsCalculator = const SectionBoundsCalculator(),
        super(const {}) {
    _products = _ref.read(productsProvider);

    final sub = _ref.listen<List<Product>>(productsProvider, (previous, next) {
      _products = next;
      _recalculate();
    });

    _ref.onDispose(sub.close);
  }

  final Ref _ref;
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
    final Map<String, _SectionLayoutContext> sections = {};

    for (final product in _products.where((p) => p.deletedAt == null)) {
      final location = product.location ??
          const ProductLocation(
            compartment: FridgeCompartment.refrigerator,
            level: 0,
          );

      final key = _sectionKey(location.compartment, location.level);
      final context = sections.putIfAbsent(
        key,
        () {
          final bounds = _boundsCalculator.getBounds(
            compartment: location.compartment,
            level: location.level,
            widgetSize: size,
            perspective: _perspective,
          );

          return _SectionLayoutContext(
            compartment: location.compartment,
            level: location.level,
            bounds: bounds,
            baseItemSize: _characterSizeForCompartment(location.compartment),
          );
        },
      );

      if (context.products.length >= _sectionLimit) {
        continue;
      }

      context.products.add(product);
    }

    final Map<String, ProductCharacterPlacement> placements = {};

    for (final context in sections.values) {
      final arranged = _layoutSection(context);
      for (final placed in arranged) {
        placements[placed.product.id ?? placed.product.name] =
            ProductCharacterPlacement(
          product: placed.product,
          position: placed.offset,
          size: placed.size,
          sectionBounds: context.bounds,
          compartment: context.compartment,
          level: context.level,
        );
      }
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

List<_PlannedPlacement> _layoutSection(_SectionLayoutContext context) {
  final products = List<Product>.of(context.products)
    ..sort(_compareProductDisplayOrder);

  if (products.isEmpty) {
    return const [];
  }

  final Rect bounds = context.bounds;
  final Size baseSize = context.baseItemSize;
  final double availableWidth = bounds.width;
  final double availableHeight = bounds.height;

  const double minScale = 0.45;
  const double scaleStep = 0.1;

  for (double scale = 1.0; scale >= minScale; scale -= scaleStep) {
    final Size itemSize = Size(baseSize.width * scale, baseSize.height * scale);
    final double verticalGap = (itemSize.height * 0.28).clamp(6.0, 18.0);
    final double minHorizontalGap = math.max(6.0, itemSize.width * 0.12);
    final double maxHorizontalGap = math.max(minHorizontalGap + 6.0, itemSize.width * 0.35);

    final int maxColumns = math.max(
      1,
      ((availableWidth + minHorizontalGap) /
              (itemSize.width + minHorizontalGap))
          .floor(),
    );

    for (int columns = math.min(products.length, maxColumns);
        columns >= 1;
        columns--) {
      final int rows = (products.length / columns).ceil();
      final double totalHeight =
          rows * itemSize.height + (rows - 1) * verticalGap;
      if (totalHeight > availableHeight + 0.1) {
        continue;
      }

      final rowsList = _splitIntoRows(products, columns);
      final List<_PlannedPlacement> placements = [];
      final double baseTop = bounds.bottom - itemSize.height;

      for (int rowIndex = 0; rowIndex < rowsList.length; rowIndex++) {
        final List<Product> rowItems = rowsList[rowsList.length - 1 - rowIndex];
        final double gap = _horizontalGapForRow(
          availableWidth: availableWidth,
          itemWidth: itemSize.width,
          itemCount: rowItems.length,
          minGap: minHorizontalGap,
          maxGap: maxHorizontalGap,
        );

        final double top =
            baseTop - rowIndex * (itemSize.height + verticalGap);

        for (int columnIndex = 0; columnIndex < rowItems.length; columnIndex++) {
          final Product product = rowItems[columnIndex];
          final double left =
              bounds.left + columnIndex * (itemSize.width + gap);

          placements.add(
            _PlannedPlacement(
              product: product,
              offset: Offset(left, top),
              size: itemSize,
            ),
          );
        }
      }

      return placements;
    }
  }

  // Fallback: use the smallest scale and stack vertically with consistent spacing.
  final Size fallbackSize = Size(
    baseSize.width * minScale,
    baseSize.height * minScale,
  );
  final double verticalGap = (fallbackSize.height * 0.2).clamp(6.0, 14.0);
  final double baseTop = bounds.bottom - fallbackSize.height;

  final List<_PlannedPlacement> placements = [];
  for (int index = products.length - 1, row = 0; index >= 0; index--, row++) {
    final double top = baseTop - row * (fallbackSize.height + verticalGap);
    placements.add(
      _PlannedPlacement(
        product: products[index],
        offset: Offset(bounds.left, top),
        size: fallbackSize,
      ),
    );
  }

  return placements;
}

int _compareProductDisplayOrder(Product a, Product b) {
  final Offset? posA = a.location?.position;
  final Offset? posB = b.location?.position;

  if (posA != null && posB != null) {
    final int dy = posA.dy.compareTo(posB.dy);
    if (dy != 0) {
      return dy;
    }
    final int dx = posA.dx.compareTo(posB.dx);
    if (dx != 0) {
      return dx;
    }
  } else if (posA != null) {
    return -1;
  } else if (posB != null) {
    return 1;
  }

  final DateTime aExpiry = a.expiryDate ?? DateTime(9999, 1, 1);
  final DateTime bExpiry = b.expiryDate ?? DateTime(9999, 1, 1);
  final int expiryCompare = aExpiry.compareTo(bExpiry);
  if (expiryCompare != 0) {
    return expiryCompare;
  }

  return (a.id ?? a.name).compareTo(b.id ?? b.name);
}

List<List<Product>> _splitIntoRows(List<Product> products, int columns) {
  final List<List<Product>> rows = [];
  for (int index = 0; index < products.length; index += columns) {
    rows.add(
      products.sublist(
        index,
        math.min(products.length, index + columns),
      ),
    );
  }
  return rows;
}

double _horizontalGapForRow({
  required double availableWidth,
  required double itemWidth,
  required int itemCount,
  required double minGap,
  required double maxGap,
}) {
  if (itemCount <= 1) {
    return 0.0;
  }

  final double remaining = availableWidth - itemCount * itemWidth;
  if (remaining <= 0) {
    return 0.0;
  }

  final double automaticGap = remaining / (itemCount - 1);
  return math.min(maxGap, math.max(minGap, automaticGap));
}

class _SectionLayoutContext {
  _SectionLayoutContext({
    required this.compartment,
    required this.level,
    required this.bounds,
    required this.baseItemSize,
  });

  final FridgeCompartment compartment;
  final int level;
  final Rect bounds;
  final Size baseItemSize;
  final List<Product> products = [];
}

class _PlannedPlacement {
  const _PlannedPlacement({
    required this.product,
    required this.offset,
    required this.size,
  });

  final Product product;
  final Offset offset;
  final Size size;
}

final productPositionProvider = StateNotifierProvider<ProductPositionNotifier,
    Map<String, ProductCharacterPlacement>>((ref) {
  return ProductPositionNotifier(ref);
});
