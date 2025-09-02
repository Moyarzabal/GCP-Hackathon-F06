import 'package:equatable/equatable.dart';
import 'package:barcode_scanner/core/utils/result.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// サインインのパラメーター
class SignInParams extends Equatable {
  final String email;
  final String password;

  const SignInParams({
    required this.email,
    required this.password,
  });

  @override
  List<Object> get props => [email, password];
}

/// サインインのユースケース
class SignIn {
  final AuthRepository repository;

  const SignIn(this.repository);

  /// メールアドレスとパスワードでサインイン
  Future<Result<User>> execute(SignInParams params) async {
    // バリデーション
    if (params.email.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'メールアドレスを入力してください'),
      );
    }

    if (params.password.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: 'パスワードを入力してください'),
      );
    }

    if (!_isValidEmail(params.email)) {
      return const Result.failure(
        ValidationFailure(message: '有効なメールアドレスを入力してください'),
      );
    }

    // 認証実行
    return await repository.signInWithEmail(params.email, params.password);
  }

  /// Googleサインイン
  Future<Result<User>> executeGoogleSignIn() async {
    return await repository.signInWithGoogle();
  }

  /// メールアドレスのバリデーション
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}