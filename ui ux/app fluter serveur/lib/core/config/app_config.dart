/// Configuration globale de l'application Serveur.
///
/// Permet de basculer en un seul endroit entre l'environnement de simulation MOCK
/// et le serveur backend réel de production ou de staging.
class AppConfig {
  AppConfig._();

  /// Mode MOCK activé par défaut pour les tests et la démonstration autonome.
  /// Mettre à `false` pour brancher les vrais endpoints HTTP et WebSocket.
  static const bool useMock = true;

  /// URL de base du backend API REST.
  /// Exemple prod : 'https://api.cafe-robot.com' ou 'http://192.168.1.100:8080'
  static const String apiBaseUrl = 'http://192.168.1.100:8080';

  /// URL du WebSocket pour les événements robot en direct.
  static const String wsUrl = 'ws://192.168.1.100:8080/ws/robot';

  /// Seuil de batterie critique (%) en dessous duquel le robot refuse toute nouvelle tâche.
  static const int lowBatteryThreshold = 20;

  /// Intervalle de rafraîchissement périodique (fallback si pas de WS) en millisecondes.
  static const int pollingIntervalMs = 3000;

  /// Timeout par défaut des requêtes réseau HTTP en secondes.
  static const Duration requestTimeout = Duration(seconds: 10);

  /// Nom de l'application affiché dans la barre de titre.
  static const String appName = 'Fabtino Serveur';

  /// Version de l'application.
  static const String appVersion = '1.0.0 (Build 12)';
}
