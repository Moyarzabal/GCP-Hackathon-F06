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

    // 冷蔵庫の商品を3段にバランス良く分散配置する
    final fridgeProducts = _products
        .where((p) => p.deletedAt == null)
        .where((p) =>
            p.location?.compartment == FridgeCompartment.refrigerator ||
            p.location?.compartment == null)
        .toList();

    // 冷蔵庫商品を3段に分散
    _distributeFridgeProducts(fridgeProducts, sections, size);

    // 冷蔵庫以外の商品は従来通りの処理
    for (final product in _products.where((p) =>
        p.deletedAt == null &&
        p.location?.compartment != FridgeCompartment.refrigerator &&
        p.location?.compartment != null)) {

      final location = product.location!;
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

  /// 冷蔵庫商品を3段にバランス良く分散配置する
  void _distributeFridgeProducts(
    List<Product> fridgeProducts,
    Map<String, _SectionLayoutContext> sections,
    Size size,
  ) {
    if (fridgeProducts.isEmpty) return;

    // 商品を賞味期限順にソート（期限が近いものから上段に配置）
    fridgeProducts.sort((a, b) {
      final aExpiry = a.expiryDate ?? DateTime(9999, 1, 1);
      final bExpiry = b.expiryDate ?? DateTime(9999, 1, 1);
      return aExpiry.compareTo(bExpiry);
    });

    // 各段の最大容量を計算（1段あたり約3-4個を目安）
    const maxItemsPerLevel = 4;
    final totalLevels = 3; // 冷蔵庫は3段

    // 商品を3段に分散配置
    for (int i = 0; i < fridgeProducts.length; i++) {
      final product = fridgeProducts[i];

      // 賞味期限が近いものほど上段（level 0）に配置
      // 商品数に応じてバランス良く分散
      int targetLevel;
      if (fridgeProducts.length <= maxItemsPerLevel) {
        // 少数の場合は全て上段
        targetLevel = 0;
      } else {
        // 商品を3段に均等分散（ただし賞味期限順を考慮）
        final levelGroup = (i * totalLevels) ~/ fridgeProducts.length;
        targetLevel = levelGroup.clamp(0, totalLevels - 1);
      }

      final key = _sectionKey(FridgeCompartment.refrigerator, targetLevel);
      final context = sections.putIfAbsent(
        key,
        () {
          final bounds = _boundsCalculator.getBounds(
            compartment: FridgeCompartment.refrigerator,
            level: targetLevel,
            widgetSize: size,
            perspective: _perspective,
          );

          return _SectionLayoutContext(
            compartment: FridgeCompartment.refrigerator,
            level: targetLevel,
            bounds: bounds,
            baseItemSize: _characterSizeForCompartment(FridgeCompartment.refrigerator),
          );
        },
      );

      // 段の容量制限チェック
      if (context.products.length >= _sectionLimit) {
        // この段が満杯の場合、次の段を試す
        for (int nextLevel = 0; nextLevel < totalLevels; nextLevel++) {
          if (nextLevel == targetLevel) continue;

          final nextKey = _sectionKey(FridgeCompartment.refrigerator, nextLevel);
          final nextContext = sections.putIfAbsent(
            nextKey,
            () {
              final bounds = _boundsCalculator.getBounds(
                compartment: FridgeCompartment.refrigerator,
                level: nextLevel,
                widgetSize: size,
                perspective: _perspective,
              );

              return _SectionLayoutContext(
                compartment: FridgeCompartment.refrigerator,
                level: nextLevel,
                bounds: bounds,
                baseItemSize: _characterSizeForCompartment(FridgeCompartment.refrigerator),
              );
            },
          );

          if (nextContext.products.length < _sectionLimit) {
            nextContext.products.add(product);
            break;
          }
        }
      } else {
        context.products.add(product);
      }
    }
  }
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
    final double minHorizontalGap = math.max(2.0, itemSize.width * 0.08);
    final double maxHorizontalGap =
        math.max(minHorizontalGap + 4.0, itemSize.width * 0.25);

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

        final double top = baseTop - rowIndex * (itemSize.height + verticalGap);

        // Center the row horizontally within available width
        final double totalRowWidth =
            rowItems.length * itemSize.width + (rowItems.length - 1) * gap;
        final double rowStartX =
            bounds.left + (availableWidth - totalRowWidth) / 2;

        for (int columnIndex = 0;
            columnIndex < rowItems.length;
            columnIndex++) {
          final Product product = rowItems[columnIndex];
          final double left = rowStartX + columnIndex * (itemSize.width + gap);

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

  // Fallback: arrange horizontally in a single row with minimal spacing
  final Size fallbackSize = Size(
    baseSize.width * minScale,
    baseSize.height * minScale,
  );

  final double minHorizontalGap = 2.0;
  final int maxItemsInRow =
      (availableWidth / (fallbackSize.width + minHorizontalGap)).floor();
  final int itemsToShow = math.min(products.length, maxItemsInRow);

  if (itemsToShow == 0) {
    return const [];
  }

  final double actualGap = itemsToShow <= 1
      ? 0.0
      : (availableWidth - itemsToShow * fallbackSize.width) / (itemsToShow - 1);
  final double clampedGap =
      actualGap.clamp(minHorizontalGap, availableWidth * 0.1);

  final double baseTop = bounds.bottom - fallbackSize.height;
  final List<_PlannedPlacement> placements = [];

  // Center the fallback row horizontally
  final double totalRowWidth =
      itemsToShow * fallbackSize.width + (itemsToShow - 1) * clampedGap;
  final double rowStartX = bounds.left + (availableWidth - totalRowWidth) / 2;

  for (int index = 0; index < itemsToShow; index++) {
    final double left = rowStartX + index * (fallbackSize.width + clampedGap);
    placements.add(
      _PlannedPlacement(
        product: products[index],
        offset: Offset(left, baseTop),
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
