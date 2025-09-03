import 'dart:developer' as dev;
import 'package:barcode_scanner/core/security/secure_storage.dart';
import 'package:barcode_scanner/core/security/env_config.dart';

/// Exception thrown when API key operations fail
class ApiKeyException implements Exception {
  final String message;
  final Exception? cause;
  
  const ApiKeyException(this.message, [this.cause]);
  
  @override
  String toString() => 'ApiKeyException: $message${cause != null ? ' (Caused by: $cause)' : ''}';
}

/// Secure API key manager
class ApiKeyManager {
  final SecureStorage _secureStorage;
  final EnvConfig _envConfig;
  
  // Request monitoring
  int _requestCount = 0;
  DateTime _lastResetTime = DateTime.now();
  static const int _maxRequestsPerHour = 1000;
  
  // Cached keys (memory only, cleared on app restart)
  final Map<String, String> _cachedKeys = {};
  
  ApiKeyManager({
    SecureStorage? secureStorage,
    EnvConfig? envConfig,
  }) : _secureStorage = secureStorage ?? SecureStorage(),
       _envConfig = envConfig ?? EnvConfig();
  
  /// Get Gemini API key with fallback strategy
  Future<String> getGeminiApiKey() async {
    _incrementRequestCount();
    
    try {
      // Try secure storage first
      String? apiKey = await _secureStorage.getApiKey('gemini');
      
      if (apiKey != null && isValidGeminiKey(apiKey)) {
        _cachedKeys['gemini'] = apiKey;
        return apiKey;
      }
      
      // Fallback to environment config
      try {
        apiKey = EnvConfig.getRequired('GEMINI_API_KEY');
        
        if (isValidGeminiKey(apiKey)) {
          // Store in secure storage for future use
          await _secureStorage.storeApiKey('gemini', apiKey);
          _cachedKeys['gemini'] = apiKey;
          return apiKey;
        }
      } catch (e) {
        dev.log('Failed to get Gemini API key from env: $e', name: 'ApiKeyManager');
      }
      
      throw ApiKeyException('No valid Gemini API key found');
    } catch (e) {
      _logSuspiciousActivity('Failed to retrieve Gemini API key', e);
      throw ApiKeyException('Failed to retrieve Gemini API key', Exception(e.toString()));
    }
  }
  
  /// Get Firebase API key
  Future<String> getFirebaseApiKey() async {
    _incrementRequestCount();
    
    try {
      String? apiKey = await _secureStorage.getApiKey('firebase');
      
      if (apiKey != null && isValidFirebaseKey(apiKey)) {
        return apiKey;
      }
      
      // Fallback to environment
      apiKey = EnvConfig.getRequired('FIREBASE_API_KEY');
      
      if (isValidFirebaseKey(apiKey)) {
        await _secureStorage.storeApiKey('firebase', apiKey);
        return apiKey;
      }
      
      throw ApiKeyException('No valid Firebase API key found');
    } catch (e) {
      _logSuspiciousActivity('Failed to retrieve Firebase API key', e);
      throw ApiKeyException('Failed to retrieve Firebase API key', Exception(e.toString()));
    }
  }
  
  /// Get Firebase configuration
  Future<FirebaseConfig> getFirebaseConfig() async {
    _incrementRequestCount();
    
    try {
      return _envConfig.getFirebaseConfig();
    } catch (e) {
      throw ApiKeyException('Failed to get Firebase config', Exception(e.toString()));
    }
  }
  
  /// Validate Gemini API key format
  bool isValidGeminiKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return false;
    
    // Gemini keys start with 'AIza' and are typically 39 characters
    return apiKey.startsWith('AIza') && 
           apiKey.length >= 35 && 
           apiKey.length <= 50 &&
           RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(apiKey);
  }
  
  /// Validate Firebase API key format
  bool isValidFirebaseKey(String? apiKey) {
    if (apiKey == null || apiKey.isEmpty) return false;
    
    // Firebase keys also start with 'AIza'
    return apiKey.startsWith('AIza') && 
           apiKey.length >= 35 && 
           apiKey.length <= 50 &&
           RegExp(r'^[A-Za-z0-9_-]+$').hasMatch(apiKey);
  }
  
  /// Rotate Gemini API key
  Future<void> rotateGeminiApiKey(String newApiKey) async {
    if (!isValidGeminiKey(newApiKey)) {
      throw ApiKeyException('Invalid Gemini API key format');
    }
    
    try {
      // Backup old key
      final oldKey = await _secureStorage.getApiKey('gemini');
      if (oldKey != null) {
        await _secureStorage.storeApiKey('gemini_backup', oldKey);
      }
      
      // Store new key
      await _secureStorage.storeApiKey('gemini', newApiKey);
      _cachedKeys['gemini'] = newApiKey;
      
      dev.log('Gemini API key rotated successfully', name: 'ApiKeyManager');
    } catch (e) {
      throw ApiKeyException('Failed to rotate Gemini API key', Exception(e.toString()));
    }
  }
  
  /// Clear all API keys
  Future<void> clearAllApiKeys() async {
    try {
      await _secureStorage.clearAll();
      _cachedKeys.clear();
      dev.log('All API keys cleared', name: 'ApiKeyManager');
    } catch (e) {
      throw ApiKeyException('Failed to clear API keys', Exception(e.toString()));
    }
  }
  
  /// Secure wipe of sensitive data from memory
  void secureWipe() {
    _cachedKeys.clear();
    _requestCount = 0;
    _lastResetTime = DateTime.now();
  }
  
  /// Check if keys are cached in memory
  bool hasCachedKeys() {
    return _cachedKeys.isNotEmpty;
  }
  
  /// Get current request count (for monitoring)
  int getRequestCount() {
    _checkAndResetRequestCount();
    return _requestCount;
  }
  
  /// Reset request count manually
  void resetRequestCount() {
    _requestCount = 0;
    _lastResetTime = DateTime.now();
  }
  
  /// Increment request count and check for rate limiting
  void _incrementRequestCount() {
    _checkAndResetRequestCount();
    _requestCount++;
    
    if (_requestCount > _maxRequestsPerHour) {
      _logSuspiciousActivity('Excessive API key requests detected', null);
      // In production, you might want to implement actual rate limiting here
    }
  }
  
  /// Check and reset request count if time window has passed
  void _checkAndResetRequestCount() {
    final now = DateTime.now();
    if (now.difference(_lastResetTime).inHours >= 1) {
      _requestCount = 0;
      _lastResetTime = now;
    }
  }
  
  /// Log suspicious activity
  void _logSuspiciousActivity(String message, dynamic error) {
    dev.log(
      'SECURITY ALERT: $message${error != null ? ' - Error: $error' : ''}',
      name: 'ApiKeyManager',
      level: 1000, // High severity
    );
  }
  
  /// Health check for API key manager
  Future<Map<String, dynamic>> healthCheck() async {
    try {
      final hasGemini = await _secureStorage.getApiKey('gemini') != null;
      final hasFirebase = await _secureStorage.getApiKey('firebase') != null;
      final hasRequiredData = await _secureStorage.hasRequiredData();
      
      return {
        'status': 'healthy',
        'hasGeminiKey': hasGemini,
        'hasFirebaseKey': hasFirebase,
        'hasRequiredData': hasRequiredData,
        'requestCount': _requestCount,
        'lastResetTime': _lastResetTime.toIso8601String(),
        'cachedKeyCount': _cachedKeys.length,
      };
    } catch (e) {
      return {
        'status': 'unhealthy',
        'error': e.toString(),
      };
    }
  }
}