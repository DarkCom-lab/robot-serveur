import '../domain/user_role.dart';

/// Résultat d'une authentification réussie.
class AuthResult {
  final String token;
  final UserRole role;

  const AuthResult({required this.token, required this.role});
}

/// Interface abstraite pour le service d'authentification.
abstract class AuthRepository {
  /// Authentifie un utilisateur via son code PIN à 4 chiffres.
  ///
  /// Endpoint backend réel :
  /// POST /api/auth/login -> { "token": "jwt...", "role": "waiter" | "manager" }
  Future<AuthResult> loginWithPin(String pin);

  /// Déconnexion et révocation locale du jeton.
  Future<void> logout();

  /// Récupère la session persistée si elle est encore valide.
  Future<AuthResult?> restoreSession();
}
