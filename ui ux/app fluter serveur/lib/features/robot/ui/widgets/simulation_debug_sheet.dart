import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/robot_status.dart';
import '../robot_controller.dart';

/// Tiroir modal permettant de tester et déclencher toutes les variations d'état exigées.
class SimulationDebugSheet extends ConsumerWidget {
  const SimulationDebugSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = ref.read(robotActionControllerProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Barre de glissement
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.surfaceBorder,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Simulateur d\'état du Robot (Tests MOCK)',
            style: AppTypography.titleLarge,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          const Text(
            'Basculez instantanément le robot dans différents états pour valider les règles de blocage et de réactivation.',
            style: AppTypography.bodyMedium,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Boutons de tests rapides
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _buildBtn(
                context,
                label: 'Robot Complet (6/6)',
                icon: Icons.layers,
                color: AppColors.primary,
                onTap: () {
                  actions.occupyAllSlots();
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'À moitié plein',
                icon: Icons.view_agenda_outlined,
                color: AppColors.primaryLight,
                onTap: () {
                  actions.halfOccupied();
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'Vider le Robot (6/6 libres)',
                icon: Icons.delete_sweep_outlined,
                color: AppColors.statusIdle,
                onTap: () {
                  actions.freeAllSlots();
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'Batterie Faible (14%)',
                icon: Icons.battery_alert_rounded,
                color: AppColors.statusError,
                onTap: () {
                  actions.setBattery(14);
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'Batterie 90%',
                icon: Icons.battery_full_rounded,
                color: AppColors.statusIdle,
                onTap: () {
                  actions.setBattery(90);
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'En Charge',
                icon: Icons.bolt_rounded,
                color: AppColors.statusCharging,
                onTap: () {
                  actions.setStatus(RobotStatus.charging);
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'En Erreur',
                icon: Icons.warning_rounded,
                color: AppColors.statusError,
                onTap: () {
                  actions.setStatus(RobotStatus.error);
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'Hors Ligne',
                icon: Icons.cloud_off_rounded,
                color: AppColors.statusOffline,
                onTap: () {
                  actions.setStatus(RobotStatus.offline);
                  Navigator.pop(context);
                },
              ),
              _buildBtn(
                context,
                label: 'En Attente (Idle)',
                icon: Icons.check_circle_outline_rounded,
                color: AppColors.statusIdle,
                onTap: () {
                  actions.setStatus(RobotStatus.idle);
                  Navigator.pop(context);
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBtn(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.surfaceElevated,
        foregroundColor: color,
        side: BorderSide(color: color.withOpacity(0.5), width: 1.2),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        minimumSize: const Size(150, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}
