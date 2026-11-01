import 'user_role.dart';

/// État immuable de la session d'authentification.
class AuthState {
  final bool isAuthenticated;
  final bool isLoading;
  final UserRole? role;
  final String? token;
  final String? errorMessage;

  const AuthState({
    this.isAuthenticated = false,
    this.isLoading = false,
    this.role,
    this.token,
    this.errorMessage,
  });

  const AuthState.initial()
      : isAuthenticated = false,
        isLoading = false,
        role = null,
        token = null,
        errorMessage = null;

  const AuthState.loading()
      : isAuthenticated = false,
        isLoading = true,
        role = null,
        token = null,
        errorMessage = null;

  const AuthState.authenticated({
    required this.role,
    required this.token,
  })  : isAuthenticated = true,
        isLoading = false,
        errorMessage = null;

  const AuthState.error(String message)
      : isAuthenticated = false,
        isLoading = false,
        role = null,
        token = null,
        errorMessage = message;

  AuthState copyWith({
    bool? isAuthenticated,
    bool? isLoading,
    UserRole? role,
    String? token,
    String? errorMessage,
  }) {
    return AuthState(
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      role: role ?? this.role,
      token: token ?? this.token,
      errorMessage: errorMessage,
    );
  }
}
