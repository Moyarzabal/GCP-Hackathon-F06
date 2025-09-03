import 'dart:io' show Platform;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Exception thrown when environment configuration is invalid
class EnvConfigException implements Exception {
  final String message;
  
  const EnvConfigException(this.message);
  
  @override
  String toString() => 'EnvConfigException: $message';
}

/// Firebase configuration model
class FirebaseConfig {
  final String apiKey;
  final String projectId;
  final String appId;
  final String? storageBucket;
  final String? messagingSenderId;
  final String? authDomain;
  
  const FirebaseConfig({
    required this.apiKey,
    required this.projectId,
    required this.appId,
    this.storageBucket,
    this.messagingSenderId,
    this.authDomain,
  });
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is FirebaseConfig &&
        other.apiKey == apiKey &&
        other.projectId == projectId &&
        other.appId == appId;
  }
  
  @override
  int get hashCode => apiKey.hashCode ^ projectId.hashCode ^ appId.hashCode;
}

/// Secure environment configuration manager
class EnvConfig {
  static bool _isInitialized = false;
  
  /// Initialize the environment configuration
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      await dotenv.load(fileName: '.env');
      _isInitialized = true;
    } catch (e) {
      // In production, .env file might not exist
      // We'll rely on platform environment variables
      _isInitialized = true;
    }
  }
  
  /// Get required environment variable or throw exception
  static String getRequired(String key) {
    if (!_isInitialized) {
      throw EnvConfigException('EnvConfig not initialized. Call initialize() first.');
    }
    
    String? value;
    try {
      value = dotenv.env[key];
    } catch (e) {
      // Fallback to system environment if dotenv fails
    }
    
    value ??= Platform.environment[key];
    
    if (value == null || value.isEmpty) {
      throw EnvConfigException('Required environment variable $key not found');
    }
    
    return value;
  }
  
  /// Get optional environment variable with default value
  static String getOptional(String key, String defaultValue) {
    if (!_isInitialized) return defaultValue;
    
    String? value;
    try {
      value = dotenv.env[key];
    } catch (e) {
      // Fallback to system environment if dotenv fails
    }
    
    return value ?? Platform.environment[key] ?? defaultValue;
  }
  
  /// Validate API key format (Google APIs start with 'AIza')
  static bool isValidApiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return false;
    return apiKey.startsWith('AIza') && apiKey.length >= 35;
  }
  
  /// Mask sensitive value for logging
  static String maskSensitiveValue(String sensitiveValue) {
    if (sensitiveValue.length <= 8) return '****';
    
    final start = sensitiveValue.substring(0, 4);
    final masked = '*' * (sensitiveValue.length - 8);
    final end = sensitiveValue.substring(sensitiveValue.length - 4);
    
    return '$start$masked$end';
  }
  
  /// Validate all required environment variables
  static void validateRequiredEnvVars() {
    final requiredVars = [
      'FIREBASE_PROJECT_ID',
    ];
    
    for (final varName in requiredVars) {
      try {
        getRequired(varName);
      } catch (e) {
        throw EnvConfigException('Missing required environment variable: $varName');
      }
    }
  }
  
  /// Check if running in web environment
  bool get isWeb => kIsWeb;
  
  /// Check if running in development environment
  bool get isDevelopment => getOptional('ENVIRONMENT', 'development') == 'development';
  
  /// Check if running in production environment
  bool get isProduction => getOptional('ENVIRONMENT', 'development') == 'production';
  
  /// Get Firebase configuration for current platform
  FirebaseConfig getFirebaseConfig() {
    if (isWeb) {
      return FirebaseConfig(
        apiKey: getRequired('FIREBASE_API_KEY'),
        projectId: getRequired('FIREBASE_PROJECT_ID'),
        appId: getRequired('FIREBASE_APP_ID'),
        storageBucket: getOptional('FIREBASE_STORAGE_BUCKET', ''),
        messagingSenderId: getOptional('FIREBASE_MESSAGING_SENDER_ID', ''),
        authDomain: getOptional('FIREBASE_AUTH_DOMAIN', ''),
      );
    } else if (Platform.isIOS) {
      return FirebaseConfig(
        apiKey: getRequired('FIREBASE_API_KEY'),
        projectId: getRequired('FIREBASE_PROJECT_ID'),
        appId: getRequired('FIREBASE_APP_ID'),
        storageBucket: getOptional('FIREBASE_STORAGE_BUCKET', ''),
        messagingSenderId: getOptional('FIREBASE_MESSAGING_SENDER_ID', ''),
      );
    } else {
      // Android and others
      return FirebaseConfig(
        apiKey: getRequired('FIREBASE_API_KEY'),
        projectId: getRequired('FIREBASE_PROJECT_ID'),
        appId: getRequired('FIREBASE_APP_ID'),
        storageBucket: getOptional('FIREBASE_STORAGE_BUCKET', ''),
        messagingSenderId: getOptional('FIREBASE_MESSAGING_SENDER_ID', ''),
      );
    }
  }
}