import 'dart:async';
import 'dart:isolate';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

import '../../core/errors/app_exception.dart';
import 'error_display.dart';

/// エラー境界ウィジェット
/// 子ウィジェットでエラーが発生した場合に、アプリ全体がクラッシュするのを防ぐ
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, StackTrace? stackTrace)? errorWidgetBuilder;
  final VoidCallback? onRetry;

  const ErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
    this.errorWidgetBuilder,
    this.onRetry,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      // エラーが発生している場合はエラー表示ウィジェットを表示
      return widget.errorWidgetBuilder?.call(_error!, _stackTrace) ??
          _buildDefaultErrorWidget();
    }

    // エラーが発生していない場合は通常の子ウィジェットを表示
    return _ErrorBoundaryWrapper(
      onError: _handleError,
      child: widget.child,
    );
  }

  void _handleError(Object error, StackTrace stackTrace) {
    setState(() {
      _error = error;
      _stackTrace = stackTrace;
    });

    // エラーコールバックを呼び出し
    widget.onError?.call(error, stackTrace);

    // デバッグモードではエラー詳細を出力
    if (kDebugMode) {
      FlutterError.presentError(FlutterErrorDetails(
        exception: error,
        stack: stackTrace,
        context: ErrorDescription('ErrorBoundary caught an error'),
      ));
    }
  }

  Widget _buildDefaultErrorWidget() {
    return ErrorDisplay(
      error: _error!,
      onRetry: _onRetry,
    );
  }

  void _onRetry() {
    setState(() {
      _error = null;
      _stackTrace = null;
    });
    
    widget.onRetry?.call();
  }

  /// 子ウィジェットが変更された場合はエラー状態をリセット
  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }
}

/// エラーキャッチャーWrapper
class _ErrorBoundaryWrapper extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _ErrorBoundaryWrapper({
    required this.child,
    required this.onError,
  });

  @override
  State<_ErrorBoundaryWrapper> createState() => _ErrorBoundaryWrapperState();
}

class _ErrorBoundaryWrapperState extends State<_ErrorBoundaryWrapper> {
  @override
  Widget build(BuildContext context) {
    return widget.child;
  }

  @override
  void initState() {
    super.initState();
    
    // FlutterErrorの処理を設定
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        widget.onError(details.exception, details.stack ?? StackTrace.current);
      }
    };
  }

  /// ウィジェットビルド中のエラーをキャッチ
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    
    try {
      // ここで子ウィジェットの依存関係の変更を処理
    } catch (error, stackTrace) {
      widget.onError(error, stackTrace);
    }
  }
}

/// 非同期エラー境界
/// FutureBuilderやStreamBuilderで発生するエラーをキャッチ
class AsyncErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;
  final Widget Function(Object error, StackTrace? stackTrace)? errorWidgetBuilder;

  const AsyncErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
    this.errorWidgetBuilder,
  }) : super(key: key);

  @override
  State<AsyncErrorBoundary> createState() => _AsyncErrorBoundaryState();
}

class _AsyncErrorBoundaryState extends State<AsyncErrorBoundary> {
  Object? _error;
  StackTrace? _stackTrace;

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return widget.errorWidgetBuilder?.call(_error!, _stackTrace) ??
          ErrorDisplay(error: _error!);
    }

    return _AsyncErrorCatcher(
      onError: _handleAsyncError,
      child: widget.child,
    );
  }

  void _handleAsyncError(Object error, StackTrace stackTrace) {
    if (mounted) {
      setState(() {
        _error = error;
        _stackTrace = stackTrace;
      });
      
      widget.onError?.call(error, stackTrace);
    }
  }

  @override
  void didUpdateWidget(AsyncErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.child != oldWidget.child) {
      setState(() {
        _error = null;
        _stackTrace = null;
      });
    }
  }
}

/// 非同期エラーキャッチャー
class _AsyncErrorCatcher extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;

  const _AsyncErrorCatcher({
    required this.child,
    required this.onError,
  });

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return runZonedGuarded(
          () => child,
          (error, stackTrace) {
            onError(error, stackTrace);
          },
        ) ?? const SizedBox.shrink();
      },
    );
  }
}

/// 特定の機能用のエラー境界
class FeatureErrorBoundary extends StatelessWidget {
  final Widget child;
  final String featureName;
  final void Function(Object error, StackTrace stackTrace, String feature)? onError;

  const FeatureErrorBoundary({
    Key? key,
    required this.child,
    required this.featureName,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: (error, stackTrace) {
        onError?.call(error, stackTrace, featureName);
      },
      errorWidgetBuilder: (error, stackTrace) {
        return _buildFeatureErrorWidget(context, error);
      },
      child: child,
    );
  }

  Widget _buildFeatureErrorWidget(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              '$featureName機能でエラーが発生しました',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Theme.of(context).colorScheme.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _getFeatureErrorMessage(error),
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                // 他の機能に戻る
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }

  String _getFeatureErrorMessage(Object error) {
    if (featureName.contains('スキャナー')) {
      return 'カメラの権限を確認してください。';
    } else if (featureName.contains('認証')) {
      return '再度ログインしてください。';
    } else if (featureName.contains('商品')) {
      return 'ネットワーク接続を確認してください。';
    } else {
      return 'この機能は一時的に利用できません。';
    }
  }
}

/// ルート階層のエラー境界
class RootErrorBoundary extends StatelessWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const RootErrorBoundary({
    Key? key,
    required this.child,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      onError: onError,
      errorWidgetBuilder: (error, stackTrace) {
        return MaterialApp(
          home: Scaffold(
            body: ErrorDisplay(
              error: error,
              message: 'アプリでエラーが発生しました',
              onRetry: () {
                // アプリを再起動
                // 実装は環境に依存
              },
            ),
          ),
        );
      },
      child: child,
    );
  }
}