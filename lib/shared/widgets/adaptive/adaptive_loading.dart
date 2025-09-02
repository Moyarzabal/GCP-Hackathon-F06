import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

/// プラットフォーム適応型のローディングウィジェット
class AdaptiveLoading extends StatelessWidget {
  final Color? color;
  final double? size;
  
  const AdaptiveLoading({
    Key? key,
    this.color,
    this.size = 20.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS) {
      return CupertinoActivityIndicator(
        color: color ?? CupertinoTheme.of(context).primaryColor,
        radius: (size ?? 20.0) / 2,
      );
    }
    
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator(
        color: color,
        strokeWidth: 2.0,
      ),
    );
  }
}