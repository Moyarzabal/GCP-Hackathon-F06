import 'package:barcode_scanner/core/utils/result.dart';
import '../repositories/auth_repository.dart';

/// サインアウトのユースケース
class SignOut {
  final AuthRepository repository;

  const SignOut(this.repository);

  /// サインアウトを実行
  Future<Result<void>> execute() async {
    return await repository.signOut();
  }
}
