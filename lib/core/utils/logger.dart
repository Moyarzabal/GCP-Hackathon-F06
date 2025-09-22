import 'package:flutter/foundation.dart';

/// Simple logger with different levels
class Logger {
  static const String _prefix = '[BarcodeScanner]';

  /// Log debug message (only in debug mode)
  static void debug(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix [DEBUG] $message');
      if (error != null) {
        debugPrint('$_prefix [DEBUG] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix [DEBUG] StackTrace: $stackTrace');
      }
    }
  }

  /// Log info message
  static void info(String message) {
    if (kDebugMode) {
      debugPrint('$_prefix [INFO] $message');
    }
  }

  /// Log warning message
  static void warning(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix [WARNING] $message');
      if (error != null) {
        debugPrint('$_prefix [WARNING] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix [WARNING] StackTrace: $stackTrace');
      }
    }
  }

  /// Log error message
  static void error(String message, [Object? error, StackTrace? stackTrace]) {
    if (kDebugMode) {
      debugPrint('$_prefix [ERROR] $message');
      if (error != null) {
        debugPrint('$_prefix [ERROR] Error: $error');
      }
      if (stackTrace != null) {
        debugPrint('$_prefix [ERROR] StackTrace: $stackTrace');
      }
    }
  }
}