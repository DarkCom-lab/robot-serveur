import 'package:flutter/material.dart';

/// Palette de couleurs Café / Espresso optimisée pour le service en salle.
///
/// Caractéristiques :
/// - Look sombre, haute lisibilité sous l'éclairage de restaurant
/// - Accents torréfiés (Ambre, Caramel, Crème)
/// - Codes d'état vifs (Vert Émeraude, Ambre chaud, Rouge Corail, Bleu TPE)
class AppColors {
  AppColors._();

  // Arrière-plans & Surfaces
  static const Color background = Color(0xFF131110);
  static const Color surface = Color(0xFF1E1A17);
  static const Color surfaceElevated = Color(0xFF28231F);
  static const Color surfaceHighlight = Color(0xFF352E29);
  static const Color surfaceBorder = Color(0xFF3F3732);

  // Marque & Accents Café
  static const Color primary = Color(0xFFD97706); // Ambre torréfié
  static const Color primaryLight = Color(0xFFF59E0B);
  static const Color primaryDark = Color(0xFF92400E);
  static const Color accentCream = Color(0xFFFDE68A); // Mousse de lait

  // Typographie & Contrastes
  static const Color textPrimary = Color(0xFFFDFBF7);
  static const Color textSecondary = Color(0xFFB5ACA5);
  static const Color textMuted = Color(0xFF78716C);
  static const Color textOnPrimary = Color(0xFF131110);

  // Indicateurs d'État Robot (Haute Visibilité)
  static const Color statusIdle = Color(0xFF10B981); // Vert émeraude (Libre)
  static const Color statusBusy = Color(0xFFF59E0B); // Ambre (Occupé / En mission)
  static const Color statusDelivering = Color(0xFF06B6D4); // Cyan néon
  static const Color statusCharging = Color(0xFF3B82F6); // Bleu électrique
  static const Color statusOffline = Color(0xFF6B7280); // Gris ardoise
  static const Color statusError = Color(0xFFEF4444); // Rouge corail vif

  // Niveaux de Batterie
  static const Color batteryGood = Color(0xFF10B981); // > 50%
  static const Color batteryMedium = Color(0xFFF59E0B); // 20% - 50%
  static const Color batteryLow = Color(0xFFEF4444); // < 20%

  // Étages & Zones Robot
  static const Color floorEmpty = Color(0xFF2B2521);
  static const Color floorEmptyBorder = Color(0xFF4A4039);
  static const Color floorOccupied = Color(0xFF432A15);
  static const Color floorOccupiedBorder = Color(0xFFD97706);
  static const Color zoneSelected = Color(0xFFB45309);

  // Parties du robot : vert = libre, rouge = occupé (lisible d'un coup d'œil)
  static const Color slotFree = Color(0xFF0E3B2B);
  static const Color slotFreeBorder = Color(0xFF10B981);
  static const Color slotOccupied = Color(0xFF4A1C1C);
  static const Color slotOccupiedBorder = Color(0xFFEF4444);

  // Paiement
  static const Color paymentTpe = Color(0xFF3B82F6); // Bleu TPE
  static const Color paymentCash = Color(0xFF10B981); // Vert Cash
}
