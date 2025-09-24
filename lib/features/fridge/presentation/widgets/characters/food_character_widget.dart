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
    final shouldDesaturate = _shouldDesaturate(stage);

    Widget characterImage = _buildProductImage(imageUrl, product.name);

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
          Positioned.fill(
            child: FittedBox(
              fit: BoxFit.contain,
              child: characterImage,
            ),
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
    return Center(
      child: Text(
        label.toUpperCase(),
        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
          color: Colors.grey[600],
          fontWeight: FontWeight.bold,
          shadows: const [
            Shadow(
              offset: Offset(0, 1),
              blurRadius: 2,
              color: Colors.black26,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildProductImage(String? imageUrl, String productName) {
  if (imageUrl != null) {
    return Image.network(
      imageUrl,
      fit: BoxFit.contain,
      errorBuilder: (context, error, stackTrace) {
        return _FallbackAvatar(text: productName);
      },
    );
  }
  return _FallbackAvatar(text: productName);
}
