import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Statut de paiement d'une commande, gardé EN MÉMOIRE par le robot.
///
/// - [none]       : pas de TPE (déjà payé, espèces...).
/// - [tpePending] : le client paiera par TPE. Le robot le sait, aucun rappel
///                  ni alerte n'est envoyé au serveur.
/// - [tpePaid]    : le client a appuyé sur « J'ai terminé » sur le robot.
///                  Le robot annonce « C'est bon, paiement validé ».
enum PaymentStatus {
  none('none', 'Sans TPE', Icons.check_circle_outline_rounded, AppColors.textMuted),
  tpePending('tpe_pending', 'TPE en attente', Icons.contactless_rounded, AppColors.paymentTpe),
  tpePaid('tpe_paid', 'Payé', Icons.verified_rounded, AppColors.statusIdle);

  /// Code échangé avec le backend.
  final String code;
  final String label;
  final IconData icon;
  final Color color;

  const PaymentStatus(this.code, this.label, this.icon, this.color);

  /// Phrase dite par le robot quand le client a fini de payer.
  static const String paidAnnouncement = "C'est bon, paiement validé";

  /// La commande passe par le TPE (en attente ou déjà payée).
  bool get usesTpe => this != PaymentStatus.none;

  static PaymentStatus fromCode(String? code) {
    if (code == null) return PaymentStatus.none;
    return PaymentStatus.values.firstWhere(
      (s) => s.code == code.toLowerCase(),
      orElse: () => PaymentStatus.none,
    );
  }

  /// Statut de départ : TPE -> en attente, sinon aucun.
  static PaymentStatus initial({required bool withTpe}) =>
      withTpe ? PaymentStatus.tpePending : PaymentStatus.none;
}
