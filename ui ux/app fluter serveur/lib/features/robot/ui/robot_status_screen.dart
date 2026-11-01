import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/utils/haptic_feedback_helper.dart';
import '../../auth/ui/auth_controller.dart';
import '../../tasks/ui/widgets/tables_overview_view.dart';
import '../domain/robot_state.dart';
import '../domain/robot_status.dart';
import 'robot_controller.dart';
import 'widgets/battery_indicator_widget.dart';
import 'widgets/robot_slots_view.dart';
import 'widgets/robot_status_badge.dart';
import 'widgets/simulation_debug_sheet.dart';

/// ÉCRAN PRINCIPAL : STATUT DU ROBOT ET VUE DES TABLES
///
/// Comprend :
/// - Onglet 1 : Vue Robot Fabtino (bandeau d'identité épuré, batterie, plateaux 1-3, bouton de commande)
/// - Onglet 2 : Vue des Tables & TPE (suivi temps réel et persistant des 10 tables avec statuts TPE)
class RobotStatusScreen extends ConsumerStatefulWidget {
  const RobotStatusScreen({super.key});

  @override
  ConsumerState<RobotStatusScreen> createState() => _RobotStatusScreenState();
}

class _RobotStatusScreenState extends ConsumerState<RobotStatusScreen> {
  int _selectedTabIndex = 0; // 0 = Robot, 1 = Tables & TPE

