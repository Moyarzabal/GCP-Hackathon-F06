import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import '../../../core/platform/platform_info.dart';

/// アダプティブダイアログアクション
class AdaptiveDialogAction {
  const AdaptiveDialogAction({
    required this.text,
    required this.onPressed,
    this.isDefaultAction = false,
    this.isDestructiveAction = false,
  });

  final String text;
  final VoidCallback onPressed;
  final bool isDefaultAction;
  final bool isDestructiveAction;
}

/// プラットフォームに応じて適応するダイアログを表示
Future<T?> showCustomAdaptiveDialog<T>({
  required BuildContext context,
  required String title,
  String? content,
  List<AdaptiveDialogAction>? actions,
  bool barrierDismissible = true,
}) {
  if (PlatformInfo.isIOS) {
    return showCupertinoDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _CupertinoAdaptiveDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  } else {
    return showDialog<T>(
      context: context,
      barrierDismissible: barrierDismissible,
      builder: (context) => _MaterialAdaptiveDialog(
        title: title,
        content: content,
        actions: actions,
      ),
    );
  }
}

class _CupertinoAdaptiveDialog extends StatelessWidget {
  const _CupertinoAdaptiveDialog({
    required this.title,
    this.content,
    this.actions,
  });

  final String title;
  final String? content;
  final List<AdaptiveDialogAction>? actions;

  @override
  Widget build(BuildContext context) {
    return CupertinoAlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: actions
              ?.map((action) => CupertinoDialogAction(
                    onPressed: action.onPressed,
                    isDefaultAction: action.isDefaultAction,
                    isDestructiveAction: action.isDestructiveAction,
                    child: Text(action.text),
                  ))
              .toList() ??
          [],
    );
  }
}

class _MaterialAdaptiveDialog extends StatelessWidget {
  const _MaterialAdaptiveDialog({
    required this.title,
    this.content,
    this.actions,
  });

  final String title;
  final String? content;
  final List<AdaptiveDialogAction>? actions;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(title),
      content: content != null ? Text(content!) : null,
      actions: actions?.map((action) {
            if (action.isDestructiveAction) {
              return TextButton(
                onPressed: action.onPressed,
                style: TextButton.styleFrom(
                  foregroundColor: Theme.of(context).colorScheme.error,
                ),
                child: Text(action.text),
              );
            } else if (action.isDefaultAction) {
              return ElevatedButton(
                onPressed: action.onPressed,
                child: Text(action.text),
              );
            } else {
              return TextButton(
                onPressed: action.onPressed,
                child: Text(action.text),
              );
            }
          }).toList() ??
          [],
    );
  }
}
