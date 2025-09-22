import 'package:flutter/material.dart';

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
    final borderColor = product.statusColor;

    final character = Container(
      width: placement.size.width,
      height: placement.size.height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor.withOpacity(0.5), width: 2),
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: borderColor.withOpacity(0.25),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return _FallbackAvatar(text: product.name);
                        },
                      )
                    : _FallbackAvatar(text: product.name),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              product.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: Colors.grey[800],
                  ),
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
