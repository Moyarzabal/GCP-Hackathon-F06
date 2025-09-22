import 'dart:ui';

import '../../../../shared/models/product.dart';

enum FridgeViewPerspective { front, top }

/// Calculates visual bounds for each fridge section inside the layered fridge widget.
///
/// The math mirrors the layout logic in `Layered3DFridgeWidget` (front view) and
/// `TopViewFridgeWidget` (top view) so that character overlays line up with the
/// painted shelves, drawers, and doors.
class SectionBoundsCalculator {
  const SectionBoundsCalculator();

  /// Padding applied inside each section to keep characters away from edges.
  static const double _inset = 8.0;

  /// Returns an absolute [Rect] in the coordinate space of the layered fridge widget.
  Rect getBounds({
    required FridgeCompartment compartment,
    required int level,
    required Size widgetSize,
    FridgeViewPerspective perspective = FridgeViewPerspective.front,
  }) {
    if (perspective == FridgeViewPerspective.top) {
      return _topViewBounds(
        compartment: compartment,
        level: level,
        widgetSize: widgetSize,
      );
    }

    final fridgeBodyLeft = widgetSize.width * 0.1;
    final fridgeBodyWidth = widgetSize.width * 0.8;
    final fridgeBodyTop = widgetSize.height * 0.02;
    final fridgeBodyHeight = widgetSize.height * 0.95;

    switch (compartment) {
      case FridgeCompartment.refrigerator:
        return _refrigeratorShelfBounds(
          level: level,
          fridgeBodyLeft: fridgeBodyLeft,
          fridgeBodyTop: fridgeBodyTop,
          fridgeBodyWidth: fridgeBodyWidth,
          fridgeBodyHeight: fridgeBodyHeight,
        );
      case FridgeCompartment.vegetableDrawer:
        return _drawerBounds(
          fridgeBodyLeft: fridgeBodyLeft,
          fridgeBodyTop: fridgeBodyTop,
          fridgeBodyWidth: fridgeBodyWidth,
          fridgeBodyHeight: fridgeBodyHeight,
          isVegetable: true,
        );
      case FridgeCompartment.freezer:
        return _drawerBounds(
          fridgeBodyLeft: fridgeBodyLeft,
          fridgeBodyTop: fridgeBodyTop,
          fridgeBodyWidth: fridgeBodyWidth,
          fridgeBodyHeight: fridgeBodyHeight,
          isVegetable: false,
        );
      case FridgeCompartment.doorLeft:
        return _doorBounds(
          widgetSize: widgetSize,
          isLeft: true,
        );
      case FridgeCompartment.doorRight:
        return _doorBounds(
          widgetSize: widgetSize,
          isLeft: false,
        );
    }
  }

  Rect _topViewBounds({
    required FridgeCompartment compartment,
    required int level,
    required Size widgetSize,
  }) {
    switch (compartment) {
      case FridgeCompartment.vegetableDrawer:
      case FridgeCompartment.freezer:
        return _topViewDrawerBounds(widgetSize: widgetSize);
      case FridgeCompartment.refrigerator:
      case FridgeCompartment.doorLeft:
      case FridgeCompartment.doorRight:
        final padding = widgetSize.shortestSide * 0.1;
        return Rect.fromLTWH(
          _inset + padding,
          _inset + padding,
          widgetSize.width - ((_inset + padding) * 2),
          widgetSize.height - ((_inset + padding) * 2),
        );
    }
  }

  Rect _refrigeratorShelfBounds({
    required int level,
    required double fridgeBodyLeft,
    required double fridgeBodyTop,
    required double fridgeBodyWidth,
    required double fridgeBodyHeight,
  }) {
    // Shelves occupy 55% of the fridge height in the layered widget.
    final shelfAreaHeight = fridgeBodyHeight * 0.55;
    final clampedLevel = level.clamp(0, 2);
    final shelfHeight = shelfAreaHeight / 3;
    final shelfTop = fridgeBodyTop + shelfHeight * clampedLevel;

    return Rect.fromLTWH(
      fridgeBodyLeft + _inset,
      shelfTop + _inset,
      fridgeBodyWidth - (_inset * 2),
      shelfHeight - (_inset * 2),
    );
  }

  Rect _drawerBounds({
    required double fridgeBodyLeft,
    required double fridgeBodyTop,
    required double fridgeBodyWidth,
    required double fridgeBodyHeight,
    required bool isVegetable,
  }) {
    // Drawers live below the main shelves: remaining 45% split into two equal drawers.
    final topSectionHeight = fridgeBodyHeight * 0.55;
    final sectionsStartY = fridgeBodyTop + topSectionHeight;
    final sectionsHeight = fridgeBodyHeight * 0.45;
    final drawerHeight = sectionsHeight * 0.5;
    final top = isVegetable ? sectionsStartY : sectionsStartY + drawerHeight;

    return Rect.fromLTWH(
      fridgeBodyLeft + _inset,
      top + _inset,
      fridgeBodyWidth - (_inset * 2),
      drawerHeight - (_inset * 2),
    );
  }

  Rect _doorBounds({
    required Size widgetSize,
    required bool isLeft,
  }) {
    final fridgeBodyLeft = widgetSize.width * 0.1;
    final fridgeBodyWidth = widgetSize.width * 0.8;
    final fridgeBodyTop = widgetSize.height * 0.02;
    final fridgeBodyHeight =
        widgetSize.height * 0.55; // doors cover same as top shelves

    final doorWidth = fridgeBodyWidth * 0.5;
    final doorLeft = isLeft ? fridgeBodyLeft : fridgeBodyLeft + doorWidth;

    return Rect.fromLTWH(
      doorLeft + _inset,
      fridgeBodyTop + _inset,
      doorWidth - (_inset * 2),
      fridgeBodyHeight - (_inset * 2),
    );
  }

  Rect _topViewDrawerBounds({
    required Size widgetSize,
  }) {
    final drawerWidth = widgetSize.width * 0.85;
    final drawerHeight = widgetSize.height * 0.45;
    final drawerLeft = (widgetSize.width - drawerWidth) / 2;
    final drawerTop = widgetSize.height * 0.275;

    return Rect.fromLTWH(
      drawerLeft + _inset,
      drawerTop + _inset,
      drawerWidth - (_inset * 2),
      drawerHeight - (_inset * 2),
    );
  }
}
