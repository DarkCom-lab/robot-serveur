/// Rôles autorisés dans l'écosystème café robotisé.
enum UserRole {
  /// Serveur de salle (périmètre restreint, cette application)
  waiter('waiter', 'Serveur'),

  /// Gérant (accès total, dashboard administrateur séparé)
  manager('manager', 'Gérant');

  final String code;
  final String label;
  const UserRole(this.code, this.label);

  static UserRole fromCode(String code) {
    return UserRole.values.firstWhere(
      (r) => r.code.toLowerCase() == code.toLowerCase(),
      orElse: () => UserRole.waiter,
    );
  }
}
