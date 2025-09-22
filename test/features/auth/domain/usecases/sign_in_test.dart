import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:barcode_scanner/features/auth/domain/entities/user.dart';
import 'package:barcode_scanner/features/auth/domain/repositories/auth_repository.dart';
import 'package:barcode_scanner/features/auth/domain/usecases/sign_in.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import 'package:barcode_scanner/core/utils/result.dart';

import 'sign_in_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  // Provide dummy values for Mockito
  provideDummy<Result<User>>(const Result.failure(AuthFailure(message: 'dummy')));
  late SignIn usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignIn(mockAuthRepository);
  });

  const testEmail = 'test@example.com';
  const testPassword = 'password123';
  const testUser = User(
    id: 'test_id',
    email: testEmail,
    displayName: 'Test User',
    isEmailVerified: true,
  );

  group('SignIn UseCase', () {
    test('should return User when signin is successful', () async {
      // Arrange
      when(mockAuthRepository.signInWithEmail(testEmail, testPassword))
          .thenAnswer((_) async => const Result.success(testUser));

      // Act
      final result = await usecase.execute(
        SignInParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result.isSuccess, true);
      expect(result.getOrNull(), testUser);
      verify(mockAuthRepository.signInWithEmail(testEmail, testPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Failure when signin fails', () async {
      // Arrange
      const failure = AuthFailure(message: 'Invalid credentials');
      when(mockAuthRepository.signInWithEmail(testEmail, testPassword))
          .thenAnswer((_) async => const Result.failure(failure));

      // Act
      final result = await usecase.execute(
        SignInParams(email: testEmail, password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), failure);
      verify(mockAuthRepository.signInWithEmail(testEmail, testPassword));
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Failure when email is empty', () async {
      // Act
      final result = await usecase.execute(
        const SignInParams(email: '', password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), isA<ValidationFailure>());
      verifyNever(mockAuthRepository.signInWithEmail(any, any));
    });

    test('should return Failure when password is empty', () async {
      // Act
      final result = await usecase.execute(
        const SignInParams(email: testEmail, password: ''),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), isA<ValidationFailure>());
      verifyNever(mockAuthRepository.signInWithEmail(any, any));
    });

    test('should return Failure when email is invalid format', () async {
      // Act
      final result = await usecase.execute(
        const SignInParams(email: 'invalid-email', password: testPassword),
      );

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), isA<ValidationFailure>());
      verifyNever(mockAuthRepository.signInWithEmail(any, any));
    });
  });

  group('SignInWithGoogle UseCase', () {
    test('should return User when Google signin is successful', () async {
      // Arrange
      const googleUser = User(
        id: 'google_id',
        email: 'user@gmail.com',
        displayName: 'Google User',
        photoUrl: 'https://example.com/photo.jpg',
        isEmailVerified: true,
      );
      when(mockAuthRepository.signInWithGoogle())
          .thenAnswer((_) async => const Result.success(googleUser));

      // Act
      final result = await usecase.executeGoogleSignIn();

      // Assert
      expect(result.isSuccess, true);
      expect(result.getOrNull(), googleUser);
      verify(mockAuthRepository.signInWithGoogle());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Failure when Google signin fails', () async {
      // Arrange
      const failure = AuthFailure(message: 'Google signin cancelled');
      when(mockAuthRepository.signInWithGoogle())
          .thenAnswer((_) async => const Result.failure(failure));

      // Act
      final result = await usecase.executeGoogleSignIn();

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), failure);
      verify(mockAuthRepository.signInWithGoogle());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}