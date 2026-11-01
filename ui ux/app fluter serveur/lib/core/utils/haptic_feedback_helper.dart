import 'package:flutter/services.dart';

/// Helper pour les retours haptiques sur les actions critiques du service.
class HapticHelper {
  HapticHelper._();

  /// Vibration légère pour la frappe du clavier PIN ou un clic d'onglet.
  static Future<void> light() async {
    try {
      await HapticFeedback.lightImpact();
    } catch (_) {}
  }

  /// Vibration moyenne pour la sélection d'une commande ou d'un étage.
  static Future<void> medium() async {
    try {
      await HapticFeedback.mediumImpact();
    } catch (_) {}
  }

  /// Retour de succès lors de l'envoi validé au robot.
  static Future<void> success() async {
    try {
      await HapticFeedback.heavyImpact();
    } catch (_) {}
  }

  /// Alerte ou erreur.
  static Future<void> error() async {
    try {
      await HapticFeedback.vibrate();
    } catch (_) {}
  }
}
