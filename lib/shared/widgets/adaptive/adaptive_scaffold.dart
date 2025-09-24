import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

/// プラットフォームに応じて適応するスキャフォールド
class AdaptiveScaffold extends StatelessWidget {
  const AdaptiveScaffold({
    Key? key,
    this.appBar,
    this.body,
    this.floatingActionButton,
    this.bottomNavigationBar,
    this.backgroundColor,
  }) : super(key: key);

  final PreferredSizeWidget? appBar;
  final Widget? body;
  final Widget? floatingActionButton;
  final Widget? bottomNavigationBar;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS) {
      return _buildCupertinoScaffold(context);
    } else {
      return _buildMaterialScaffold(context);
    }
  }

  Widget _buildCupertinoScaffold(BuildContext context) {
    return CupertinoPageScaffold(
      backgroundColor: backgroundColor ??
          CupertinoColors.systemBackground.resolveFrom(context),
      navigationBar: appBar is CupertinoNavigationBar
          ? appBar as CupertinoNavigationBar
          : null,
      child: Column(
        children: [
          if (appBar != null && appBar is! CupertinoNavigationBar) appBar!,
          Expanded(
            child: body ?? const SizedBox.shrink(),
          ),
          if (bottomNavigationBar != null) bottomNavigationBar!,
        ],
      ),
    );
  }

  Widget _buildMaterialScaffold(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      body: body,
      floatingActionButton: floatingActionButton,
      bottomNavigationBar: bottomNavigationBar,
      backgroundColor: backgroundColor,
    );
  }
}

/// プラットフォームに応じて適応するアプリバー
class AdaptiveAppBar extends StatelessWidget implements PreferredSizeWidget {
  const AdaptiveAppBar({
    Key? key,
    this.title,
    this.leading,
    this.actions,
    this.backgroundColor,
  }) : super(key: key);

  final Widget? title;
  final Widget? leading;
  final List<Widget>? actions;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    if (PlatformInfo.isIOS) {
      return CupertinoNavigationBar(
        middle: title,
        leading: leading,
        trailing: actions != null && actions!.isNotEmpty
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: actions!,
              )
            : null,
        backgroundColor: backgroundColor,
      );
    } else {
      return AppBar(
        title: title,
        leading: leading,
        actions: actions,
        backgroundColor: backgroundColor,
      );
    }
  }

  @override
  Size get preferredSize {
    if (PlatformInfo.isIOS) {
      return const Size.fromHeight(44.0); // CupertinoNavigationBarのデフォルト高さ
    } else {
      return const Size.fromHeight(kToolbarHeight);
    }
  }
}
