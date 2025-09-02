import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:barcode_scanner/features/auth/domain/repositories/auth_repository.dart';
import 'package:barcode_scanner/features/auth/domain/usecases/sign_out.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import 'package:barcode_scanner/core/utils/result.dart';

import 'sign_out_test.mocks.dart';

@GenerateMocks([AuthRepository])
void main() {
  // Provide dummy values for Mockito
  provideDummy<Result<void>>(const Result.success(null));
  late SignOut usecase;
  late MockAuthRepository mockAuthRepository;

  setUp(() {
    mockAuthRepository = MockAuthRepository();
    usecase = SignOut(mockAuthRepository);
  });

  group('SignOut UseCase', () {
    test('should return success when signout is successful', () async {
      // Arrange
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Result.success(null));

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result.isSuccess, true);
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should return Failure when signout fails', () async {
      // Arrange
      const failure = AuthFailure(message: 'Failed to sign out');
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Result.failure(failure));

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), failure);
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });

    test('should handle network errors during signout', () async {
      // Arrange
      const failure = NetworkFailure(message: 'No internet connection');
      when(mockAuthRepository.signOut())
          .thenAnswer((_) async => const Result.failure(failure));

      // Act
      final result = await usecase.execute();

      // Assert
      expect(result.isFailure, true);
      expect(result.getError(), isA<NetworkFailure>());
      verify(mockAuthRepository.signOut());
      verifyNoMoreInteractions(mockAuthRepository);
    });
  });
}