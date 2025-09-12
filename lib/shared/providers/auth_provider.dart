import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_auth/firebase_auth.dart';

// 現在のユーザーを管理するプロバイダー
final currentUserProvider = StreamProvider<User?>((ref) {
  return FirebaseAuth.instance.authStateChanges();
});

// 認証サービスプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

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
}
