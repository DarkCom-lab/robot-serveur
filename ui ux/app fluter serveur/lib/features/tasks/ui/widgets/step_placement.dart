import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../robot/domain/robot_state.dart';
import '../../../robot/ui/widgets/robot_slots_view.dart';
import '../task_wizard_controller.dart';
import 'wizard_common.dart';

/// ÉTAPE 1 — Plateau : je touche UNE OU PLUSIEURS parties vertes.
class StepPlacement extends ConsumerWidget {
  final RobotStateModel robot;
  const StepPlacement({super.key, required this.robot});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(taskWizardControllerProvider);
    final controller = ref.read(taskWizardControllerProvider.notifier);
    final waitingTables = ref.watch(pendingOrdersProvider).maybeWhen(
          data: (orders) => orders.map((o) => o.tableNumber).toSet().length,
          orElse: () => null,
        );
    final free = robot.freeSlotsCount;
    final allChosen = wizard.count >= free;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WizardStepHeader(
          title: 'Où poser les plateaux ?',
          hint: free > 1
              ? 'Touchez les parties vertes. Vous pouvez en choisir plusieurs.'
              : 'Touchez la partie verte.',
          trailing: CountPill(
            text: '${wizard.count} / $free',
            color: wizard.count > 0 ? AppColors.primaryLight : AppColors.textMuted,
          ),
        ),
        const SizedBox(height: AppDimensions.space16),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 12, 10, 12),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
            border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              RobotSlotsView(
                floors: robot.floors,
                selected: wizard.selectedPlacements,
                onToggle: (choice) {
                  HapticHelper.light();
                  controller.togglePlacement(choice);
                },
              ),
              const SizedBox(height: 12),
              const RobotSlotsLegend(showSelected: true, showTpe: false),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                key: const ValueKey('auto-select'),
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeightSecondary),
                  foregroundColor: AppColors.primaryLight,
                  side: BorderSide(
                      color: allChosen ? AppColors.surfaceBorder : AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Choisir pour moi',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: allChosen
                    ? null
                    : () {
                        // Autant de parties que de tables en attente ; si c'est
                        // déjà le cas, on complète avec toutes les parties libres.
                        var wanted = (waitingTables ?? free).clamp(1, free);
                        if (wanted <= wizard.count) wanted = free;
                        if (controller.autoSelect(robot, wanted: wanted) > 0) {
                          HapticHelper.medium();
                        }
                      },
              ),
            ),
            if (wizard.count > 0) ...[
              const SizedBox(width: 10),
              SizedBox(
                height: AppDimensions.buttonHeightSecondary,
                child: TextButton(
                  style: TextButton.styleFrom(foregroundColor: AppColors.textSecondary),
                  onPressed: () {
                    HapticHelper.light();
                    controller.clearSelection();
                  },
                  child: const Text('Tout enlever'),
                ),
              ),
            ],
          ],
        ),
        if (waitingTables != null) ...[
          const SizedBox(height: 10),
          Text(
            waitingTables == 0
                ? 'Aucune table n\'attend de commande pour le moment.'
                : waitingTables == 1
                    ? '1 table attend sa commande.'
                    : '$waitingTables tables attendent leur commande.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 13, color: AppColors.textMuted),
          ),
        ],
      ],
    );
  }
}
