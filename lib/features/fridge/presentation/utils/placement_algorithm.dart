import 'dart:math' as math;
import 'dart:ui';

/// Calculates non-overlapping positions for product characters within a section.
class PlacementAlgorithm {
  PlacementAlgorithm({math.Random? random}) : _random = random ?? math.Random();

  final math.Random _random;

  /// Space kept between character widgets when checking for collisions.
  static const double _collisionPadding = 6.0;
  static const int _maxRandomAttempts = 24;

  /// Returns a position inside [sectionBounds] that avoids overlapping [occupiedSpaces].
  ///
  /// If no free slot is found after several attempts the algorithm falls back to a
  /// lightweight grid layout to guarantee a deterministic placement.
  Offset placeProduct({
    required Rect sectionBounds,
    required Size itemSize,
    required List<Rect> occupiedSpaces,
    Offset? preferredNormalizedPosition,
  }) {
    final width = sectionBounds.width - itemSize.width;
    final height = sectionBounds.height - itemSize.height;

    // Degenerate scenarios: section smaller than item.
    if (width <= 0 || height <= 0) {
      return Offset(
        sectionBounds.left + (math.max(0.0, width) / 2),
        sectionBounds.top + (math.max(0.0, height) / 2),
      );
    }

    // Use stored normalized position when available.
    if (preferredNormalizedPosition != null) {
      final candidate = Offset(
        sectionBounds.left +
            preferredNormalizedPosition.dx.clamp(0.0, 1.0) * width,
        sectionBounds.top +
            preferredNormalizedPosition.dy.clamp(0.0, 1.0) * height,
      );
      final candidateRect = _rectFromOffset(candidate, itemSize);
      if (!_hasCollision(candidateRect, occupiedSpaces)) {
        return candidate;
      }
    }

    // Try random placements
    for (var i = 0; i < _maxRandomAttempts; i++) {
      final candidate = Offset(
        sectionBounds.left + _random.nextDouble() * width,
        sectionBounds.top + _random.nextDouble() * height,
      );
      final candidateRect = _rectFromOffset(candidate, itemSize);
      if (!_hasCollision(candidateRect, occupiedSpaces)) {
        return candidate;
      }
    }

    // Fallback to grid scan to guarantee a placement.
    return _fallbackGrid(
        sectionBounds: sectionBounds,
        itemSize: itemSize,
        occupiedSpaces: occupiedSpaces);
  }

  bool _hasCollision(Rect candidate, List<Rect> occupiedSpaces) {
    final expandedCandidate = candidate.inflate(_collisionPadding);
    for (final rect in occupiedSpaces) {
      if (expandedCandidate.overlaps(rect.inflate(_collisionPadding))) {
        return true;
      }
    }
    return false;
  }

  Offset _fallbackGrid({
    required Rect sectionBounds,
    required Size itemSize,
    required List<Rect> occupiedSpaces,
  }) {
    final horizontalPitch = itemSize.width + _collisionPadding;
    final verticalPitch = itemSize.height + _collisionPadding;

    final cols = math.max((sectionBounds.width / horizontalPitch).floor(), 1);
    final rows = math.max((sectionBounds.height / verticalPitch).floor(), 1);

    for (var row = 0; row < rows; row++) {
      for (var col = 0; col < cols; col++) {
        final offset = Offset(
          sectionBounds.left + col * horizontalPitch,
          sectionBounds.top + row * verticalPitch,
        );
        final candidateRect = _rectFromOffset(offset, itemSize);
        if (!_hasCollision(candidateRect, occupiedSpaces)) {
          return offset;
        }
      }
    }

    // As ultimate fallback place in centre.
    return Offset(
      sectionBounds.left + (sectionBounds.width - itemSize.width) / 2,
      sectionBounds.top + (sectionBounds.height - itemSize.height) / 2,
    );
  }

  Rect _rectFromOffset(Offset offset, Size size) {
    return Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height);
  }
}
