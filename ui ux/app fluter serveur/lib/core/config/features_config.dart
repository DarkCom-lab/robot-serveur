import '../../features/auth/domain/user_role.dart';

/// Énumération de toutes les fonctionnalités de l'écosystème.
enum AppFeature {
  /// Connexion rapide par code PIN 4 chiffres
  pinLogin,

  /// Visualisation de l'état du robot (étages, batterie, statut)
  robotStatus,

  /// Création et envoi d'une tâche de livraison au robot
  createDeliveryTask,

  /// Suivi en direct d'une tâche en cours d'exécution
  trackActiveTask,

  // --- FONCTIONNALITÉS PRÉVUES MAIS DÉSACTIVÉES POUR LE SERVEUR ---

  /// Annulation d'une tâche de livraison en cours
  cancelTask,

  /// Rappel manuel du robot à sa base de recharge
  recallRobotToBase,

  /// Historique complet de toutes les livraisons passées
  deliveryHistory,

  /// Bouton d'arrêt d'urgence du robot (réservé gérant / sécurité)
  emergencyStop,

  /// Notifications push instantanées
  pushNotifications,

  /// Statistiques de service, temps moyen et métriques
  analyticsStats,
}

/// Système centralisé de gestion des fonctionnalités (Feature Flags) et des permissions.
///
/// Conformément aux exigences :
/// - Les fonctionnalités sont activées/désactivées par rôle dans cette matrice unique.
/// - L'application serveur (rôle 'waiter') a un périmètre volontairement restreint.
/// - Activer une fonctionnalité future = modifier un booléen ici + brancher la route.
///
/// NOTE SÉCURITÉ :
/// L'application valide localement ces permissions pour l'affichage de l'interface,
/// mais l'API backend valide OBLIGATOIREMENT le rôle présent dans le jeton JWT
/// sur chaque endpoint (principe de sécurité zéro-confiance).
class FeaturesConfig {
  FeaturesConfig._();

  /// Matrice des permissions par fonctionnalité et par rôle.
  static const Map<AppFeature, Map<UserRole, bool>> _permissionsMatrix = {
    // 1. Authentification par PIN
    AppFeature.pinLogin: {
      UserRole.waiter: true,
      UserRole.manager: true,
    },

    // 2. Écran État du robot (3 étages, batterie, statut)
    AppFeature.robotStatus: {
      UserRole.waiter: true,
      UserRole.manager: true,
    },

    // 3. Configurer et envoyer une tâche de livraison
    AppFeature.createDeliveryTask: {
      UserRole.waiter: true,
      UserRole.manager: true,
    },

    // 4. Suivre en direct la tâche de livraison
    AppFeature.trackActiveTask: {
      UserRole.waiter: true,
      UserRole.manager: true,
    },

    // 5. Annulation d'une tâche (DÉSACTIVÉ serveur, ACTIVÉ manager)
    AppFeature.cancelTask: {
      UserRole.waiter: false,
      UserRole.manager: true,
    },

    // 6. Rappel du robot à la base (DÉSACTIVÉ serveur, ACTIVÉ manager)
    AppFeature.recallRobotToBase: {
      UserRole.waiter: false,
      UserRole.manager: true,
    },

    // 7. Historique des livraisons (DÉSACTIVÉ serveur, ACTIVÉ manager)
    AppFeature.deliveryHistory: {
      UserRole.waiter: false,
      UserRole.manager: true,
    },

    // 8. Arrêt d'urgence (DÉSACTIVÉ serveur, ACTIVÉ manager)
    AppFeature.emergencyStop: {
      UserRole.waiter: false,
      UserRole.manager: true,
    },

    // 9. Notifications push (DÉSACTIVÉ pour tous pour l'instant)
    AppFeature.pushNotifications: {
      UserRole.waiter: false,
      UserRole.manager: false,
    },

    // 10. Statistiques & Analytics (DÉSACTIVÉ serveur, ACTIVÉ manager)
    AppFeature.analyticsStats: {
      UserRole.waiter: false,
      UserRole.manager: true,
    },
  };

  /// Vérifie si une fonctionnalité est autorisée pour un rôle donné.
  static bool isEnabled(AppFeature feature, UserRole role) {
    return _permissionsMatrix[feature]?[role] ?? false;
  }

  /// Retourne la liste des fonctionnalités disponibles pour un rôle.
  static List<AppFeature> getAvailableFeatures(UserRole role) {
    return AppFeature.values.where((f) => isEnabled(f, role)).toList();
  }

  /// Explication textuelle pour l'UI en cas de fonctionnalité désactivée.
  static String getDisabledReason(AppFeature feature) {
    switch (feature) {
      case AppFeature.cancelTask:
        return "L'annulation de tâche nécessite les privilèges Gérant.";
      case AppFeature.recallRobotToBase:
        return "Le rappel à la base est géré automatiquement ou par le Gérant.";
      case AppFeature.deliveryHistory:
        return "L'historique est disponible sur le tableau de bord Gérant.";
      case AppFeature.emergencyStop:
        return "L'arrêt d'urgence est réservé aux bornes physiques ou au Gérant.";
      case AppFeature.pushNotifications:
        return "Les notifications push seront disponibles dans une prochaine version.";
      case AppFeature.analyticsStats:
        return "Les statistiques sont réservées au tableau de bord Gérant.";
      default:
        return "Fonctionnalité non accessible pour votre profil.";
    }
  }
}
