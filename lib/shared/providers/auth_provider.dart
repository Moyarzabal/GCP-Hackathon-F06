import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/services/auth_service.dart';

/// AuthServiceのプロバイダー
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});
