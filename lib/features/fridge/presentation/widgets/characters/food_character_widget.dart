import 'package:flutter/material.dart';

import 'package:barcode_scanner/shared/models/product.dart';

import '../../providers/product_position_provider.dart';

class FoodCharacterWidget extends StatelessWidget {
  const FoodCharacterWidget({
    super.key,
    required this.placement,
    this.onTap,
  });

  final ProductCharacterPlacement placement;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final product = placement.product;
    final imageUrl = product.currentImageUrl;
    final stage = product.currentImageStage;
    final glowColor = _glowColorForStage(stage, product.statusColor);
    final glowStrength = _glowStrengthForStage(stage);
    final shouldDesaturate = _shouldDesaturate(stage);

    Widget characterImage;
    if (imageUrl != null) {
      characterImage = Image.network(
        imageUrl,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _FallbackAvatar(text: product.name);
        },
      );
    } else {
      characterImage = _FallbackAvatar(text: product.name);
    }

    if (shouldDesaturate) {
      characterImage = ColorFiltered(
        colorFilter: const ColorFilter.matrix(_greyscaleMatrix),
        child: characterImage,
      );
    }

    final character = SizedBox(
      width: placement.size.width,
      height: placement.size.height,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: placement.size.width,
            height: placement.size.height,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(_glowBorderRadius),
              boxShadow: _buildGlowShadows(glowColor, glowStrength),
            ),
          ),
          ClipRRect(
            borderRadius: BorderRadius.circular(_imageBorderRadius),
            child: SizedBox.expand(child: characterImage),
          ),
        ],
      ),
    );

    return Tooltip(
      message: '${product.name}\n残り${product.daysUntilExpiry}日',
      child: GestureDetector(
        onTap: onTap,
        child: character,
      ),
    );
  }
}

const double _imageBorderRadius = 18;
const double _glowBorderRadius = 22;

List<BoxShadow> _buildGlowShadows(Color glowColor, double strength) {
  final primaryOpacity = 0.55 * strength;
  final secondaryOpacity = 0.28 * strength;

  return [
    BoxShadow(
      color: glowColor.withOpacity(primaryOpacity.clamp(0, 1)),
      blurRadius: 12 + (4 * strength),
      spreadRadius: 2 + (2 * strength),
    ),
    BoxShadow(
      color: glowColor.withOpacity(secondaryOpacity.clamp(0, 1)),
      blurRadius: 18 + (6 * strength),
      spreadRadius: 4 + (3 * strength),
    ),
  ];
}

Color _glowColorForStage(ImageStage stage, Color baseColor) {
  switch (stage) {
    case ImageStage.veryFresh:
      return baseColor;
    case ImageStage.fresh:
      return baseColor;
    case ImageStage.warning:
      return const Color(0xFFf97316);
    case ImageStage.urgent:
      return const Color(0xFF9ca3af);
    case ImageStage.expired:
      return const Color(0xFF6b7280);
  }
}

double _glowStrengthForStage(ImageStage stage) {
  switch (stage) {
    case ImageStage.veryFresh:
      return 1.0;
    case ImageStage.fresh:
      return 0.85;
    case ImageStage.warning:
      return 0.7;
    case ImageStage.urgent:
      return 0.5;
    case ImageStage.expired:
      return 0.4;
  }
}

bool _shouldDesaturate(ImageStage stage) {
  return stage == ImageStage.urgent || stage == ImageStage.expired;
}

const List<double> _greyscaleMatrix = <double>[
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0.2126,
  0.7152,
  0.0722,
  0,
  0,
  0,
  0,
  0,
  1,
  0,
];

class _FallbackAvatar extends StatelessWidget {
  const _FallbackAvatar({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    final trimmed = text.trim();
    final label = trimmed.isEmpty ? '?' : trimmed[0];
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Text(
          label.toUpperCase(),
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.grey[600],
                fontWeight: FontWeight.bold,
              ),
        ),
      ),
    );
  }
}