  void _openSimulationSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const SimulationDebugSheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final robotAsync = ref.watch(robotStateStreamProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text(
          _selectedTabIndex == 0 ? AppStrings.robotStatusTitle : 'Tables & Paiements TPE',
          style: AppTypography.titleLarge,
        ),
        actions: [
          IconButton(
            tooltip: 'Simulateur d\'état',
            icon: const Icon(Icons.tune_rounded, color: AppColors.primaryLight),
            onPressed: () => _openSimulationSheet(context),
          ),
          IconButton(
            tooltip: 'Déconnexion',
            icon: const Icon(Icons.logout_rounded, color: AppColors.textMuted),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Sélecteur d'onglets ergonomique en haut de l'écran
          Container(
            margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Row(
              children: [
                _buildTabButton('Robot Fabtino', Icons.smart_toy_rounded, _selectedTabIndex == 0, () {
                  HapticHelper.light();
                  setState(() => _selectedTabIndex = 0);
                }),
                _buildTabButton('Vue Tables & TPE', Icons.table_restaurant_rounded, _selectedTabIndex == 1, () {
                  HapticHelper.light();
                  setState(() => _selectedTabIndex = 1);
                }),
              ],
            ),
          ),

          // Contenu principal selon l'onglet
          Expanded(
            child: _selectedTabIndex == 1
                ? const TablesOverviewView()
                : robotAsync.when(
                    loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
                    error: (err, stack) => Center(
                      child: Padding(
                        padding: const EdgeInsets.all(AppDimensions.space24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.error_outline_rounded, color: AppColors.statusError, size: 48),
                            const SizedBox(height: 12),
                            const Text(AppStrings.errorGeneric,
                                style: AppTypography.bodyLarge, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () => ref.invalidate(robotStateStreamProvider),
                              child: const Text(AppStrings.retry),
                            ),
                          ],
                        ),
                      ),
                    ),
                    data: (robot) => _buildRobotContent(context, ref, robot),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabButton(String label, IconData icon, bool isSelected, VoidCallback onTap) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.35),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    )
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: isSelected ? AppColors.textOnPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRobotContent(BuildContext context, WidgetRef ref, RobotStateModel robot) {
    final isFree = robot.canAcceptNewTask;
    final canDispatch = robot.storedOrdersCount > 0 &&
        robot.status.isOperational &&
        robot.status != RobotStatus.delivering &&
        !robot.isLowBattery;

    return SafeArea(
      child: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Bandeau moderne épuré et informatif pour l'identité du robot (sans photo floue)
                  _buildRobotIdentityHeader(context, robot),
                  const SizedBox(height: AppDimensions.space16),

                  _buildAvailabilityCard(robot, isFree),
                  const SizedBox(height: AppDimensions.space16),

                  if (robot.status == RobotStatus.delivering) ...[
                    _buildDeliveryCard(context, robot),
                    const SizedBox(height: AppDimensions.space16),
                  ],
                  if (robot.storedOrdersCount > 0) ...[
                    _buildStoredCard(ref, robot.storedOrdersCount, canDispatch),
                    const SizedBox(height: AppDimensions.space16),
                  ],

                  // Vue des 3 étages du robot
                  Container(
                    padding: const EdgeInsets.fromLTRB(10, 14, 10, 14),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
                      border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Row(
                            children: [
                              const Text('Plateaux du robot', style: AppTypography.titleMedium),
                              const Spacer(),
                              Text(
                                '${robot.occupiedSlotsCount}/${RobotStateModel.totalSlots} occupées',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textMuted,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        RobotSlotsView(floors: robot.floors),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Bouton d'action principal
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: SizedBox(
              height: AppDimensions.buttonHeightPrimary,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.add_shopping_cart_rounded, size: 24),
                label: const Text('Passer des commandes'),
                onPressed: isFree
                    ? () {
                        HapticHelper.medium();
                        context.push('/task-wizard');
                      }
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Bandeau moderne épuré présentant l'identité du robot (remplace la photo floue).
  Widget _buildRobotIdentityHeader(BuildContext context, RobotStateModel robot) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
        gradient: LinearGradient(
          colors: [
            AppColors.surfaceElevated,
            AppColors.surfaceHighlight.withOpacity(0.4),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.16),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.primary, width: 1.8),
                ),
                child: const Icon(
                  Icons.smart_toy_rounded,
                  color: AppColors.primaryLight,
                  size: 30,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('FABTINO 01', style: AppTypography.titleLarge),
                    SizedBox(height: 2),
                    Text('Robot Serveur Autonome', style: AppTypography.labelSmall),
                  ],
                ),
              ),
              RobotStatusBadge(status: robot.status),
            ],
          ),
          const SizedBox(height: 14),
          const Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              BatteryIndicatorWidget(
                percentage: robot.batteryPercentage,
                isCharging: robot.isCharging,
              ),
              const Row(
                children: [
                  Icon(Icons.wifi_rounded, size: 16, color: AppColors.statusIdle),
                  SizedBox(width: 4),
                  Text(
                    'Wi-Fi 5GHz',
                    style: TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              Text(
                '${robot.freeSlotsCount}/${RobotStateModel.totalSlots} libres',
                style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAvailabilityCard(RobotStateModel robot, bool isFree) {
    final color = isFree ? AppColors.statusIdle : AppColors.statusBusy;
    final title = isFree ? 'ROBOT LIBRE' : 'ROBOT NON DISPONIBLE';
    final subtitle = isFree
        ? '${robot.freeSlotsCount} partie(s) libre(s) sur ${RobotStateModel.totalSlots}'
        : (robot.disabledReason ?? '');

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color, width: 2),
      ),
      child: Row(
        children: [
          Icon(
            isFree ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
            color: color,
            size: 44,
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.displayLarge.copyWith(color: color)),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(subtitle, style: AppTypography.bodyLarge),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDeliveryCard(BuildContext context, RobotStateModel robot) {
    final table = robot.activeDestinationTable;
    final batchId = robot.activeTaskId;
    return Material(
      color: AppColors.statusDelivering.withOpacity(0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        side: BorderSide(color: AppColors.statusDelivering.withOpacity(0.4)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        onTap: batchId != null ? () => context.push('/task-tracking/$batchId') : null,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              const Icon(Icons.navigation_rounded, color: AppColors.statusDelivering),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  table != null ? 'Livraison en cours vers $table' : 'Livraison en cours…',
                  style: AppTypography.labelLarge,
                ),
              ),
              if (batchId != null) ...[
                const Text(
                  'Suivre',
                  style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.statusDelivering),
                ),
                const Icon(Icons.chevron_right_rounded, color: AppColors.statusDelivering),
              ],
            ],
          ),
        ),
      ),
    );
  }

  /// Commandes rangées dans le robot, en attente de départ.
  Widget _buildStoredCard(WidgetRef ref, int count, bool canDispatch) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.primary.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.schedule_rounded, color: AppColors.primaryLight),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  count == 1
                      ? '1 commande rangée, en attente de départ'
                      : '$count commandes rangées, en attente de départ',
                  style: AppTypography.titleMedium,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_arrow_rounded),
            label: const Text('Envoyer le robot maintenant'),
            onPressed: canDispatch
                ? () {
                    HapticHelper.medium();
                    ref.read(robotActionControllerProvider).dispatchStored();
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
