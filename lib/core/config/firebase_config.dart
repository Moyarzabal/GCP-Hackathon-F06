import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'package:barcode_scanner/core/security/env_config.dart';

class FirebaseConfig {
  // Secure Firebase configuration using environment variables
  static FirebaseOptions get webOptions => FirebaseOptions(
        apiKey: _getApiKey(),
        authDomain: _getAuthDomain(),
        projectId: _getProjectId(),
        storageBucket: _getStorageBucket(),
        messagingSenderId: _getMessagingSenderId(),
        appId: _getWebAppId(),
      );

  static FirebaseOptions get iosOptions => FirebaseOptions(
        apiKey: _getApiKey(),
        appId: _getIosAppId(),
        messagingSenderId: _getMessagingSenderId(),
        projectId: _getProjectId(),
        storageBucket: _getStorageBucket(),
        iosBundleId: 'com.f06team.fridgemanager',
      );

  static FirebaseOptions get androidOptions => FirebaseOptions(
        apiKey: _getApiKey(),
        appId: _getAndroidAppId(),
        messagingSenderId: _getMessagingSenderId(),
        projectId: _getProjectId(),
        storageBucket: _getStorageBucket(),
      );

  // Private methods to get configuration from environment
  static String _getApiKey() {
    try {
      return EnvConfig.getRequired('FIREBASE_API_KEY');
    } catch (e) {
      // Fallback to hardcoded values for development/testing
      if (kDebugMode) {
        return 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A';
      }
      rethrow;
    }
  }

  static String _getProjectId() {
    return EnvConfig.getOptional('FIREBASE_PROJECT_ID', 'gcp-f06-barcode');
  }

  static String _getStorageBucket() {
    return EnvConfig.getOptional(
        'FIREBASE_STORAGE_BUCKET', 'gcp-f06-barcode.firebasestorage.app');
  }

  static String _getAuthDomain() {
    return EnvConfig.getOptional(
        'FIREBASE_AUTH_DOMAIN', 'gcp-f06-barcode.firebaseapp.com');
  }

  static String _getMessagingSenderId() {
    return EnvConfig.getOptional(
        'FIREBASE_MESSAGING_SENDER_ID', '787989873030');
  }

  static String _getWebAppId() {
    return EnvConfig.getOptional(
        'FIREBASE_WEB_APP_ID', '1:787989873030:web:09603db34685565f29ac07');
  }

  static String _getIosAppId() {
    return EnvConfig.getOptional(
        'FIREBASE_IOS_APP_ID', '1:787989873030:ios:0f768aa144b5823329ac07');
  }

  static String _getAndroidAppId() {
    return EnvConfig.getOptional('FIREBASE_ANDROID_APP_ID',
        '1:787989873030:android:d9495bc8845cdfa629ac07');
  }

  /// Initialize Firebase with platform-specific configuration
  static Future<void> initialize() async {
    // Ensure EnvConfig is initialized first
    await EnvConfig.initialize();

    FirebaseOptions? options;

    if (kIsWeb) {
      options = webOptions;
    } else if (Platform.isIOS) {
      options = iosOptions;
    } else if (Platform.isAndroid) {
      options = androidOptions;
    }

    if (options != null) {
      await Firebase.initializeApp(options: options);
    } else {
      throw UnsupportedError(
          'Unsupported platform for Firebase initialization');
    }
  }

  /// Get current platform configuration for debugging (masked)
  static Map<String, String> getConfigInfo() {
    return {
      'platform': kIsWeb ? 'web' : Platform.operatingSystem,
      'projectId': _getProjectId(),
      'apiKey': EnvConfig.maskSensitiveValue(_getApiKey()),
      'storageBucket': _getStorageBucket(),
    };
  }
}
