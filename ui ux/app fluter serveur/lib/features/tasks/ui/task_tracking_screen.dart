import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/config/app_config.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/utils/haptic_feedback_helper.dart';
import '../../robot/domain/payment_status.dart';
import '../../robot/ui/widgets/robot_slots_view.dart';
import '../domain/task_model.dart';
import 'task_tracking_controller.dart';
import 'task_wizard_controller.dart';
import 'widgets/wizard_common.dart';

/// ÉCRAN 3 : SUIVI DE LA LIVRAISON.
///
/// Une opération peut contenir plusieurs commandes : on voit la progression
/// de la tournée, puis chaque arrêt (partie -> table) avec son statut de
/// paiement (Sans TPE / TPE en attente / Payé).
///
/// TPE : aucun rappel ni alerte pour le serveur. Le robot garde l'info en
/// mémoire ; c'est le client qui appuie sur « J'ai terminé » sur le robot.
class TaskTrackingScreen extends ConsumerWidget {
  /// Identifiant de l'opération (batchId).
  final String taskId;

  const TaskTrackingScreen({super.key, required this.taskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final batchAsync = ref.watch(batchTrackingProvider(taskId));

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text(AppStrings.taskTrackingTitle, style: AppTypography.titleLarge),
        leading: IconButton(
          tooltip: 'Accueil',
          icon: const Icon(Icons.home_rounded),
          onPressed: () => context.go('/robot-status'),
        ),
      ),
      body: SafeArea(
        child: batchAsync.when(
          loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
          error: (err, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Suivi indisponible : ${err.toString().replaceAll('Exception: ', '')}',
                  style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            ),
          ),
          data: (batch) => Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _HeaderCard(batch: batch),
                      const SizedBox(height: AppDimensions.space16),
                      _ProgressBar(step: batch.overallStep, finished: batch.isFinished),
                      const SizedBox(height: AppDimensions.space20),
                      Text(
                        batch.tasks.length > 1 ? 'La tournée' : 'La livraison',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: AppDimensions.space8),
                      for (final task in batch.tasks)
                        _StopCard(
                          task: task,
                          isCurrent: batch.currentStop?.id == task.id && !batch.isStored,
                        ),
                    ],
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: SizedBox(
                  height: AppDimensions.buttonHeightSecondary,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          batch.isFinished ? AppColors.primary : AppColors.surfaceElevated,
                      foregroundColor:
                          batch.isFinished ? AppColors.textOnPrimary : AppColors.textPrimary,
                      side: batch.isFinished
                          ? null
                          : const BorderSide(color: AppColors.surfaceBorder, width: 1.5),
                    ),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    label: const Text(AppStrings.backToHome, style: TextStyle(fontSize: 16)),
                    onPressed: () {
                      HapticHelper.light();
                      context.go('/robot-status');
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Résumé : nombre de commandes, livrées, TPE.
class _HeaderCard extends StatelessWidget {
  final DeliveryBatch batch;
  const _HeaderCard({required this.batch});

  @override
  Widget build(BuildContext context) {
    final total = batch.tasks.length;
    final current = batch.currentStop;
    final String title;
    final String subtitle;
    final Color color;
    final IconData icon;

    if (batch.isFinished) {
      title = total > 1 ? 'Tournée terminée' : 'Livraison terminée';
      subtitle = total > 1 ? 'Les $total tables sont servies.' : '${batch.tasks.first.tableNumber} est servie.';
      color = AppColors.statusIdle;
      icon = Icons.check_circle_rounded;
    } else if (batch.isStored) {
      title = 'Rangé dans le robot';
      subtitle = 'Il partira quand vous l\'enverrez depuis l\'accueil.';
      color = AppColors.primaryLight;
      icon = Icons.schedule_rounded;
    } else if (current != null && current.isAwaitingTpe) {
      title = 'Paiement en cours';
      subtitle = '${current.tableNumber} paie sur le TPE du robot.';
      color = AppColors.paymentTpe;
      icon = Icons.contactless_rounded;
    } else if (current != null && current.currentStep == DeliveryStep.delivering) {
      title = 'En route vers ${current.tableNumber}';
      subtitle = total > 1 ? 'Arrêt ${current.stopIndex + 1} sur $total' : 'Le robot roule.';
      color = AppColors.statusDelivering;
      icon = Icons.navigation_rounded;
    } else {
      title = 'Préparation du départ';
      subtitle = total > 1 ? '$total commandes à livrer' : 'Le robot prend la commande.';
      color = AppColors.primaryLight;
      icon = Icons.pan_tool_alt_rounded;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        border: Border.all(color: color.withOpacity(0.7), width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.titleLarge),
                const SizedBox(height: 2),
                Text(subtitle, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
              ],
            ),
          ),
          if (total > 1)
            CountPill(text: '${batch.finishedCount}/$total', color: color),
        ],
      ),
    );
  }
}

