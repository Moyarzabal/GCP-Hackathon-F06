import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

/// プラットフォーム適応型のボタンウィジェット
class AdaptiveButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final Color? backgroundColor;
  final Color? textColor;
  final bool isPrimary;
  
  const AdaptiveButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.backgroundColor,
    this.textColor,
    this.isPrimary = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS) {
      return CupertinoButton(
        onPressed: isLoading ? null : onPressed,
        color: isPrimary ? backgroundColor : null,
        child: isLoading
            ? const CupertinoActivityIndicator()
            : Text(
                text,
                style: TextStyle(
                  color: textColor ?? (isPrimary ? Colors.white : CupertinoTheme.of(context).primaryColor),
                ),
              ),
      );
    }
    
    if (isPrimary) {
      return ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: textColor,
        ),
        child: isLoading
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2.0,
                  color: Colors.white,
                ),
              )
            : Text(text),
      );
    }
    
    return OutlinedButton(
      onPressed: isLoading ? null : onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: textColor,
        side: backgroundColor != null ? BorderSide(color: backgroundColor!) : null,
      ),
      child: isLoading
          ? SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2.0,
                color: textColor ?? Theme.of(context).primaryColor,
              ),
            )
          : Text(text),
    );
  }
}