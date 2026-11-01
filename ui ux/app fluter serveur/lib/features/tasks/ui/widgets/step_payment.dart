import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../domain/delivery_request.dart';
import '../../domain/pending_order.dart';
import '../task_wizard_controller.dart';
import 'choice_card.dart';
import 'wizard_common.dart';

/// ÉTAPE 3 — Vérifier et envoyer :
/// Liste finale des arrêts ordonnés, réorganisation de l'ordre (▲ / ▼),
/// choix TPE / sans TPE par arrêt, et départ.
class StepPayment extends ConsumerWidget {
  const StepPayment({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wizard = ref.watch(taskWizardControllerProvider);
    final controller = ref.read(taskWizardControllerProvider.notifier);
    final requests = wizard.requests;
    final total = requests.fold<double>(0, (sum, r) => sum + r.order.totalPrice);
    final n = requests.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        WizardStepHeader(
          title: 'Vérifier la tournée et envoyer',
          hint: n > 1
              ? 'Le robot livrera successivement les $n tables dans cet ordre précis. Utilisez ▲ / ▼ pour ajuster.'
              : 'Dernière vérification avant le départ du robot.',
        ),
        const SizedBox(height: AppDimensions.space16),

        // Liste ordonnée des destinations
        for (var i = 0; i < n; i++)
          _RequestCard(
            index: i,
            request: requests[i],
            totalStops: n,
            isLast: i == n - 1,
            onPayment: (mode) {
              HapticHelper.light();
              controller.setPaymentMode(requests[i].order, mode);
            },
            onMoveUp: () {
              HapticHelper.medium();
              controller.moveDestinationUp(i);
            },
            onMoveDown: () {
              HapticHelper.medium();
              controller.moveDestinationDown(i);
            },
          ),
        const SizedBox(height: 8),

        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.paymentTpe.withOpacity(0.08),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.paymentTpe.withOpacity(0.2)),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(Icons.contactless_rounded, size: 20, color: AppColors.paymentTpe),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Avec TPE, le robot s\'en souvient pour chaque table. À l\'arrivée, il attend le règlement '
                  'et valide le statut « Payé » dès que le client ou serveur valide.',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),

        const Text('Quand le robot part-il ?', style: AppTypography.titleMedium),
        const SizedBox(height: AppDimensions.space8),
        ChoiceCard(
          icon: Icons.rocket_launch_rounded,
          title: 'Partir maintenant',
          subtitle: n > 1
              ? 'Le robot fait la tournée complète immédiatement.'
              : 'Le robot livre ce client tout de suite.',
          color: AppColors.statusDelivering,
          selected: wizard.deliverNow,
          onTap: () {
            HapticHelper.light();
            controller.setDeliverNow(true);
          },
        ),
        const SizedBox(height: AppDimensions.space8),
        ChoiceCard(
          icon: Icons.schedule_rounded,
          title: 'Garder pour plus tard',
          subtitle: 'Le robot range les plateaux et attend votre ordre de départ depuis l\'accueil.',
          color: AppColors.primaryLight,
          selected: !wizard.deliverNow,
          onTap: () {
            HapticHelper.light();
            controller.setDeliverNow(false);
          },
        ),
        const SizedBox(height: AppDimensions.space16),

        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '$n table${n > 1 ? 's à livrer' : ' à livrer'}'
              '${wizard.tpeCount > 0 ? ' • ${wizard.tpeCount} avec TPE' : ''}',
              style: AppTypography.bodyMedium.copyWith(fontSize: 14),
            ),
            Text(formatPrice(total),
                style: AppTypography.titleMedium.copyWith(color: AppColors.primaryLight)),
          ],
        ),
      ],
    );
  }
}

/// Une ligne de la tournée : ordre, boutons de réorganisation, partie, table, articles, TPE.
class _RequestCard extends StatelessWidget {
  final int index;
  final DeliveryRequest request;
  final int totalStops;
  final bool isLast;
  final ValueChanged<PaymentMode> onPayment;
  final VoidCallback onMoveUp;
  final VoidCallback onMoveDown;

  const _RequestCard({
    required this.index,
    required this.request,
    required this.totalStops,
    required this.isLast,
    required this.onPayment,
    required this.onMoveUp,
    required this.onMoveDown,
  });

  @override
  Widget build(BuildContext context) {
    final order = request.order;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Colonne verticale indiquant l'ordre de passage avec flèches
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  margin: const EdgeInsets.only(top: 14),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: AppColors.primary.withOpacity(0.4), blurRadius: 6),
                    ],
                  ),
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColors.textOnPrimary,
                    ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: AppColors.surfaceBorder,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),

          // Carte de la destination
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated,
                borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
                border: Border.all(
                  color: request.withTpe
                      ? AppColors.paymentTpe.withOpacity(0.6)
                      : AppColors.surfaceBorder,
                  width: 1.2,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      SlotCodeChip(code: request.placement.shortCode, size: 36),
                      const SizedBox(width: 8),
                      const Icon(Icons.arrow_forward_rounded, size: 16, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(order.tableNumber, style: AppTypography.titleLarge),
                            Text(
                              'Arrêt n°${index + 1} • ${request.placement.displayLabel}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.labelSmall,
                            ),
                          ],
                        ),
                      ),
                      Text(
                        formatPrice(order.totalPrice),
                        style: AppTypography.labelLarge.copyWith(color: AppColors.primaryLight),
                      ),

                      // Boutons de réorganisation
                      if (totalStops > 1) ...[
                        const SizedBox(width: 4),
                        Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: index > 0 ? onMoveUp : null,
                              child: Icon(
                                Icons.arrow_drop_up_rounded,
                                size: 22,
                                color: index > 0 ? AppColors.primaryLight : AppColors.textMuted.withOpacity(0.3),
                              ),
                            ),
                            InkWell(
                              onTap: !isLast ? onMoveDown : null,
                              child: Icon(
                                Icons.arrow_drop_down_rounded,
                                size: 22,
                                color: !isLast ? AppColors.primaryLight : AppColors.textMuted.withOpacity(0.3),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    order.itemsSummary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  PaymentToggle(
                    value: request.paymentMode,
                    orderLabel: order.tableNumber,
                    onChanged: onPayment,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
