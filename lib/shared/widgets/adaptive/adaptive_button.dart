import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

enum AdaptiveButtonStyle {
  primary,
  secondary,
  outlined,
}

/// プラットフォームに応じて適応するボタン
class AdaptiveButton extends StatelessWidget {
  const AdaptiveButton({
    Key? key,
    required this.onPressed,
    this.style = AdaptiveButtonStyle.primary,
    required this.child,
  }) : super(key: key);

  final VoidCallback? onPressed;
  final AdaptiveButtonStyle style;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS) {
      return _buildCupertinoButton(context);
    } else {
      return _buildMaterialButton(context);
    }
  }

  Widget _buildCupertinoButton(BuildContext context) {
    switch (style) {
      case AdaptiveButtonStyle.primary:
        return CupertinoButton.filled(
          onPressed: onPressed,
          child: child,
        );
      case AdaptiveButtonStyle.secondary:
        return CupertinoButton(
          onPressed: onPressed,
          color: CupertinoColors.systemGrey.resolveFrom(context),
          child: child,
        );
      case AdaptiveButtonStyle.outlined:
        return CupertinoButton(
          onPressed: onPressed,
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.activeBlue.resolveFrom(context),
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: child,
          ),
        );
    }
  }

  Widget _buildMaterialButton(BuildContext context) {
    switch (style) {
      case AdaptiveButtonStyle.primary:
        return ElevatedButton(
          onPressed: onPressed,
          child: child,
        );
      case AdaptiveButtonStyle.secondary:
        return FilledButton.tonal(
          onPressed: onPressed,
          child: child,
        );
      case AdaptiveButtonStyle.outlined:
        return OutlinedButton(
          onPressed: onPressed,
          child: child,
        );
    }
  }
}