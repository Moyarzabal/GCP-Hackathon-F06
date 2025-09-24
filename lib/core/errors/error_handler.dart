import 'dart:async';
import 'dart:isolate';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

import 'app_exception.dart';
import 'error_reporter.dart';
import 'error_messages.dart';

/// グローバルエラーハンドラー
/// Flutter Error、Platform Error、および非同期エラーを統一的に処理
class ErrorHandler {
  final ErrorReporter errorReporter;
  final Logger logger;

  ErrorHandler({
    required this.errorReporter,
    required this.logger,
  });

  /// エラーハンドラーを初期化
  /// Flutter のエラーハンドリング機能を設定
  void initialize() {
    // Flutter フレームワークエラーのハンドリング
    FlutterError.onError = (FlutterErrorDetails details) {
      handleFlutterError(details);
    };

    // プラットフォームエラーのハンドリング
    PlatformDispatcher.instance.onError = (error, stack) {
      handleAsyncError(error, stack);
      return true; // エラーが処理されたことを示す
    };

    // Isolate のエラーハンドリング（Webでは使用しない）
    // Web以外のプラットフォームでのみIsolateを使用
    // Webではdart:isolateがサポートされていないため
    if (!kIsWeb) {
      Isolate.current.addErrorListener(
        RawReceivePort((pair) async {
          final List<dynamic> errorAndStacktrace = pair;
          final error = errorAndStacktrace[0];
          final stackTrace = errorAndStacktrace[1] is StackTrace
              ? errorAndStacktrace[1] as StackTrace
              : null;
          await handleAsyncError(error, stackTrace);
        }).sendPort,
      );
    }
  }

  /// Flutter フレームワークエラーの処理
  Future<void> handleFlutterError(FlutterErrorDetails details) async {
    logger.severe(
      'Flutter Error: ${details.exception}',
      details.exception,
      details.stack,
    );

    await errorReporter.reportError(
      details.exception,
      stackTrace: details.stack,
      context:
          'Flutter Error${details.context != null ? ': ${details.context}' : ''}',
      fatal: false,
    );

    // デバッグモードでは通常のFlutterエラー処理も実行
    if (kDebugMode) {
      FlutterError.presentError(details);
    }
  }

  /// 非同期エラーの処理
  Future<void> handleAsyncError(Object error, StackTrace? stackTrace) async {
    final isCritical = isCriticalError(error);

    logger.severe(
      'Async Error: $error',
      error,
      stackTrace,
    );

    await errorReporter.reportError(
      error,
      stackTrace: stackTrace,
      context: 'Async Error',
      fatal: isCritical,
    );
  }

  /// 一般的なエラー処理（コンテキスト付き）
  Future<void> handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) async {
    final contextMsg = context != null ? ' (Context: $context)' : '';

    logger.warning(
      'Error: $error$contextMsg',
      error,
      stackTrace,
    );

    await errorReporter.reportError(
      error,
      stackTrace: stackTrace,
      context: context,
      fatal: fatal,
    );
  }

  /// エラーが重大かどうかを判定
  bool isCriticalError(Object error) {
    return error is DatabaseException ||
        error is AuthException ||
        (error is ApiException &&
            error.statusCode != null &&
            error.statusCode! >= 500);
  }

  /// エラーの回復方法を提案
  String getRecoverySuggestion(Object error) {
    return ErrorMessages.getRecoverySuggestion(error);
  }

  /// ユーザーフレンドリーなエラーメッセージを取得
  String getUserFriendlyMessage(Object error) {
    return ErrorMessages.getUserFriendlyMessage(error);
  }

  /// 詳細なエラーメッセージを取得
  String getDetailedMessage(Object error) {
    return ErrorMessages.getDetailedMessage(error);
  }

  /// エラーハンドラーのクリーンアップ
  void dispose() {
    // 必要に応じてリソースのクリーンアップを行う
  }
}
