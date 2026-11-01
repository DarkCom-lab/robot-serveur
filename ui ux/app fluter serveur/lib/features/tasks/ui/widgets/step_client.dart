import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/i18n/app_strings.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../../robot/ui/robot_controller.dart';
import '../../domain/pending_order.dart';
import '../../domain/placement_option.dart';
import '../task_wizard_controller.dart';
import 'cafe_map_widget.dart';
import 'wizard_common.dart';

/// ÉTAPE 2 — Clients & Destinations multiples :
/// Sélection libre de 1, 2, 3 tables ou toutes les tables (1-10),
/// ajout/retrait et réorganisation directe de l'ordre des arrêts.
class StepClient extends ConsumerWidget {
  const StepClient({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(taskWizardControllerProvider);
    final controller = ref.read(taskWizardControllerProvider.notifier);
    final ordersAsync = ref.watch(pendingOrdersProvider);
    final robotAsync = ref.watch(robotStateStreamProvider);
    final target = wizard.targetPlacement;
    final done = wizard.count - wizard.unassignedPlacements.length;

    return ordersAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.all(48),
        child: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      ),
      error: (e, _) => Column(
        children: [
          const SizedBox(height: 32),
          const Text('Impossible de charger les commandes.', style: AppTypography.bodyLarge),
          TextButton(
            onPressed: () => ref.invalidate(pendingOrdersProvider),
            child: const Text(AppStrings.retry),
          ),
        ],
      ),
      data: (orders) {
        final byTable = <String, PendingOrder>{};
        for (final o in orders) {
          byTable.putIfAbsent(o.tableNumber, () => o);
        }

        final robot = robotAsync.valueOrNull;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            WizardStepHeader(
              title: wizard.count > 1 ? 'Quelles tables desservir ?' : 'Pour quelle table ?',
              hint: target != null
                  ? 'Touchez une table sur le plan pour la partie ${target.shortCode}.'
                  : 'Réorganisez l\'ordre avec ▲ / ▼ ou touchez une table pour la modifier.',
              trailing: CountPill(
                text: '$done / ${wizard.count}',
                color: wizard.allAssigned ? AppColors.statusIdle : AppColors.primaryLight,
              ),
            ),
            const SizedBox(height: AppDimensions.space12),

            // Raccourcis de sélection rapide de destinations
            if (robot != null)
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    _buildPresetChip('1 Table', () {
                      HapticHelper.medium();
                      controller.applyTablesPreset(robot, orders, 1);
                    }),
                    const SizedBox(width: 8),
                    _buildPresetChip('2 Tables', () {
                      HapticHelper.medium();
                      controller.applyTablesPreset(robot, orders, 2);
                    }),
                    const SizedBox(width: 8),
                    _buildPresetChip('3 Tables', () {
                      HapticHelper.medium();
                      controller.applyTablesPreset(robot, orders, 3);
                    }),
                    const SizedBox(width: 8),
                    _buildPresetChip('Toutes (${robot.freeSlotsCount})', () {
                      HapticHelper.medium();
                      controller.applyTablesPreset(robot, orders, robot.freeSlotsCount);
                    }),
                    const SizedBox(width: 8),
                    InkWell(
                      borderRadius: BorderRadius.circular(20),
                      onTap: () {
                        HapticHelper.light();
                        controller.clearSelection();
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceHighlight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: const Text('Vider', style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: AppDimensions.space12),

            // Liste des destinations attribuées avec boutons de réorganisation
            if (wizard.selectedPlacements.isNotEmpty) ...[
              _AssignmentList(
                placements: wizard.selectedPlacements,
                assignments: wizard.assignments,
                target: target,
                onTap: (p) {
                  HapticHelper.light();
                  controller.setActivePlacement(p);
                },
                onClear: (p) {
                  HapticHelper.light();
                  controller.clearAssignment(p);
                },
                onMoveUp: (index) {
                  HapticHelper.medium();
                  controller.moveDestinationUp(index);
                },
                onMoveDown: (index) {
                  HapticHelper.medium();
                  controller.moveDestinationDown(index);
                },
              ),
              const SizedBox(height: AppDimensions.space16),
            ],

            // Plan du café : toutes les tables (1 à 10) sont cliquables
            CafeMapWidget(
              ordersByTable: byTable,
              assignedCodes: {
                for (final e in wizard.assignments.entries) e.value.tableNumber: e.key.shortCode,
              },
              stopOrderNumbers: {
                for (var i = 0; i < wizard.selectedPlacements.length; i++)
                  if (wizard.assignments[wizard.selectedPlacements[i]] != null)
                    wizard.assignments[wizard.selectedPlacements[i]]!.tableNumber: i + 1,
              },
              tpeTables: {
                for (final r in wizard.requests)
                  if (r.withTpe) r.order.tableNumber,
              },
              onSelect: (order) {
                HapticHelper.light();
                if (robot != null && wizard.selectedPlacements.isEmpty) {
                  controller.togglePlacement(
                    PlacementChoice.computeBestAutoPlacement(robot) ??
                        const PlacementChoice(floorId: 1, zoneKey: 'A'),
                  );
                }
                controller.assignOrder(order);
              },
            ),
            const SizedBox(height: 16),

            if (!wizard.allAssigned && wizard.selectedPlacements.isNotEmpty)
              OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(AppDimensions.buttonHeightSecondary),
                  foregroundColor: AppColors.primaryLight,
                  side: const BorderSide(color: AppColors.primary, width: 1.5),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                label: const Text('Remplir automatiquement',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                onPressed: () {
                  HapticHelper.medium();
                  controller.autoAssign(orders);
                },
              ),
          ],
        );
      },
    );
  }

  Widget _buildPresetChip(String label, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.primary.withOpacity(0.6)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.touch_app_rounded, size: 14, color: AppColors.primaryLight),
            const SizedBox(width: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primaryLight)),
          ],
        ),
      ),
    );
  }
}

