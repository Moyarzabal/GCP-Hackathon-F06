import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:barcode_scanner/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:barcode_scanner/features/auth/data/datasources/firebase_auth_datasource.dart';
import 'package:barcode_scanner/features/auth/domain/entities/user.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import 'package:barcode_scanner/core/utils/result.dart';

import 'auth_repository_test.mocks.dart';

@GenerateMocks([FirebaseAuthDatasource, firebase_auth.User])
void main() {
  // Provide dummy values for Mockito
  provideDummy<Result<User>>(
      const Result.failure(AuthFailure(message: 'dummy')));
  provideDummy<Result<User?>>(
      const Result.failure(AuthFailure(message: 'dummy')));
  provideDummy<Result<void>>(const Result.success(null));
  late AuthRepositoryImpl repository;
  late MockFirebaseAuthDatasource mockDatasource;

  setUp(() {
    mockDatasource = MockFirebaseAuthDatasource();
    repository = AuthRepositoryImpl(mockDatasource);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testUser = User(
    id: 'test_id',
    email: testEmail,
    displayName: 'Test User',
    isEmailVerified: true,
  );

  group('AuthRepositoryImpl', () {
    group('signInWithEmail', () {
      test('should return User when signin is successful', () async {
        // Arrange
        when(mockDatasource.signInWithEmail(testEmail, testPassword))
            .thenAnswer((_) async => testUser);

        // Act
        final result =
            await repository.signInWithEmail(testEmail, testPassword);

        // Assert
        expect(result.isSuccess, true);
        expect(result.getOrNull(), testUser);
        verify(mockDatasource.signInWithEmail(testEmail, testPassword));
      });

      test('should return AuthFailure when credentials are invalid', () async {
        // Arrange
        when(mockDatasource.signInWithEmail(testEmail, testPassword))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user record found',
        ));

        // Act
        final result =
            await repository.signInWithEmail(testEmail, testPassword);

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<AuthFailure>());
        verify(mockDatasource.signInWithEmail(testEmail, testPassword));
      });

      test('should return NetworkFailure when network error occurs', () async {
        // Arrange
        when(mockDatasource.signInWithEmail(testEmail, testPassword))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'network-request-failed',
          message: 'Network error',
        ));

        // Act
        final result =
            await repository.signInWithEmail(testEmail, testPassword);

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<NetworkFailure>());
        verify(mockDatasource.signInWithEmail(testEmail, testPassword));
      });

      test('should return ServerFailure for unexpected errors', () async {
        // Arrange
        when(mockDatasource.signInWithEmail(testEmail, testPassword))
            .thenThrow(Exception('Unexpected error'));

        // Act
        final result =
            await repository.signInWithEmail(testEmail, testPassword);

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<ServerFailure>());
        verify(mockDatasource.signInWithEmail(testEmail, testPassword));
      });
    });

    group('signInWithGoogle', () {
      test('should return User when Google signin is successful', () async {
        // Arrange
        const googleUser = User(
          id: 'google_id',
          email: 'user@gmail.com',
          displayName: 'Google User',
          photoUrl: 'https://example.com/photo.jpg',
          isEmailVerified: true,
        );
        when(mockDatasource.signInWithGoogle())
            .thenAnswer((_) async => googleUser);

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isSuccess, true);
        expect(result.getOrNull(), googleUser);
        verify(mockDatasource.signInWithGoogle());
      });

      test('should return ServerFailure when Google signin is cancelled',
          () async {
        // Arrange
        when(mockDatasource.signInWithGoogle())
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'sign_in_canceled',
          message: 'Sign in cancelled by user',
        ));

        // Act
        final result = await repository.signInWithGoogle();

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<ServerFailure>());
        verify(mockDatasource.signInWithGoogle());
      });
    });

    group('signOut', () {
      test('should return success when signout is successful', () async {
        // Arrange
        when(mockDatasource.signOut()).thenAnswer((_) async => {});

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isSuccess, true);
        verify(mockDatasource.signOut());
      });

      test('should return Failure when signout fails', () async {
        // Arrange
        when(mockDatasource.signOut())
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'unknown',
          message: 'Sign out failed',
        ));

        // Act
        final result = await repository.signOut();

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<ServerFailure>());
        verify(mockDatasource.signOut());
      });
    });

    group('getCurrentUser', () {
      test('should return User when user is authenticated', () async {
        // Arrange
        when(mockDatasource.getCurrentUser()).thenAnswer((_) async => testUser);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, true);
        expect(result.getOrNull(), testUser);
        verify(mockDatasource.getCurrentUser());
      });

      test('should return null when no user is authenticated', () async {
        // Arrange
        when(mockDatasource.getCurrentUser()).thenAnswer((_) async => null);

        // Act
        final result = await repository.getCurrentUser();

        // Assert
        expect(result.isSuccess, true);
        expect(result.getOrNull(), isNull);
        verify(mockDatasource.getCurrentUser());
      });
    });

    group('createAccount', () {
      test('should return User when account creation is successful', () async {
        // Arrange
        const displayName = 'New User';
        when(mockDatasource.createAccount(testEmail, testPassword, displayName))
            .thenAnswer((_) async => testUser);

        // Act
        final result = await repository.createAccount(
            testEmail, testPassword, displayName);

        // Assert
        expect(result.isSuccess, true);
        expect(result.getOrNull(), testUser);
        verify(
            mockDatasource.createAccount(testEmail, testPassword, displayName));
      });

      test('should return ValidationFailure when email is already in use',
          () async {
        // Arrange
        const displayName = 'New User';
        when(mockDatasource.createAccount(testEmail, testPassword, displayName))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'email-already-in-use',
          message: 'Email is already registered',
        ));

        // Act
        final result = await repository.createAccount(
            testEmail, testPassword, displayName);

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<ValidationFailure>());
        verify(
            mockDatasource.createAccount(testEmail, testPassword, displayName));
      });
    });

    group('resetPassword', () {
      test('should return success when password reset is sent', () async {
        // Arrange
        when(mockDatasource.resetPassword(testEmail))
            .thenAnswer((_) async => {});

        // Act
        final result = await repository.resetPassword(testEmail);

        // Assert
        expect(result.isSuccess, true);
        verify(mockDatasource.resetPassword(testEmail));
      });

      test('should return AuthFailure when user not found', () async {
        // Arrange
        when(mockDatasource.resetPassword(testEmail))
            .thenThrow(firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'No user found with this email',
        ));

        // Act
        final result = await repository.resetPassword(testEmail);

        // Assert
        expect(result.isFailure, true);
        expect(result.getError(), isA<AuthFailure>());
        verify(mockDatasource.resetPassword(testEmail));
      });
    });
  });
}
