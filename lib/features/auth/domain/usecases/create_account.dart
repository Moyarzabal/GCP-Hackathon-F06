import 'package:equatable/equatable.dart';
import 'package:barcode_scanner/core/utils/result.dart';
import 'package:barcode_scanner/core/errors/failures.dart';
import '../entities/user.dart';
import '../repositories/auth_repository.dart';

/// アカウント作成のパラメーター
class CreateAccountParams extends Equatable {
  final String email;
  final String password;
  final String displayName;

  const CreateAccountParams({
    required this.email,
    required this.password,
    required this.displayName,
  });

  @override
  List<Object> get props => [email, password, displayName];
}

/// アカウント作成のユースケース
class CreateAccount {
  final AuthRepository repository;

  const CreateAccount(this.repository);

  /// アカウント作成を実行
  Future<Result<User>> execute(CreateAccountParams params) async {
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

    if (params.displayName.isEmpty) {
      return const Result.failure(
        ValidationFailure(message: '表示名を入力してください'),
      );
    }

    if (!_isValidEmail(params.email)) {
      return const Result.failure(
        ValidationFailure(message: '有効なメールアドレスを入力してください'),
      );
    }

    if (params.password.length < 6) {
      return const Result.failure(
        ValidationFailure(message: 'パスワードは6文字以上で入力してください'),
      );
    }

    // アカウント作成実行
    return await repository.createAccount(
      params.email,
      params.password,
      params.displayName,
    );
  }

  /// メールアドレスのバリデーション
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}