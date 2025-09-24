import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:barcode_scanner/features/auth/domain/entities/user.dart'
    as domain;

/// Firebase認証のデータソース
abstract class FirebaseAuthDatasource {
  /// メールアドレスとパスワードでサインイン
  Future<domain.User> signInWithEmail(String email, String password);

  /// Googleサインイン
  Future<domain.User> signInWithGoogle();

  /// メールアドレスとパスワードでアカウント作成
  Future<domain.User> createAccount(
      String email, String password, String displayName);

  /// サインアウト
  Future<void> signOut();

  /// 現在のユーザーを取得
  Future<domain.User?> getCurrentUser();

  /// パスワードリセットメールを送信
  Future<void> resetPassword(String email);

  /// メールアドレス認証を送信
  Future<void> sendEmailVerification();

  /// 認証状態の変更を監視
  Stream<domain.User?> watchAuthStateChanges();

  /// ユーザープロフィールを更新
  Future<domain.User> updateProfile({String? displayName, String? photoUrl});

  /// パスワードを更新
  Future<void> updatePassword(String newPassword);

  /// アカウントを削除
  Future<void> deleteAccount();
}

/// Firebase認証のデータソース実装
class FirebaseAuthDatasourceImpl implements FirebaseAuthDatasource {
  final firebase_auth.FirebaseAuth _firebaseAuth;

  const FirebaseAuthDatasourceImpl(this._firebaseAuth);

  @override
  Future<domain.User> signInWithEmail(String email, String password) async {
    try {
      final credential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'sign-in-failed',
          message: 'サインインに失敗しました',
        );
      }

      return _mapFirebaseUserToDomain(credential.user!);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: '予期しないエラーが発生しました',
      );
    }
  }

  @override
  Future<domain.User> signInWithGoogle() async {
    // TODO: Google Sign-In implementation
    throw UnimplementedError('Google Sign-In not implemented yet');
  }

  @override
  Future<domain.User> createAccount(
      String email, String password, String displayName) async {
    try {
      final credential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      if (credential.user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'account-creation-failed',
          message: 'アカウント作成に失敗しました',
        );
      }

      // プロフィールを更新
      await credential.user!.updateDisplayName(displayName);
      await credential.user!.reload();

      // 最新のユーザー情報を取得
      final updatedUser = _firebaseAuth.currentUser;
      if (updatedUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }

      return _mapFirebaseUserToDomain(updatedUser);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'unknown-error',
        message: '予期しないエラーが発生しました',
      );
    }
  }

  @override
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'sign-out-failed',
        message: 'サインアウトに失敗しました',
      );
    }
  }

  @override
  Future<domain.User?> getCurrentUser() async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return null;
      }
      return _mapFirebaseUserToDomain(firebaseUser);
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'get-current-user-failed',
        message: '現在のユーザー情報の取得に失敗しました',
      );
    }
  }

  @override
  Future<void> resetPassword(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'password-reset-failed',
        message: 'パスワードリセットに失敗しました',
      );
    }
  }

  @override
  Future<void> sendEmailVerification() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }
      await user.sendEmailVerification();
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'email-verification-failed',
        message: 'メール認証の送信に失敗しました',
      );
    }
  }

  @override
  Stream<domain.User?> watchAuthStateChanges() {
    return _firebaseAuth.authStateChanges().map((firebaseUser) {
      return firebaseUser != null
          ? _mapFirebaseUserToDomain(firebaseUser)
          : null;
    });
  }

  @override
  Future<domain.User> updateProfile(
      {String? displayName, String? photoUrl}) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }

      await user.updateDisplayName(displayName);
      await user.updatePhotoURL(photoUrl);
      await user.reload();

      final updatedUser = _firebaseAuth.currentUser;
      if (updatedUser == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }

      return _mapFirebaseUserToDomain(updatedUser);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'profile-update-failed',
        message: 'プロフィールの更新に失敗しました',
      );
    }
  }

  @override
  Future<void> updatePassword(String newPassword) async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }
      await user.updatePassword(newPassword);
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'password-update-failed',
        message: 'パスワードの更新に失敗しました',
      );
    }
  }

  @override
  Future<void> deleteAccount() async {
    try {
      final user = _firebaseAuth.currentUser;
      if (user == null) {
        throw firebase_auth.FirebaseAuthException(
          code: 'user-not-found',
          message: 'ユーザーが見つかりません',
        );
      }
      await user.delete();
    } on firebase_auth.FirebaseAuthException {
      rethrow;
    } catch (e) {
      throw firebase_auth.FirebaseAuthException(
        code: 'account-deletion-failed',
        message: 'アカウントの削除に失敗しました',
      );
    }
  }

  /// FirebaseUserをドメインUserにマッピング
  domain.User _mapFirebaseUserToDomain(firebase_auth.User firebaseUser) {
    return domain.User(
      id: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      displayName: firebaseUser.displayName,
      photoUrl: firebaseUser.photoURL,
      isEmailVerified: firebaseUser.emailVerified,
      createdAt: firebaseUser.metadata.creationTime,
      lastSignInTime: firebaseUser.metadata.lastSignInTime,
    );
  }
}
