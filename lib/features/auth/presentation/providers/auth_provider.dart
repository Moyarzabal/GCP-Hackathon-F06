import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/errors/app_exception.dart';
import '../../../../core/errors/result.dart';

/// ユーザー情報を表すクラス
class User {
  final String id;
  final String email;
  final String? displayName;
  final String? photoUrl;
  final bool isEmailVerified;

  const User({
    required this.id,
    required this.email,
    this.displayName,
    this.photoUrl,
    this.isEmailVerified = false,
  });

  User copyWith({
    String? id,
    String? email,
    String? displayName,
    String? photoUrl,
    bool? isEmailVerified,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      photoUrl: photoUrl ?? this.photoUrl,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    );
  }
}

/// 認証状態を表すクラス
class AuthState {
  final User? user;
  final bool isLoading;
  final bool isAuthenticated;
  final String? error;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.isAuthenticated = false,
    this.error,
  });

  AuthState copyWith({
    User? user,
    bool? isLoading,
    bool? isAuthenticated,
    String? error,
  }) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      error: error ?? this.error,
    );
  }
}

/// 認証状態を管理するStateNotifier
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState()) {
    // 初期状態で認証状態をチェック
    _checkAuthStatus();
  }

  /// 認証状態をチェック
  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // TODO: 実際の認証状態チェックを実装
      // 現在は仮実装で認証済みとする
      await Future.delayed(const Duration(seconds: 1));
      
      const user = User(
        id: 'dummy_user_id',
        email: 'user@example.com',
        displayName: 'テストユーザー',
        isEmailVerified: true,
      );
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
    } catch (e, stackTrace) {
      final exception = AuthException(
        '認証状態の確認に失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  /// メールアドレスとパスワードでログイン
  Future<Result<User>> signInWithEmail(String email, String password) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // バリデーション
      if (email.isEmpty || password.isEmpty) {
        throw const AuthException('メールアドレスとパスワードを入力してください');
      }
      
      if (!_isValidEmail(email)) {
        throw const AuthException('有効なメールアドレスを入力してください');
      }
      
      // TODO: 実際のログイン処理を実装
      await Future.delayed(const Duration(seconds: 2));
      
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        displayName: email.split('@').first,
        isEmailVerified: true,
      );
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      
      return Result.success(user);
    } catch (e, stackTrace) {
      final exception = e is AuthException 
          ? e 
          : AuthException(
              'ログインに失敗しました',
              details: e.toString(),
              stackTrace: stackTrace,
            );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      
      return Result.failure(exception);
    }
  }

  /// Googleサインイン
  Future<Result<User>> signInWithGoogle() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // TODO: 実際のGoogleサインイン処理を実装
      await Future.delayed(const Duration(seconds: 2));
      
      const user = User(
        id: 'google_user_id',
        email: 'google.user@gmail.com',
        displayName: 'Google User',
        photoUrl: 'https://example.com/photo.jpg',
        isEmailVerified: true,
      );
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      
      return Result.success(user);
    } catch (e, stackTrace) {
      final exception = AuthException(
        'Googleサインインに失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      
      return Result.failure(exception);
    }
  }

  /// メールアドレスとパスワードでアカウント作成
  Future<Result<User>> createAccount(String email, String password, String displayName) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // バリデーション
      if (email.isEmpty || password.isEmpty || displayName.isEmpty) {
        throw const AuthException('すべてのフィールドを入力してください');
      }
      
      if (!_isValidEmail(email)) {
        throw const AuthException('有効なメールアドレスを入力してください');
      }
      
      if (password.length < 6) {
        throw const AuthException('パスワードは6文字以上で入力してください');
      }
      
      // TODO: 実際のアカウント作成処理を実装
      await Future.delayed(const Duration(seconds: 2));
      
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        email: email,
        displayName: displayName,
        isEmailVerified: false,
      );
      
      state = state.copyWith(
        user: user,
        isAuthenticated: true,
        isLoading: false,
      );
      
      return Result.success(user);
    } catch (e, stackTrace) {
      final exception = e is AuthException 
          ? e 
          : AuthException(
              'アカウント作成に失敗しました',
              details: e.toString(),
              stackTrace: stackTrace,
            );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      
      return Result.failure(exception);
    }
  }

  /// ログアウト
  Future<Result<void>> signOut() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      // TODO: 実際のログアウト処理を実装
      await Future.delayed(const Duration(seconds: 1));
      
      state = state.copyWith(
        user: null,
        isAuthenticated: false,
        isLoading: false,
      );
      
      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = AuthException(
        'ログアウトに失敗しました',
        details: e.toString(),
        stackTrace: stackTrace,
      );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      
      return Result.failure(exception);
    }
  }

  /// パスワードリセット
  Future<Result<void>> resetPassword(String email) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      if (!_isValidEmail(email)) {
        throw const AuthException('有効なメールアドレスを入力してください');
      }
      
      // TODO: 実際のパスワードリセット処理を実装
      await Future.delayed(const Duration(seconds: 2));
      
      state = state.copyWith(isLoading: false);
      return Result.success(null);
    } catch (e, stackTrace) {
      final exception = e is AuthException 
          ? e 
          : AuthException(
              'パスワードリセットに失敗しました',
              details: e.toString(),
              stackTrace: stackTrace,
            );
      
      state = state.copyWith(
        error: exception.message,
        isLoading: false,
      );
      
      return Result.failure(exception);
    }
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// メールアドレスバリデーション
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// 現在のユーザーを取得するプロバイダー
final currentUserProvider = Provider<User?>((ref) {
  return ref.watch(authProvider).user;
});

/// 認証状態を取得するプロバイダー
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// ローディング状態を取得するプロバイダー
final isAuthLoadingProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isLoading;
});