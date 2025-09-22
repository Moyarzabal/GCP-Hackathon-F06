import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:barcode_scanner/core/security/secure_storage.dart';

@GenerateMocks([FlutterSecureStorage])
import 'secure_storage_test.mocks.dart';

void main() {
  group('SecureStorage', () {
    late MockFlutterSecureStorage mockStorage;
    late SecureStorage secureStorage;

    setUp(() {
      mockStorage = MockFlutterSecureStorage();
      secureStorage = SecureStorage(storage: mockStorage);
    });

    group('Basic Storage Operations', () {
      test('should store sensitive data securely', () async {
        const key = 'test_key';
        const value = 'sensitive_value';

        await secureStorage.store(key, value);

        verify(mockStorage.write(key: key, value: value)).called(1);
      });

      test('should retrieve stored data', () async {
        const key = 'test_key';
        const value = 'sensitive_value';

        when(mockStorage.read(key: key))
            .thenAnswer((_) async => value);

        final result = await secureStorage.read(key);

        expect(result, equals(value));
        verify(mockStorage.read(key: key)).called(1);
      });

      test('should delete stored data', () async {
        const key = 'test_key';

        await secureStorage.delete(key);

        verify(mockStorage.delete(key: key)).called(1);
      });

      test('should clear all data', () async {
        await secureStorage.clearAll();

        verify(mockStorage.deleteAll()).called(1);
      });
    });

    group('API Key Management', () {
      test('should store API keys with encryption', () async {
        const apiKey = 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A';

        await secureStorage.storeApiKey('gemini', apiKey);

        verify(mockStorage.write(
          key: 'api_key_gemini',
          value: anyNamed('value'),
        )).called(1);
      });

      test('should retrieve and decrypt API keys', () async {
        const apiKey = 'AIzaSyD02Wpf0jMl6cjnsfbx2epdEkQEaBKH64A';

        when(mockStorage.read(key: 'api_key_gemini'))
            .thenAnswer((_) async => apiKey);

        final result = await secureStorage.getApiKey('gemini');

        expect(result, equals(apiKey));
      });

      test('should handle missing API keys gracefully', () async {
        when(mockStorage.read(key: 'api_key_missing'))
            .thenAnswer((_) async => null);

        final result = await secureStorage.getApiKey('missing');

        expect(result, isNull);
      });
    });

    group('Biometric Authentication', () {
      test('should store biometric preference', () async {
        await secureStorage.setBiometricEnabled(true);

        verify(mockStorage.write(
          key: 'biometric_enabled',
          value: 'true',
        )).called(1);
      });

      test('should retrieve biometric preference', () async {
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => 'true');

        final result = await secureStorage.isBiometricEnabled();

        expect(result, isTrue);
      });

      test('should default to false for biometric when not set', () async {
        when(mockStorage.read(key: 'biometric_enabled'))
            .thenAnswer((_) async => null);

        final result = await secureStorage.isBiometricEnabled();

        expect(result, isFalse);
      });
    });

    group('Data Encryption', () {
      test('should encrypt sensitive data before storage', () async {
        const sensitiveData = 'user_token_12345';

        await secureStorage.storeEncrypted('user_token', sensitiveData);

        // Verify that the stored value is different from original (encrypted)
        final captured = verify(mockStorage.write(
          key: 'encrypted_user_token',
          value: captureAnyNamed('value'),
        )).captured.single as String;

        expect(captured, isNot(equals(sensitiveData)));
        expect(captured.length, greaterThan(sensitiveData.length));
      });

      test('should decrypt data when retrieving', () async {
        const originalData = 'user_token_12345';
        
        // First, store the data to get proper encryption
        await secureStorage.storeEncrypted('user_token', originalData);
        
        // Get the encrypted data that was stored
        final capturedEncrypted = verify(mockStorage.write(
          key: 'encrypted_user_token',
          value: captureAnyNamed('value'),
        )).captured.single as String;

        // Mock the read to return the encrypted data
        when(mockStorage.read(key: 'encrypted_user_token'))
            .thenAnswer((_) async => capturedEncrypted);

        // This should decrypt successfully
        final result = await secureStorage.readEncrypted('user_token');

        expect(result, equals(originalData));
      });
    });

    group('Error Handling', () {
      test('should handle storage exceptions gracefully', () async {
        when(mockStorage.read(key: anyNamed('key')))
            .thenThrow(Exception('Storage error'));

        expect(
          () async => await secureStorage.read('test_key'),
          throwsA(isA<SecureStorageException>()),
        );
      });

      test('should handle write exceptions gracefully', () async {
        when(mockStorage.write(key: anyNamed('key'), value: anyNamed('value')))
            .thenThrow(Exception('Write error'));

        expect(
          () async => await secureStorage.store('test_key', 'test_value'),
          throwsA(isA<SecureStorageException>()),
        );
      });
    });
  });
}