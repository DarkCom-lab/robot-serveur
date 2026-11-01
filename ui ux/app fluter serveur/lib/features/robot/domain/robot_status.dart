import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Statuts opérationnels du robot livreur autonome.
enum RobotStatus {
  idle('idle', 'En attente', AppColors.statusIdle, Icons.check_circle_outline),
  busy('busy', 'Occupé', AppColors.statusBusy, Icons.hourglass_top_rounded),
  delivering('delivering', 'En livraison', AppColors.statusDelivering, Icons.local_shipping_outlined),
  returning('returning', 'Retour à la base', AppColors.statusBusy, Icons.u_turn_left_rounded),
  charging('charging', 'En charge', AppColors.statusCharging, Icons.bolt_rounded),
  offline('offline', 'Hors ligne', AppColors.statusOffline, Icons.cloud_off_rounded),
  error('error', 'En erreur', AppColors.statusError, Icons.warning_amber_rounded);

  final String code;
  final String label;
  final Color color;
  final IconData icon;

  const RobotStatus(this.code, this.label, this.color, this.icon);

  static RobotStatus fromCode(String code) {
    return RobotStatus.values.firstWhere(
      (s) => s.code.toLowerCase() == code.toLowerCase(),
      orElse: () => RobotStatus.idle,
    );
  }

  /// Indique si le robot est en état de marche physique (pas en panne ni déconnecté ni en charge).
  bool get isOperational => this != RobotStatus.offline && this != RobotStatus.error && this != RobotStatus.charging;
}
