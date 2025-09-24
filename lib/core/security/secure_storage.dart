import 'dart:convert';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Exception thrown when secure storage operations fail
class SecureStorageException implements Exception {
  final String message;
  final Exception? cause;

  const SecureStorageException(this.message, [this.cause]);

  @override
  String toString() =>
      'SecureStorageException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
}

/// Secure storage manager for sensitive data
class SecureStorage {
  final FlutterSecureStorage _storage;

  // Default options for secure storage
  static const AndroidOptions _androidOptions = AndroidOptions(
    encryptedSharedPreferences: true,
    sharedPreferencesName: 'barcode_scanner_secure_prefs',
    preferencesKeyPrefix: 'secure_',
  );

  static const IOSOptions _iosOptions = IOSOptions(
    groupId: 'group.com.f06team.fridgemanager',
    accountName: 'barcode_scanner_keychain',
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  static const LinuxOptions _linuxOptions = LinuxOptions();
  static const WindowsOptions _windowsOptions = WindowsOptions();
  static const WebOptions _webOptions = WebOptions();

  SecureStorage({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: _androidOptions,
              iOptions: _iosOptions,
              lOptions: _linuxOptions,
              wOptions: _windowsOptions,
              webOptions: _webOptions,
            );

  /// Store a key-value pair securely
  Future<void> store(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      throw SecureStorageException(
          'Failed to store data for key: $key', Exception(e.toString()));
    }
  }

  /// Read a value by key
  Future<String?> read(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      throw SecureStorageException(
          'Failed to read data for key: $key', Exception(e.toString()));
    }
  }

  /// Delete a key-value pair
  Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      throw SecureStorageException(
          'Failed to delete data for key: $key', Exception(e.toString()));
    }
  }

  /// Clear all stored data
  Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
    } catch (e) {
      throw SecureStorageException(
          'Failed to clear all data', Exception(e.toString()));
    }
  }

  /// Store API key with additional security
  Future<void> storeApiKey(String keyName, String apiKey) async {
    try {
      final secureKey = 'api_key_$keyName';
      await _storage.write(key: secureKey, value: apiKey);
    } catch (e) {
      throw SecureStorageException(
          'Failed to store API key: $keyName', Exception(e.toString()));
    }
  }

  /// Get API key
  Future<String?> getApiKey(String keyName) async {
    try {
      final secureKey = 'api_key_$keyName';
      return await _storage.read(key: secureKey);
    } catch (e) {
      throw SecureStorageException(
          'Failed to retrieve API key: $keyName', Exception(e.toString()));
    }
  }

  /// Store biometric authentication preference
  Future<void> setBiometricEnabled(bool enabled) async {
    try {
      await _storage.write(key: 'biometric_enabled', value: enabled.toString());
    } catch (e) {
      throw SecureStorageException(
          'Failed to store biometric preference', Exception(e.toString()));
    }
  }

  /// Get biometric authentication preference
  Future<bool> isBiometricEnabled() async {
    try {
      final value = await _storage.read(key: 'biometric_enabled');
      return value?.toLowerCase() == 'true';
    } catch (e) {
      throw SecureStorageException(
          'Failed to retrieve biometric preference', Exception(e.toString()));
    }
  }

  /// Store encrypted data (additional layer of security)
  Future<void> storeEncrypted(String key, String data) async {
    try {
      final encryptedData = _encrypt(data);
      final secureKey = 'encrypted_$key';
      await _storage.write(key: secureKey, value: encryptedData);
    } catch (e) {
      throw SecureStorageException(
          'Failed to store encrypted data for key: $key',
          Exception(e.toString()));
    }
  }

  /// Read and decrypt data
  Future<String?> readEncrypted(String key) async {
    try {
      final secureKey = 'encrypted_$key';
      final encryptedData = await _storage.read(key: secureKey);
      if (encryptedData == null) return null;

      return _decrypt(encryptedData);
    } catch (e) {
      throw SecureStorageException(
          'Failed to read encrypted data for key: $key',
          Exception(e.toString()));
    }
  }

  /// Simple encryption using base64 and basic obfuscation
  /// Note: For production, consider using more robust encryption
  String _encrypt(String data) {
    final bytes = utf8.encode(data);
    final encoded = base64.encode(bytes);

    // Simple obfuscation - reverse the string
    return encoded.split('').reversed.join('');
  }

  /// Simple decryption
  String _decrypt(String encryptedData) {
    try {
      // Reverse the obfuscation
      final reversed = encryptedData.split('').reversed.join('');
      final bytes = base64.decode(reversed);
      return utf8.decode(bytes);
    } catch (e) {
      throw SecureStorageException(
          'Failed to decrypt data', Exception(e.toString()));
    }
  }

  /// Check if all required data is present
  Future<bool> hasRequiredData() async {
    try {
      final requiredKeys = ['api_key_gemini', 'api_key_firebase'];

      for (final key in requiredKeys) {
        final value = await _storage.read(key: key);
        if (value == null || value.isEmpty) {
          return false;
        }
      }

      return true;
    } catch (e) {
      return false;
    }
  }

  /// Get all stored keys (for debugging purposes)
  Future<Set<String>> getAllKeys() async {
    try {
      final allKeys = await _storage.readAll();
      return allKeys.keys.toSet();
    } catch (e) {
      throw SecureStorageException(
          'Failed to retrieve all keys', Exception(e.toString()));
    }
  }
}
