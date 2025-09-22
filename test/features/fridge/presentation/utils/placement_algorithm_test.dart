import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';

import 'package:barcode_scanner/features/fridge/presentation/utils/placement_algorithm.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PlacementAlgorithm', () {
    test('places products within bounds without collisions', () {
      final algorithm = PlacementAlgorithm(random: math.Random(1));
      final sectionBounds = Rect.fromLTWH(0, 0, 200, 150);
      final itemSize = const Size(40, 40);
      final occupied = <Rect>[];

      for (var i = 0; i < 5; i++) {
        final position = algorithm.placeProduct(
          sectionBounds: sectionBounds,
          itemSize: itemSize,
          occupiedSpaces: occupied,
        );
        final rect = Rect.fromLTWH(
            position.dx, position.dy, itemSize.width, itemSize.height);
        expect(sectionBounds.contains(rect.topLeft), isTrue);
        expect(sectionBounds.contains(rect.bottomRight), isTrue);
        for (final other in occupied) {
          expect(rect.overlaps(other), isFalse);
        }
        occupied.add(rect);
      }
    });

    test('falls back to center when bounds are too small', () {
      final algorithm = PlacementAlgorithm(random: math.Random(2));
      final sectionBounds = Rect.fromLTWH(10, 10, 20, 20);
      final itemSize = const Size(40, 40);

      final position = algorithm.placeProduct(
        sectionBounds: sectionBounds,
        itemSize: itemSize,
        occupiedSpaces: const [],
      );

      expect(position.dx, sectionBounds.left);
      expect(position.dy, sectionBounds.top);
    });
  });
}
