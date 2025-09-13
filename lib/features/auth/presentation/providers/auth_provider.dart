import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/services/service_locator.dart';
import '../../domain/entities/user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/sign_in.dart';
import '../../domain/usecases/sign_out.dart';
import '../../domain/usecases/create_account.dart';

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
  final AuthRepository _authRepository;
  final SignIn _signIn;
  final SignOut _signOut;
  final CreateAccount _createAccount;

  AuthNotifier(
    this._authRepository,
    this._signIn,
    this._signOut,
    this._createAccount,
  ) : super(const AuthState()) {
    // 初期状態で認証状態をチェック
    _checkAuthStatus();
    // 認証状態の変更を監視
    _watchAuthStateChanges();
  }

  /// 認証状態をチェック
  Future<void> _checkAuthStatus() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      
      final result = await _authRepository.getCurrentUser();
      
      result.fold(
        (failure) {
          state = state.copyWith(
            error: failure.message,
            isLoading: false,
            isAuthenticated: false,
          );
        },
        (user) {
          state = state.copyWith(
            user: user,
            isAuthenticated: user != null,
            isLoading: false,
          );
        },
      );
    } catch (e) {
      state = state.copyWith(
        error: '認証状態の確認に失敗しました',
        isLoading: false,
        isAuthenticated: false,
      );
    }
  }

  /// 認証状態の変更を監視
  void _watchAuthStateChanges() {
    _authRepository.watchAuthStateChanges().listen((user) {
      state = state.copyWith(
        user: user,
        isAuthenticated: user != null,
        error: null,
      );
    });
  }

  /// メールアドレスとパスワードでログイン
  Future<Result<User>> signInWithEmail(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _signIn.execute(SignInParams(
      email: email,
      password: password,
    ));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
        return Result.failure(failure);
      },
      (user) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return Result.success(user);
      },
    );
  }

  /// Googleサインイン
  Future<Result<User>> signInWithGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _signIn.executeGoogleSignIn();
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
        return Result.failure(failure);
      },
      (user) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return Result.success(user);
      },
    );
  }

  /// メールアドレスとパスワードでアカウント作成
  Future<Result<User>> createAccount(String email, String password, String displayName) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _createAccount.execute(CreateAccountParams(
      email: email,
      password: password,
      displayName: displayName,
    ));
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
        return Result.failure(failure);
      },
      (user) {
        state = state.copyWith(
          user: user,
          isAuthenticated: true,
          isLoading: false,
        );
        return Result.success(user);
      },
    );
  }

  /// ログアウト
  Future<Result<void>> signOut() async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _signOut.execute();
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
        return Result.failure(failure);
      },
      (_) {
        state = state.copyWith(
          user: null,
          isAuthenticated: false,
          isLoading: false,
        );
        return const Result.success(null);
      },
    );
  }

  /// パスワードリセット
  Future<Result<void>> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    final result = await _authRepository.resetPassword(email);
    
    return result.fold(
      (failure) {
        state = state.copyWith(
          error: failure.message,
          isLoading: false,
        );
        return Result.failure(failure);
      },
      (_) {
        state = state.copyWith(isLoading: false);
        return const Result.success(null);
      },
    );
  }

  /// エラーをクリア
  void clearError() {
    state = state.copyWith(error: null);
  }

}

/// 認証プロバイダー
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final serviceLocator = ServiceLocator.instance;
  return AuthNotifier(
    serviceLocator.get<AuthRepository>(),
    serviceLocator.get<SignIn>(),
    serviceLocator.get<SignOut>(),
    serviceLocator.get<CreateAccount>(),
  );
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