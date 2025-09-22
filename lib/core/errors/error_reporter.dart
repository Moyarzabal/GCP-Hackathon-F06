import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';
import 'package:device_info_plus/device_info_plus.dart';

import 'app_exception.dart';
import 'error_messages.dart';

// ErrorSeverityはerror_messages.dartで定義

/// エラーレポーター
/// エラーの収集、分類、外部レポート機能を提供
class ErrorReporter {
  final Logger logger;
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  // エラー重複除去用のキャッシュ
  final Map<String, DateTime> _errorCache = {};

  // パンくずリスト（ユーザーの行動履歴）
  final List<Map<String, dynamic>> _breadcrumbs = [];

  // ユーザーコンテキスト
  final Map<String, dynamic> _userContext = {};

  // カスタムタグ
  final Map<String, String> _tags = {};

  // 設定
  static const int maxBreadcrumbs = 20;
  static const Duration duplicateErrorWindow = Duration(minutes: 5);

  ErrorReporter({required this.logger});

  /// エラーをレポート
  Future<void> reportError(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) async {
    try {
      // エラー重複チェック
      if (_isDuplicateError(error)) {
        logger.fine('Skipping duplicate error: $error');
        return;
      }

      // エラーの重要度を判定
      final severity = getErrorSeverity(error);

      // ログレベルに応じてログ出力
      switch (severity) {
        case ErrorSeverity.info:
          logger.info('Error reported: $error', error, stackTrace);
          break;
        case ErrorSeverity.warning:
          logger.warning('Error reported: $error', error, stackTrace);
          break;
        case ErrorSeverity.error:
        case ErrorSeverity.critical:
          logger.severe('Error reported: $error', error, stackTrace);
          break;
      }

      // エラー情報をフォーマット
      final errorData = formatErrorForReporting(
        error,
        stackTrace: stackTrace,
        context: context,
        fatal: fatal,
      );

      // 外部サービスにレポート（将来的にCrashlyticsなど）
      await _reportToExternalService(errorData);

      // エラーキャッシュに追加
      _addToErrorCache(error);

    } catch (reportingError) {
      // エラーレポート自体でエラーが発生した場合
      logger.shout('Error reporting failed: $reportingError');
    }
  }

  /// エラーの重要度を判定
  ErrorSeverity getErrorSeverity(Object error) {
    if (error is DatabaseException) {
      return ErrorSeverity.critical;
    } else if (error is AuthException) {
      return ErrorSeverity.error;
    } else if (error is ApiException) {
      if (error.statusCode != null && error.statusCode! >= 500) {
        return ErrorSeverity.error;
      }
      return ErrorSeverity.warning;
    } else if (error is NetworkException) {
      return ErrorSeverity.warning;
    } else if (error is ValidationException) {
      return ErrorSeverity.info;
    } else if (error is ScannerException) {
      return ErrorSeverity.warning;
    } else {
      return ErrorSeverity.warning;
    }
  }

  /// デバイス情報を収集
  Future<Map<String, dynamic>> collectDeviceInfo() async {
    try {
      final Map<String, dynamic> deviceInfo = {};

      deviceInfo['platform'] = Platform.operatingSystem;
      deviceInfo['version'] = Platform.operatingSystemVersion;
      deviceInfo['locale'] = Platform.localeName;
      deviceInfo['dart_version'] = Platform.version;

      if (kIsWeb) {
        final webBrowserInfo = await _deviceInfo.webBrowserInfo;
        deviceInfo['browser'] = webBrowserInfo.browserName.name;
        deviceInfo['user_agent'] = webBrowserInfo.userAgent;
      } else if (Platform.isAndroid) {
        final androidInfo = await _deviceInfo.androidInfo;
        deviceInfo['device_model'] = androidInfo.model;
        deviceInfo['android_version'] = androidInfo.version.release;
        deviceInfo['manufacturer'] = androidInfo.manufacturer;
      } else if (Platform.isIOS) {
        final iosInfo = await _deviceInfo.iosInfo;
        deviceInfo['device_model'] = iosInfo.model;
        deviceInfo['ios_version'] = iosInfo.systemVersion;
        deviceInfo['device_name'] = iosInfo.name;
      }

      return deviceInfo;
    } catch (e) {
      logger.warning('Failed to collect device info: $e');
      return {'platform': 'unknown'};
    }
  }