/// Barre horizontale des 4 étapes.
class _ProgressBar extends StatelessWidget {
  final DeliveryStep step;
  final bool finished;
  const _ProgressBar({required this.step, required this.finished});

  @override
  Widget build(BuildContext context) {
    const steps = DeliveryStep.values;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: i < step.index || finished
                        ? AppColors.statusIdle
                        : i == step.index
                            ? steps[i].color
                            : AppColors.surfaceElevated,
                    border: Border.all(
                        color: i <= step.index ? Colors.transparent : AppColors.surfaceBorder),
                  ),
                  child: Icon(
                    i < step.index || finished ? Icons.check_rounded : steps[i].icon,
                    size: 17,
                    color: i <= step.index ? AppColors.textOnPrimary : AppColors.textMuted,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[i].label,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: i == step.index ? FontWeight.w800 : FontWeight.w500,
                    color: i <= step.index ? AppColors.textPrimary : AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Un arrêt de la tournée : partie -> table + statut de livraison + paiement.
class _StopCard extends ConsumerWidget {
  final RobotTask task;
  final bool isCurrent;
  const _StopCard({required this.task, required this.isCurrent});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final paid = task.paymentStatus == PaymentStatus.tpePaid;
    final borderColor = task.isAwaitingTpe
        ? AppColors.paymentTpe
        : isCurrent
            ? AppColors.statusDelivering
            : AppColors.surfaceBorder;

    final String stepText;
    if (task.isStored) {
      stepText = 'Attend le départ';
    } else if (task.isAwaitingTpe) {
      stepText = 'Le robot est à la table';
    } else if (task.isFinished) {
      stepText = 'Servie';
    } else {
      stepText = task.currentStep.description;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: borderColor, width: isCurrent || task.isAwaitingTpe ? 2 : 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              SlotCodeChip(code: task.shortLocation, size: 38, active: !task.isFinished),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(task.tableNumber, style: AppTypography.titleMedium),
                        if (task.isFinished) ...[
                          const SizedBox(width: 6),
                          const Icon(Icons.check_circle_rounded,
                              size: 17, color: AppColors.statusIdle),
                        ],
                      ],
                    ),
                    Text('$stepText • ${task.locationLabel}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTypography.bodyMedium.copyWith(fontSize: 12)),
                  ],
                ),
              ),
              _PaymentBadge(status: task.paymentStatus),
            ],
          ),
          if (task.isAwaitingTpe) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppColors.paymentTpe.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Text(
                'Le client paie sur le TPE du robot, puis appuie sur « J\'ai terminé ». '
                'Rien à faire pour vous.',
                style: TextStyle(fontSize: 13, color: AppColors.textSecondary, height: 1.3),
              ),
            ),
            if (AppConfig.useMock) ...[
              const SizedBox(height: 8),
              _SimulatePayButton(taskId: task.id),
            ],
          ],
          if (paid) ...[
            const SizedBox(height: 10),
            const Row(
              children: [
                Icon(Icons.record_voice_over_rounded, size: 17, color: AppColors.statusIdle),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Le robot : « ${PaymentStatus.paidAnnouncement} »',
                    style: TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.statusIdle),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _PaymentBadge extends StatelessWidget {
  final PaymentStatus status;
  const _PaymentBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = status == PaymentStatus.none ? AppColors.textMuted : status.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.14),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (status == PaymentStatus.none)
            const Icon(Icons.payments_outlined, size: 14, color: AppColors.textMuted)
          else
            TpeStatusIcon(status: status, size: 16),
          const SizedBox(width: 5),
          Text(status.label,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }
}

/// MOCK uniquement : simule le client qui appuie sur « J'ai terminé ».
class _SimulatePayButton extends ConsumerStatefulWidget {
  final String taskId;
  const _SimulatePayButton({required this.taskId});

  @override
  ConsumerState<_SimulatePayButton> createState() => _SimulatePayButtonState();
}

class _SimulatePayButtonState extends ConsumerState<_SimulatePayButton> {
  bool _busy = false;

  Future<void> _pay() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await ref.read(tasksRepositoryProvider).markPaymentDone(widget.taskId);
      HapticHelper.success();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      key: ValueKey('simulate-pay-${widget.taskId}'),
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(44),
        foregroundColor: AppColors.paymentTpe,
        side: const BorderSide(color: AppColors.paymentTpe),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      onPressed: _busy ? null : _pay,
      icon: _busy
          ? const SizedBox(
              width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.touch_app_rounded, size: 18),
      label: const Text('Simulation : le client appuie sur « J\'ai terminé »'),
    );
  }
}
