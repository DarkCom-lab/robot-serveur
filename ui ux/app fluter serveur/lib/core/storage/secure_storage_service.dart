import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Service de stockage chiffré pour les données sensibles (jeton JWT, rôle, session).
class SecureStorageService {
  final FlutterSecureStorage _storage;

  SecureStorageService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(encryptedSharedPreferences: true),
              iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
            );

  static const String _keyToken = 'auth_jwt_token';
  static const String _keyRole = 'user_role';

  Future<void> saveAuthToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<String?> getAuthToken() async {
    return await _storage.read(key: _keyToken);
  }

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _keyRole, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _keyRole);
  }

  Future<void> clearSession() async {
    await _storage.delete(key: _keyToken);
    await _storage.delete(key: _keyRole);
  }
}
