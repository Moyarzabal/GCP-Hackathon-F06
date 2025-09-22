import 'package:logging/logging.dart';

import 'error_handler.dart';
import 'error_reporter.dart';

/// グローバルエラーハンドラーのシングルトン
/// アプリ全体でエラーハンドリングを統一管理
class GlobalErrorHandler {
  static GlobalErrorHandler? _instance;
  static GlobalErrorHandler get instance => _instance ??= GlobalErrorHandler._();

  late final ErrorHandler _errorHandler;
  late final ErrorReporter _errorReporter;
  late final Logger _logger;

  GlobalErrorHandler._() {
    _logger = Logger('GlobalErrorHandler');
    _errorReporter = ErrorReporter(logger: _logger);
    _errorHandler = ErrorHandler(
      errorReporter: _errorReporter,
      logger: _logger,
    );
  }

  /// エラーハンドラーを初期化
  void initialize() {
    _errorHandler.initialize();
    _setupLoggerLevel();
  }

  /// ログレベルを設定
  void _setupLoggerLevel() {
    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      // デバッグビルドでのみコンソールに出力
      if (record.level >= Level.WARNING) {
        print('${record.level.name}: ${record.time}: ${record.message}');
        if (record.error != null) {
          print('Error: ${record.error}');
        }
        if (record.stackTrace != null) {
          print('Stack trace:\n${record.stackTrace}');
        }
      }
    });
  }

  /// エラーハンドラーを取得
  ErrorHandler get errorHandler => _errorHandler;

  /// エラーレポーターを取得
  ErrorReporter get errorReporter => _errorReporter;

  /// 一般的なエラー処理のための便利メソッド
  Future<void> handleError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) async {
    await _errorHandler.handleError(
      error,
      stackTrace: stackTrace,
      context: context,
      fatal: fatal,
    );
  }

  /// パンくずリストに追加
  void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    _errorReporter.addBreadcrumb(message, category: category, data: data);
  }

  /// ユーザーコンテキストを設定
  void setUserContext({
    String? userId,
    String? email,
    String? name,
    Map<String, dynamic>? extra,
  }) {
    _errorReporter.setUserContext(
      userId: userId,
      email: email,
      name: name,
      extra: extra,
    );
  }

  /// カスタムタグを設定
  void setTag(String key, String value) {
    _errorReporter.setTag(key, value);
  }

  /// リソースのクリーンアップ
  void dispose() {
    _errorHandler.dispose();
    _errorReporter.dispose();
  }
}