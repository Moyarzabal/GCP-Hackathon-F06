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
          child: Container(
            width: double.infinity,
            child: Center(child: child),
          ),
        );
      case AdaptiveButtonStyle.secondary:
        return CupertinoButton(
          onPressed: onPressed,
          color: CupertinoColors.systemGrey5.resolveFrom(context),
          child: Container(
            width: double.infinity,
            child: Center(child: child),
          ),
        );
      case AdaptiveButtonStyle.outlined:
        return GestureDetector(
          onTap: onPressed,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              border: Border.all(
                color: CupertinoColors.activeBlue.resolveFrom(context),
                width: 2,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(child: child),
          ),
        );
    }
  }

  Widget _buildMaterialButton(BuildContext context) {
    switch (style) {
      case AdaptiveButtonStyle.primary:
        return SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: onPressed,
            child: child,
          ),
        );
      case AdaptiveButtonStyle.secondary:
        return SizedBox(
          width: double.infinity,
          child: FilledButton.tonal(
            onPressed: onPressed,
            style: FilledButton.styleFrom(
              backgroundColor: Colors.grey.shade200,
              foregroundColor: Colors.grey.shade800,
            ),
            child: child,
          ),
        );
      case AdaptiveButtonStyle.outlined:
        return SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: onPressed,
            child: child,
          ),
        );
    }
  }
}