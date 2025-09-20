import 'package:firebase_auth/firebase_auth.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // 現在のユーザーを取得
  User? get currentUser => _auth.currentUser;

  // ユーザーがログインしているかチェック
  bool get isLoggedIn => currentUser != null;

  // ログアウト
  Future<void> signOut() async {
    await _auth.signOut();
  }

  // ユーザーIDを取得
  String? get userId => currentUser?.uid;

  // ユーザー情報を取得
  Map<String, dynamic>? get userInfo {
    final user = currentUser;
    if (user == null) return null;

    return {
      'uid': user.uid,
      'email': user.email,
      'displayName': user.displayName,
      'photoURL': user.photoURL,
    };
  }

  // メールアドレスでサインアップ
  Future<UserCredential?> signUpWithEmail(String email, String password, [String? displayName]) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 表示名を設定
      if (displayName != null && displayName.isNotEmpty) {
        await credential.user?.updateDisplayName(displayName);
      }

      return credential;
    } catch (e) {
      print('Sign up error: $e');
      return null;
    }
  }

  // メールアドレスでサインイン
  Future<UserCredential?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      return credential;
    } catch (e) {
      print('Sign in error: $e');
      return null;
    }
  }

  // Googleでサインイン（一時的に無効化）
  Future<UserCredential?> signInWithGoogle() async {
    try {
      // TODO: Implement Google Sign-In when google_sign_in package is available
      print('Google Sign-In temporarily disabled');
      return null;
    } catch (e) {
      print('Google Sign-In error: $e');
      return null;
    }
  }

  // Appleでサインイン（一時的に無効化）
  Future<UserCredential?> signInWithApple() async {
    try {
      // TODO: Implement Apple Sign-In when sign_in_with_apple package is available
      print('Apple Sign-In temporarily disabled');
      return null;
    } catch (e) {
      print('Apple Sign-In error: $e');
      return null;
    }
  }
}
