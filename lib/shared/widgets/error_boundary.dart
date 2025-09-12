import 'dart:async';
import 'package:flutter/material.dart';
import 'error_display.dart';

/// エラーバウンダリウィジェット
class ErrorBoundary extends StatefulWidget {
  final Widget child;
  final void Function(Object error, StackTrace stackTrace) onError;
  final String? featureName;

  const ErrorBoundary({
    Key? key,
    required this.child,
    required this.onError,
    this.featureName,
  }) : super(key: key);

  @override
  State<ErrorBoundary> createState() => _ErrorBoundaryState();
}

class _ErrorBoundaryState extends State<ErrorBoundary> {
  Object? _error;

  @override
  void initState() {
    super.initState();
    
    // FlutterErrorの処理を設定
    FlutterError.onError = (FlutterErrorDetails details) {
      if (mounted) {
        // 非同期でエラーを処理してsetStateの競合を避ける
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            widget.onError(details.exception, details.stack ?? StackTrace.current);
          }
        });
      }
    };
  }

  @override
  void didUpdateWidget(ErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // エラーがクリアされた場合
    if (oldWidget.child != widget.child && _error != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            _error = null;
          });
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      return _buildErrorWidget(context, _error!);
    }
    
    return widget.child;
  }


  Widget _buildErrorWidget(BuildContext context, Object error) {
    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.featureName ?? 'アプリ'}でエラーが発生しました'),
        backgroundColor: Theme.of(context).colorScheme.error,
        foregroundColor: Colors.white,
      ),
      body: ErrorDisplay(
        error: error,
        onRetry: () {
          setState(() {
            _error = null;
          });
        },
      ),
    );
  }
}


/// 機能別エラーバウンダリ
class FeatureErrorBoundary extends StatelessWidget {
  final Widget child;
  final String featureName;
  final void Function(Object error, StackTrace stackTrace)? onError;

  const FeatureErrorBoundary({
    Key? key,
    required this.child,
    required this.featureName,
    this.onError,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ErrorBoundary(
      featureName: featureName,
      onError: (error, stackTrace) {
        onError?.call(error, stackTrace);
      },
      child: child,
    );
  }

  Widget _buildFeatureErrorWidget(BuildContext context, Object error) {
    return Center(
      child: SingleChildScrollView(
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
      ),
    );
  }

  String _getFeatureErrorMessage(Object error) {
    if (featureName.contains('スキャナー')) {
      return 'カメラの権限を確認してください。';
    } else if (featureName.contains('認証')) {
      return '再度ログインしてください。';
    } else if (featureName.contains('商品')) {
      return '商品情報の取得に失敗しました。';
    } else {
      return '予期しないエラーが発生しました。';
    }
  }
}

/// ルートレベルのエラーバウンダリ
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
      onError: (error, stackTrace) {
        onError?.call(error, stackTrace);
      },
      child: child,
    );
  }
}