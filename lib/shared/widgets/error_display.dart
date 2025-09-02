import 'dart:async';
import 'package:flutter/material.dart';
import '../../core/errors/app_exception.dart';
import '../../core/errors/error_messages.dart';

/// ユーザーフレンドリーなエラー表示ウィジェット
class ErrorDisplay extends StatefulWidget {
  final Object error;
  final String? message;
  final VoidCallback? onRetry;
  final bool showDetails;

  const ErrorDisplay({
    Key? key,
    required this.error,
    this.message,
    this.onRetry,
    this.showDetails = true,
  }) : super(key: key);

  @override
  State<ErrorDisplay> createState() => _ErrorDisplayState();
}

class _ErrorDisplayState extends State<ErrorDisplay> {
  bool _showingDetails = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = widget.message ?? _getLocalizedMessage(widget.error);
    final errorIcon = _getErrorIcon(widget.error);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // エラーアイコン
            Icon(
              errorIcon,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            
            // メインメッセージ
            Text(
              errorMessage,
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            
            // エラー詳細
            Text(
              widget.error.toString(),
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            
            // 詳細表示ボタン
            if (widget.showDetails) ...[
              const SizedBox(height: 16),
              TextButton.icon(
                onPressed: () {
                  setState(() {
                    _showingDetails = !_showingDetails;
                  });
                },
                icon: Icon(_showingDetails ? Icons.expand_less : Icons.expand_more),
                label: Text(_showingDetails ? '詳細を隠す' : '詳細を表示'),
              ),
            ],
            
            // 詳細情報
            if (widget.showDetails && _showingDetails) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'エラーの詳細:',
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'エラータイプ: ${widget.error.runtimeType}',
                      style: theme.textTheme.bodySmall,
                    ),
                    if (widget.error is AppException) ...[
                      const SizedBox(height: 4),
                      if ((widget.error as AppException).details != null)
                        Text(
                          '詳細: ${(widget.error as AppException).details}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                    if (widget.error is ApiException) ...[
                      const SizedBox(height: 4),
                      if ((widget.error as ApiException).statusCode != null)
                        Text(
                          'Status: ${(widget.error as ApiException).statusCode}',
                          style: theme.textTheme.bodySmall,
                        ),
                    ],
                  ],
                ),
              ),
            ],
            
            // 再試行ボタン
            if (widget.onRetry != null) ...[
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: widget.onRetry,
                icon: const Icon(Icons.refresh),
                label: const Text('再試行'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _getLocalizedMessage(Object error) {
    return ErrorMessages.getUserFriendlyMessage(error);
  }

  IconData _getErrorIcon(Object error) {
    if (error is NetworkException) {
      return Icons.wifi_off;
    } else if (error is AuthException) {
      return Icons.lock_outline;
    } else if (error is DatabaseException) {
      return Icons.storage;
    } else if (error is ValidationException) {
      return Icons.warning;
    } else if (error is ScannerException) {
      return Icons.camera_alt_outlined;
    } else if (error is ApiException) {
      return Icons.cloud_off;
    } else {
      return Icons.error_outline;
    }
  }

  String _getDetailedMessage(Object error) {
    return ErrorMessages.getDetailedMessage(error);
  }
}

/// インライン用の小さなエラー表示ウィジェット
class InlineErrorDisplay extends StatelessWidget {
  final Object error;
  final String? message;
  final VoidCallback? onDismiss;

  const InlineErrorDisplay({
    Key? key,
    required this.error,
    this.message,
    this.onDismiss,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorMessage = message ?? error.toString();

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      padding: const EdgeInsets.all(12.0),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer,
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: theme.colorScheme.error.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline,
            color: theme.colorScheme.error,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              errorMessage,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onErrorContainer,
              ),
            ),
          ),
          if (onDismiss != null) ...[
            const SizedBox(width: 12),
            GestureDetector(
              onTap: onDismiss,
              child: Icon(
                Icons.close,
                color: theme.colorScheme.error,
                size: 20,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// エラー用のSnackBar
class ErrorSnackBar {
  static void show(
    BuildContext context,
    Object error, {
    String? message,
    VoidCallback? onRetry,
    Duration duration = const Duration(seconds: 4),
  }) {
    final errorMessage = message ?? _getErrorMessage(error);
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.white,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
        duration: duration,
        action: onRetry != null
            ? SnackBarAction(
                label: '再試行',
                textColor: Colors.white,
                onPressed: onRetry,
              )
            : null,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  static String _getErrorMessage(Object error) {
    if (error is NetworkException) {
      return 'ネットワークエラーが発生しました';
    } else if (error is AuthException) {
      return '認証に失敗しました';
    } else if (error is ValidationException) {
      return '入力内容に問題があります';
    } else {
      return 'エラーが発生しました';
    }
  }
}

/// トースト風のエラー表示
class ErrorToast {
  static void show(
    BuildContext context,
    Object error, {
    String? message,
  }) {
    final overlay = Overlay.of(context);
    final errorMessage = message ?? error.toString();

    late OverlayEntry overlayEntry;
    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).padding.top + 16,
        left: 16,
        right: 16,
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(8),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: Theme.of(context).colorScheme.error.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  color: Theme.of(context).colorScheme.error,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    errorMessage,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);

    // 3秒後に自動で削除
    Timer(const Duration(seconds: 3), () {
      overlayEntry.remove();
    });
  }
}