import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:barcode_scanner/core/utils/result.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import 'package:barcode_scanner/features/auth/domain/entities/user.dart';
import 'package:barcode_scanner/features/auth/domain/repositories/auth_repository.dart';
import '../datasources/firebase_auth_datasource.dart';

/// 認証リポジトリの実装
class AuthRepositoryImpl implements AuthRepository {
  final FirebaseAuthDatasource _datasource;

  const AuthRepositoryImpl(this._datasource);

  @override
  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      final user = await _datasource.signInWithEmail(email, password);
      return Result.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<User>> signInWithGoogle() async {
    try {
      final user = await _datasource.signInWithGoogle();
      return Result.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<User>> createAccount(
    String email,
    String password,
    String displayName,
  ) async {
    try {
      final user = await _datasource.createAccount(email, password, displayName);
      return Result.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> signOut() async {
    try {
      await _datasource.signOut();
      return const Result.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<User?>> getCurrentUser() async {
    try {
      final user = await _datasource.getCurrentUser();
      return Result.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> resetPassword(String email) async {
    try {
      await _datasource.resetPassword(email);
      return const Result.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> sendEmailVerification() async {
    try {
      await _datasource.sendEmailVerification();
      return const Result.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Stream<User?> watchAuthStateChanges() {
    return _datasource.watchAuthStateChanges();
  }

  @override
  Future<Result<User>> updateProfile({
    String? displayName,
    String? photoUrl,
  }) async {
    try {
      final user = await _datasource.updateProfile(
        displayName: displayName,
        photoUrl: photoUrl,
      );
      return Result.success(user);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> updatePassword(String newPassword) async {
    try {
      await _datasource.updatePassword(newPassword);
      return const Result.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  @override
  Future<Result<void>> deleteAccount() async {
    try {
      await _datasource.deleteAccount();
      return const Result.success(null);
    } on firebase_auth.FirebaseAuthException catch (e) {
      return Result.failure(_mapFirebaseAuthException(e));
    } catch (e) {
      return Result.failure(
        ServerFailure(message: '予期しないエラーが発生しました: ${e.toString()}'),
      );
    }
  }

  /// FirebaseAuthExceptionをFailureにマッピング
  Failure _mapFirebaseAuthException(firebase_auth.FirebaseAuthException exception) {
    switch (exception.code) {
      // 認証エラー
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
      case 'user-disabled':
      case 'too-many-requests':
        return AuthFailure(
          message: _getJapaneseErrorMessage(exception.code),
          code: exception.code,
          originalError: exception,
        );

      // ネットワークエラー
      case 'network-request-failed':
      case 'timeout':
        return NetworkFailure(
          message: _getJapaneseErrorMessage(exception.code),
          code: exception.code,
          originalError: exception,
        );

      // バリデーションエラー
      case 'invalid-email':
      case 'weak-password':
      case 'email-already-in-use':
        return ValidationFailure(
          message: _getJapaneseErrorMessage(exception.code),
          code: exception.code,
          originalError: exception,
        );

      // その他のサーバーエラー
      default:
        return ServerFailure(
          message: exception.message ?? '予期しないエラーが発生しました',
          code: exception.code,
          originalError: exception,
        );
    }
  }

  /// エラーコードを日本語メッセージに変換
  String _getJapaneseErrorMessage(String code) {
    switch (code) {
      case 'user-not-found':
        return 'ユーザーが見つかりません';
      case 'wrong-password':
        return 'パスワードが正しくありません';
      case 'invalid-credential':
        return '認証情報が正しくありません';
      case 'user-disabled':
        return 'このアカウントは無効になっています';
      case 'too-many-requests':
        return 'リクエストが多すぎます。しばらく待ってからお試しください';
      case 'network-request-failed':
        return 'ネットワークエラーが発生しました';
      case 'timeout':
        return 'タイムアウトしました';
      case 'invalid-email':
        return 'メールアドレスの形式が正しくありません';
      case 'weak-password':
        return 'パスワードが弱すぎます';
      case 'email-already-in-use':
        return 'このメールアドレスは既に使用されています';
      default:
        return '予期しないエラーが発生しました';
    }
  }
}