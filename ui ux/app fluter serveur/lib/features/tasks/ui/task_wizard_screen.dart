import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/constants/app_typography.dart';
import '../../../core/i18n/app_strings.dart';
import '../../../core/utils/haptic_feedback_helper.dart';
import '../../robot/domain/robot_state.dart';
import '../../robot/ui/robot_controller.dart';
import 'task_wizard_controller.dart';
import 'widgets/step_client.dart';
import 'widgets/step_payment.dart';
import 'widgets/step_placement.dart';

/// ÉCRAN 2 : « Passer des commandes » en 3 étapes simples.
///   1. Plateau  : je touche une ou plusieurs parties LIBRES du robot
///   2. Clients  : pour chaque partie, je touche la table sur le plan
///   3. Envoi    : TPE ou non pour chaque commande, départ, UN seul bouton
class TaskWizardScreen extends ConsumerWidget {
  const TaskWizardScreen({super.key});

  static const List<String> _stepTitles = ['Plateau', 'Clients', 'Envoi'];

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(taskWizardControllerProvider.notifier).submit();
    if (!context.mounted) return;
    if (result == null) {
      HapticHelper.error();
      return;
    }
    HapticHelper.success();
    final n = result.batch.tasks.length;
    if (result.deliverNow) {
      context.go('/task-tracking/${result.batch.id}');
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(n > 1
              ? '$n commandes rangées dans le robot. Il partira quand vous le déciderez.'
              : 'Commande rangée dans le robot. Il partira quand vous le déciderez.'),
        ),
      );
      context.go('/robot-status');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(taskWizardControllerProvider);
    final robotAsync = ref.watch(robotStateStreamProvider);

    return PopScope(
      canPop: wizard.currentStep == 0 && !wizard.isSubmitting,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) ref.read(taskWizardControllerProvider.notifier).previousStep();
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          title: const Text(AppStrings.taskWizardTitle, style: AppTypography.titleLarge),
          leading: IconButton(
            tooltip: AppStrings.back,
            icon: const Icon(Icons.arrow_back_rounded),
            onPressed: wizard.isSubmitting
                ? null
                : () {
                    if (wizard.currentStep > 0) {
                      ref.read(taskWizardControllerProvider.notifier).previousStep();
                    } else {
                      context.pop();
                    }
                  },
          ),
        ),
        body: SafeArea(
          child: robotAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator(color: AppColors.primary)),
            error: (err, _) => Center(child: Text('Erreur : $err', style: AppTypography.bodyLarge)),
            data: (robot) {
              // Le robot est devenu indisponible pendant la saisie.
              if (!robot.canAcceptNewTask && !wizard.isSubmitting && !wizard.hasSubmitted) {
                return _buildUnavailable(context, robot);
              }
              return Column(
                children: [
                  _buildStepIndicator(ref, wizard.currentStep),
                  AnimatedSize(
                    duration: const Duration(milliseconds: 200),
                    child: wizard.errorMessage != null
                        ? _buildError(wizard.errorMessage!)
                        : const SizedBox(width: double.infinity),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 240),
                      switchInCurve: Curves.easeOutCubic,
                      transitionBuilder: (child, anim) => FadeTransition(
                        opacity: anim,
                        child: SlideTransition(
                          position: Tween(begin: const Offset(0.04, 0), end: Offset.zero)
                              .animate(anim),
                          child: child,
                        ),
                      ),
                      child: SingleChildScrollView(
                        key: ValueKey(wizard.currentStep),
                        padding: const EdgeInsets.all(AppDimensions.space16),
                        child: switch (wizard.currentStep) {
                          0 => StepPlacement(robot: robot),
                          1 => const StepClient(),
                          _ => const StepPayment(),
                        },
                      ),
                    ),
                  ),
                  _buildBottomBar(context, ref, wizard),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildStepIndicator(WidgetRef ref, int current) {
    final controller = ref.read(taskWizardControllerProvider.notifier);
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          for (var i = 0; i < _stepTitles.length; i++) ...[
            Expanded(
              child: Semantics(
                button: i < current,
                label: 'Étape ${i + 1}, ${_stepTitles[i]}',
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: i < current ? () => controller.goToStep(i) : null,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Column(
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 6,
                          decoration: BoxDecoration(
                            color: i <= current ? AppColors.primary : AppColors.surfaceBorder,
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (i < current) ...[
                              const Icon(Icons.check_rounded,
                                  size: 13, color: AppColors.primaryLight),
                              const SizedBox(width: 3),
                            ],
                            Text(
                              '${i + 1}. ${_stepTitles[i]}',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: i == current ? FontWeight.w800 : FontWeight.w500,
                                color: i == current
                                    ? AppColors.textPrimary
                                    : i < current
                                        ? AppColors.textSecondary
                                        : AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            if (i < _stepTitles.length - 1) const SizedBox(width: 8),
          ],
        ],
      ),
    );
  }

  Widget _buildError(String message) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.statusError.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.statusError.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: AppColors.statusError, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message,
                style: const TextStyle(color: AppColors.textPrimary, fontSize: 13.5)),
          ),
        ],
      ),
    );
  }

  Widget _buildUnavailable(BuildContext context, RobotStateModel robot) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.do_not_disturb_on_rounded, size: 64, color: AppColors.statusError),
            const SizedBox(height: 12),
            const Text('ROBOT NON LIBRE', style: AppTypography.displayMedium),
            const SizedBox(height: 8),
            Text(robot.disabledReason ?? '',
                style: AppTypography.bodyLarge, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => context.go('/robot-status'),
              child: const Text(AppStrings.backToHome),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomBar(BuildContext context, WidgetRef ref, TaskWizardState wizard) {
    final controller = ref.read(taskWizardControllerProvider.notifier);
    final isLast = wizard.currentStep == TaskWizardState.lastStep;
    final n = wizard.count;

    final String label;
    final IconData icon;
    String? helper;
    if (wizard.currentStep == 0) {
      label = n == 0
          ? 'Choisissez au moins une partie'
          : 'Suivant • $n partie${n > 1 ? 's' : ''}';
      icon = Icons.arrow_forward_rounded;
    } else if (wizard.currentStep == 1) {
      final missing = wizard.unassignedPlacements.length;
      label = missing == 0 ? 'Suivant' : 'Encore $missing table${missing > 1 ? 's' : ''} à choisir';
      icon = Icons.arrow_forward_rounded;
    } else if (wizard.deliverNow) {
      label = n > 1 ? 'Envoyer les $n commandes' : AppStrings.sendToRobotButton;
      icon = Icons.send_rounded;
      helper = 'Le robot est vérifié juste avant l\'envoi.';
    } else {
      label = n > 1 ? 'Ranger les $n commandes' : 'Ranger pour plus tard';
      icon = Icons.schedule_send_rounded;
    }

    final enabled = isLast ? wizard.canSubmit : wizard.canGoToNextStep;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: AppDimensions.buttonHeightPrimary,
            child: ElevatedButton.icon(
              key: const ValueKey('wizard-main-button'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: AppColors.textOnPrimary,
                disabledBackgroundColor: AppColors.surfaceHighlight,
                disabledForegroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                ),
              ),
              onPressed: enabled
                  ? () {
                      HapticHelper.medium();
                      if (isLast) {
                        _submit(context, ref);
                      } else {
                        controller.nextStep();
                      }
                    }
                  : null,
              icon: wizard.isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2.5, color: AppColors.textOnPrimary),
                    )
                  : Icon(icon),
              label: Text(
                wizard.isSubmitting ? AppStrings.sendingInProgress : label,
                style: AppTypography.labelLarge.copyWith(
                  color: enabled || wizard.isSubmitting
                      ? AppColors.textOnPrimary
                      : AppColors.textMuted,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (helper != null && !wizard.isSubmitting) ...[
            const SizedBox(height: 6),
            Text(helper,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
          ],
        ],
      ),
    );
  }
}
