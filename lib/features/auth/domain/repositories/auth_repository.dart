import 'package:barcode_scanner/core/utils/result.dart';
import '../entities/user.dart';

/// 認証リポジトリのインターフェース
abstract class AuthRepository {
  /// メールアドレスとパスワードでサインイン
  Future<Result<User>> signInWithEmail(String email, String password);

  /// Googleサインイン
  Future<Result<User>> signInWithGoogle();

  /// メールアドレスとパスワードでアカウント作成
  Future<Result<User>> createAccount(
    String email,
    String password,
    String displayName,
  );

  /// サインアウト
  Future<Result<void>> signOut();

  /// 現在のユーザーを取得
  Future<Result<User?>> getCurrentUser();

  /// パスワードリセットメールを送信
  Future<Result<void>> resetPassword(String email);

  /// メールアドレス認証を送信
  Future<Result<void>> sendEmailVerification();

  /// 認証状態の変更を監視
  Stream<User?> watchAuthStateChanges();

  /// ユーザープロフィールを更新
  Future<Result<User>> updateProfile({
    String? displayName,
    String? photoUrl,
  });

  /// パスワードを更新
  Future<Result<void>> updatePassword(String newPassword);

  /// アカウントを削除
  Future<Result<void>> deleteAccount();
}