/// Liste « partie -> table » avec réorganisation de l'ordre de la tournée (▲ / ▼).
class _AssignmentList extends StatelessWidget {
  final List<PlacementChoice> placements;
  final Map<PlacementChoice, PendingOrder> assignments;
  final PlacementChoice? target;
  final ValueChanged<PlacementChoice> onTap;
  final ValueChanged<PlacementChoice> onClear;
  final ValueChanged<int> onMoveUp;
  final ValueChanged<int> onMoveDown;

  const _AssignmentList({
    required this.placements,
    required this.assignments,
    required this.target,
    required this.onTap,
    required this.onClear,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          for (var i = 0; i < placements.length; i++) ...[
            if (i > 0) const Divider(height: 1, color: AppColors.surfaceBorder),
            _row(placements[i], i),
          ],
        ],
      ),
    );
  }

  Widget _row(PlacementChoice p, int index) {
    final order = assignments[p];
    final isTarget = target == p;
    return Material(
      color: isTarget ? AppColors.primary.withOpacity(0.12) : Colors.transparent,
      child: InkWell(
        onTap: () => onTap(p),
        child: Container(
          constraints: const BoxConstraints(minHeight: 58),
          padding: const EdgeInsets.fromLTRB(10, 6, 4, 6),
          child: Row(
            children: [
              // Numéro d'arrêt
              Container(
                width: 22,
                height: 22,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  shape: BoxShape.circle,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Text(
                  '${index + 1}',
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.primaryLight),
                ),
              ),
              const SizedBox(width: 8),
              SlotCodeChip(code: p.shortCode, active: order != null || isTarget),
              const SizedBox(width: 8),
              Icon(Icons.arrow_forward_rounded,
                  size: 16, color: order != null ? AppColors.primaryLight : AppColors.textMuted),
              const SizedBox(width: 8),
              Expanded(
                child: order == null
                    ? Text(
                        isTarget ? 'Touchez une table sur le plan' : 'Table à choisir',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: isTarget ? AppColors.primaryLight : AppColors.textMuted,
                        ),
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(order.tableNumber, style: AppTypography.titleMedium),
                          Text(order.itemsSummary,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall),
                        ],
                      ),
              ),

              // Boutons de réorganisation de la tournée (▲ / ▼)
              if (placements.length > 1) ...[
                IconButton(
                  tooltip: 'Déplacer avant',
                  icon: const Icon(Icons.arrow_upward_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: index > 0 ? AppColors.primaryLight : AppColors.textMuted.withOpacity(0.3),
                  onPressed: index > 0 ? () => onMoveUp(index) : null,
                ),
                IconButton(
                  tooltip: 'Déplacer après',
                  icon: const Icon(Icons.arrow_downward_rounded, size: 18),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 30, minHeight: 30),
                  color: index < placements.length - 1 ? AppColors.primaryLight : AppColors.textMuted.withOpacity(0.3),
                  onPressed: index < placements.length - 1 ? () => onMoveDown(index) : null,
                ),
              ],

              if (order != null)
                IconButton(
                  tooltip: 'Retirer la table',
                  onPressed: () => onClear(p),
                  icon: const Icon(Icons.close_rounded, size: 18, color: AppColors.textMuted),
                )
              else
                const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
