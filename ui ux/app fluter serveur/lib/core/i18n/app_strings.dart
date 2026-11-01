/// Textes de l'application en français avec structure prête pour l'arabe (RTL).
///
/// La structure est organisée par domaines sémantiques pour faciliter
/// la génération de fichiers .arb ou l'intégration Flutter Intl future.
class AppStrings {
  AppStrings._();

  // Général
  static const String appTitle = 'Fabtino Serveur';
  static const String back = 'Retour';
  static const String cancel = 'Annuler';
  static const String confirm = 'Confirmer';
  static const String retry = 'Réessayer';
  static const String errorGeneric = 'Une erreur est survenue';
  static const String offlineMode = 'Mode Déconnecté';

  // Auth PIN
  static const String pinLoginTitle = 'Accès Serveur';
  static const String pinLoginSubtitle = 'Saisissez votre code PIN à 4 chiffres';
  static const String pinError = 'Code PIN incorrect';
  static const String pinQuickHint = 'Code démo serveur : 1234 (Gérant : 9999)';

  // Écran 1 : État Robot
  static const String robotStatusTitle = 'État du Robot';
    static const String battery = 'Batterie';
  static const String robotStatus = 'Statut';
  static const String activeTask = 'Tâche en cours';
  static const String noActiveTask = 'Aucune mission en cours';
  static const String newOrderButton = 'Passer une commande';

  // Raisons de désactivation bouton
  static const String robotFullReason = 'Les 6 parties du robot sont occupées.';
  static const String lowBatteryReason = 'Batterie faible, le robot doit se recharger.';
  static const String offlineReason = 'Le robot est hors ligne, vérifiez la connexion.';
  static const String chargingReason = 'Le robot est en charge sur sa base.';
  static const String errorReason = 'Le robot est en incident technique.';
  static const String returningReason = 'Le robot retourne à la base, patientez.';

  // Écran 2 : Tâche
  static const String taskWizardTitle = 'Passer une commande';

  static const String noPendingOrders = 'Aucune commande en attente de livraison';

  static const String paymentModeTpe = 'Paiement par TPE';
  static const String paymentModeTpeDesc = 'Le robot vous appelle avec le TPE à son arrivée';
  static const String paymentModeNone = 'Sans TPE';
  static const String paymentModeNoneDesc = 'Cash ou commande déjà payée';

  static const String sendToRobotButton = 'Envoyer au robot';
  static const String sendingInProgress = 'Vérification et transmission en cours...';

  // Écran 3 : Suivi
  static const String taskTrackingTitle = 'Suivi de Livraison';
  static const String statusStepPending = 'En attente';
  static const String statusStepAssigned = 'Prise en charge';
  static const String statusStepDelivering = 'En livraison';
  static const String statusStepDelivered = 'Livrée à table';
  static const String backToHome = 'Retour à l\'accueil';

  // RTL Helpers
  static bool isRTL(String languageCode) => languageCode == 'ar';
}
