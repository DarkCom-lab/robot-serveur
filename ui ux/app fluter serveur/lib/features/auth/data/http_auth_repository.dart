import 'dart:async';
import '../../../core/network/api_client.dart';
import '../../../core/storage/secure_storage_service.dart';
import '../domain/user_role.dart';
import 'auth_repository.dart';

/// Implémentation HTTP réelle prête à l'emploi.
///
/// Endpoint appelé :
/// POST /api/auth/login
/// Body : { "pin": "1234" }
/// Response : { "token": "eyJh...", "role": "waiter" }
class HttpAuthRepository implements AuthRepository {
  final ApiClient _apiClient;
  final SecureStorageService _secureStorage;

  HttpAuthRepository({
    ApiClient? apiClient,
    SecureStorageService? secureStorage,
  })  : _apiClient = apiClient ?? ApiClient(),
        _secureStorage = secureStorage ?? SecureStorageService();

  @override
  Future<AuthResult> loginWithPin(String pin) async {
    final response = await _apiClient.post(
      '/api/auth/login',
      body: {'pin': pin},
    );

    if (response is Map<String, dynamic>) {
      final token = response['token'] as String;
      final roleStr = response['role'] as String? ?? 'waiter';
      final role = UserRole.fromCode(roleStr);

      await _secureStorage.saveAuthToken(token);
      await _secureStorage.saveUserRole(role.code);

      return AuthResult(token: token, role: role);
    } else {
      throw ApiException(statusCode: 500, message: 'Format de réponse invalide');
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
