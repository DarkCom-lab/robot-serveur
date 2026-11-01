import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/auth_repository.dart';
import '../data/mock_auth_repository.dart';
import '../data/http_auth_repository.dart';
import '../domain/auth_state.dart';

/// Fournisseur du Repository d'authentification (bascule Mock / HTTP selon AppConfig).
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (AppConfig.useMock) {
    return MockAuthRepository();
  } else {
    return HttpAuthRepository();
  }
});

/// Notifier gérant la session d'authentification.
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return AuthController(repository);
});

class AuthController extends StateNotifier<AuthState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthState.initial()) {
    checkExistingSession();
  }

  Future<void> checkExistingSession() async {
    try {
      final session = await _repository.restoreSession();
      if (session != null) {
        state = AuthState.authenticated(role: session.role, token: session.token);
      }
    } catch (_) {
      state = const AuthState.initial();
    }
  }

  Future<bool> login(String pin) async {
    state = const AuthState.loading();
    try {
      final result = await _repository.loginWithPin(pin);
      state = AuthState.authenticated(role: result.role, token: result.token);
      return true;
    } catch (e) {
      final errorMsg = e.toString().replaceAll('Exception: ', '');
      state = AuthState.error(errorMsg);
      return false;
    }
  }

  Future<void> logout() async {
    await _repository.logout();
    state = const AuthState.initial();
  }
}
