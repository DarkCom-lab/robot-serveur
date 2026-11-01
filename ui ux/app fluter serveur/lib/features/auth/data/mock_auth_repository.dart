import 'dart:async';
import '../domain/user_role.dart';
import 'auth_repository.dart';
import '../../../core/storage/secure_storage_service.dart';

/// Implémentation MOCK simulant le service d'authentification.
///
/// PINs de test pré-configurés :
/// - '1234' -> Rôle Serveur (waiter)
/// - '9999' -> Rôle Gérant (manager)
class MockAuthRepository implements AuthRepository {
  final SecureStorageService _secureStorage;

  MockAuthRepository({SecureStorageService? secureStorage})
      : _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<AuthResult> loginWithPin(String pin) async {
    // Simule une latence réseau réaliste
    await Future.delayed(const Duration(milliseconds: 400));

    if (pin == '1234') {
      const token = 'mock_jwt_waiter_token_valid';
      await _secureStorage.saveAuthToken(token);
      await _secureStorage.saveUserRole(UserRole.waiter.code);
      return const AuthResult(token: token, role: UserRole.waiter);
    } else if (pin == '9999') {
      const token = 'mock_jwt_manager_token_valid';
      await _secureStorage.saveAuthToken(token);
      await _secureStorage.saveUserRole(UserRole.manager.code);
      return const AuthResult(token: token, role: UserRole.manager);
    } else {
      throw Exception('Code PIN non reconnu. Veuillez réessayer.');
    }
  }

  @override
  Future<void> logout() async {
    await _secureStorage.clearSession();
  }

  @override
  Future<AuthResult?> restoreSession() async {
    final token = await _secureStorage.getAuthToken();
    final roleCode = await _secureStorage.getUserRole();
    if (token != null && roleCode != null) {
      return AuthResult(token: token, role: UserRole.fromCode(roleCode));
    }
    return null;
  }
}