  /// エラー情報をレポート用にフォーマット
  Map<String, dynamic> formatErrorForReporting(
    Object error, {
    StackTrace? stackTrace,
    String? context,
    bool fatal = false,
  }) {
    final Map<String, dynamic> data = {
      'error': error.toString(),
      'error_type': error.runtimeType.toString(),
      'fatal': fatal,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // スタックトレース
    if (stackTrace != null) {
      data['stack_trace'] = stackTrace.toString();
    }

    // コンテキスト
    if (context != null) {
      data['context'] = context;
    }

    // AppException 固有の情報
    if (error is AppException) {
      if (error.details != null) {
        data['details'] = error.details;
      }
    }

    // ApiException 固有の情報
    if (error is ApiException && error.statusCode != null) {
      data['status_code'] = error.statusCode;
    }

    // パンくずリスト
    data['breadcrumbs'] = List.from(_breadcrumbs);

    // ユーザーコンテキスト
    data['user_context'] = Map.from(_userContext);

    // カスタムタグ
    data['tags'] = Map.from(_tags);

    // エラーの重要度
    data['severity'] = getErrorSeverity(error).name;

    return data;
  }

  /// パンくずリストに追加
  void addBreadcrumb(String message, {String? category, Map<String, dynamic>? data}) {
    final breadcrumb = {
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
      'category': category ?? 'default',
      'data': data ?? {},
    };

    _breadcrumbs.add(breadcrumb);

    // 最大数を超えた場合、古いものを削除
    if (_breadcrumbs.length > maxBreadcrumbs) {
      _breadcrumbs.removeAt(0);
    }
  }

  /// パンくずリストを取得
  List<Map<String, dynamic>> getBreadcrumbs() {
    return List.unmodifiable(_breadcrumbs);
  }

  /// ユーザーコンテキストを設定
  void setUserContext({
    String? userId,
    String? email,
    String? name,
    Map<String, dynamic>? extra,
  }) {
    if (userId != null) _userContext['userId'] = userId;
    if (email != null) _userContext['email'] = email;
    if (name != null) _userContext['name'] = name;
    if (extra != null) _userContext.addAll(extra);
  }

  /// ユーザーコンテキストを取得
  Map<String, dynamic> getUserContext() {
    return Map.unmodifiable(_userContext);
  }

  /// ユーザーコンテキストをクリア
  void clearUserContext() {
    _userContext.clear();
  }

  /// カスタムタグを設定
  void setTag(String key, String value) {
    _tags[key] = value;
  }

  /// タグを取得
  Map<String, String> getTags() {
    return Map.unmodifiable(_tags);
  }

  /// 重複エラーかどうかをチェック
  bool _isDuplicateError(Object error) {
    final errorKey = '${error.runtimeType}_${error.toString()}';
    final now = DateTime.now();

    if (_errorCache.containsKey(errorKey)) {
      final lastReported = _errorCache[errorKey]!;
      if (now.difference(lastReported) < duplicateErrorWindow) {
        return true;
      }
    }

    return false;
  }

  /// エラーキャッシュに追加
  void _addToErrorCache(Object error) {
    final errorKey = '${error.runtimeType}_${error.toString()}';
    _errorCache[errorKey] = DateTime.now();

    // 古いエラーエントリをクリーンアップ
    final cutoff = DateTime.now().subtract(duplicateErrorWindow);
    _errorCache.removeWhere((key, timestamp) => timestamp.isBefore(cutoff));
  }

  /// 外部サービスにレポート
  Future<void> _reportToExternalService(Map<String, dynamic> errorData) async {
    // 将来的にCrashlyticsやSentryなどの外部サービスに送信
    // 現在はログ出力のみ
    logger.info('Error data ready for external reporting: ${errorData['error_type']}');

    // TODO: Firebase Crashlytics統合
    // FirebaseCrashlytics.instance.recordError(
    //   errorData['error'],
    //   StackTrace.fromString(errorData['stack_trace'] ?? ''),
    //   fatal: errorData['fatal'],
    // );
  }

  /// リソースのクリーンアップ
  void dispose() {
    _errorCache.clear();
    _breadcrumbs.clear();
    _userContext.clear();
    _tags.clear();
  }
}