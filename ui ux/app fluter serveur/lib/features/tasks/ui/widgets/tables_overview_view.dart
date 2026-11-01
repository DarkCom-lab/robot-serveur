import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_dimensions.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../../core/utils/haptic_feedback_helper.dart';
import '../../domain/cafe_table.dart';
import '../../domain/table_payment_state.dart';
import '../table_payments_provider.dart';

/// Vue d'ensemble des 10 tables du café avec statut TPE en temps réel et persistant.
/// Permet au serveur et au gérant d'identifier en un coup d'œil les paiements en attente,
/// et de valider / confirmer le paiement directement d'un simple toucher.
class TablesOverviewView extends ConsumerWidget {
  const TablesOverviewView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tablePayments = ref.watch(tablePaymentsProvider);
    final notifier = ref.read(tablePaymentsProvider.notifier);

    final pendingCount = tablePayments.values.where((p) => p.status == TableTpeStatus.pending).length;
    final paidCount = tablePayments.values.where((p) => p.status == TableTpeStatus.paid).length;
    final noneCount = tablePayments.values.where((p) => p.status == TableTpeStatus.none).length;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppDimensions.space16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Bandeau résumé des statuts
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.table_restaurant_rounded, color: AppColors.primaryLight, size: 22),
                    const SizedBox(width: 8),
                    const Text('Suivi des Tables & TPE', style: AppTypography.titleLarge),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Réinitialiser toutes les tables',
                      icon: const Icon(Icons.refresh_rounded, color: AppColors.textMuted, size: 20),
                      onPressed: () => _confirmResetAll(context, notifier),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _buildStatPill('En attente TPE', pendingCount, AppColors.paymentTpe, Icons.pending_rounded),
                    const SizedBox(width: 8),
                    _buildStatPill('Payés', paidCount, AppColors.statusIdle, Icons.check_circle_outline_rounded),
                    const SizedBox(width: 8),
                    _buildStatPill('Libres', noneCount, AppColors.textMuted, Icons.radio_button_unchecked_rounded),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),

          // Grille des 10 tables
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: CafeLayout.tables.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 0.88,
            ),
            itemBuilder: (context, index) {
              final table = CafeLayout.tables[index];
              final info = tablePayments[table.label] ??
                  TablePaymentInfo(tableNumber: table.label, updatedAt: DateTime.now());
              return _TableCard(table: table, info: info, notifier: notifier);
            },
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStatPill(String title, int count, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 14, color: color),
                const SizedBox(width: 4),
                Text('$count', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color)),
              ],
            ),
            const SizedBox(height: 2),
            Text(title, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: color), maxLines: 1),
          ],
        ),
      ),
    );
  }

  void _confirmResetAll(BuildContext context, TablePaymentsNotifier notifier) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Réinitialiser les tables ?', style: AppTypography.titleLarge),
        content: const Text(
          'Tous les statuts de paiement TPE des tables seront remis à l\'état libre.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler', style: TextStyle(color: AppColors.textMuted)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.statusError),
            onPressed: () {
              notifier.resetAll();
              Navigator.pop(ctx);
              HapticHelper.success();
            },
            child: const Text('Réinitialiser'),
          ),
        ],
      ),
    );
  }
}

class _TableCard extends StatelessWidget {
  final CafeTable table;
  final TablePaymentInfo info;
  final TablePaymentsNotifier notifier;

  const _TableCard({
    required this.table,
    required this.info,
    required this.notifier,
  });

  @override
  Widget build(BuildContext context) {
    final status = info.status;
    final color = status.color;
    final isPending = status == TableTpeStatus.pending;
    final isPaid = status == TableTpeStatus.paid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isPending
              ? AppColors.paymentTpe
              : isPaid
                  ? AppColors.statusIdle.withOpacity(0.7)
                  : AppColors.surfaceBorder,
          width: isPending ? 2.0 : 1.2,
        ),
        boxShadow: isPending
            ? [
                BoxShadow(
                  color: AppColors.paymentTpe.withOpacity(0.25),
                  blurRadius: 10,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Haut de la carte : Numéro de table & Statut
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isPending
                      ? AppColors.paymentTpe.withOpacity(0.2)
                      : isPaid
                          ? AppColors.statusIdle.withOpacity(0.2)
                          : AppColors.surfaceHighlight,
                  shape: BoxShape.circle,
                  border: Border.all(color: color, width: 1.5),
                ),
                alignment: Alignment.center,
                child: Text(
                  CafeLayout.shortLabel(table.label),
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: color),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(table.label, style: AppTypography.titleMedium),
                    Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: color,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Spacer(),

          // Montant si renseigné
          if (info.amount != null) ...[
            Center(
              child: Text(
                '${info.amount!.toStringAsFixed(2)} €',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(height: 6),
          ],

          // Bouton d'action selon le statut
          if (isPending) ...[
            ElevatedButton.icon(
              icon: const Icon(Icons.check_rounded, size: 16),
              label: const Text('Valider Paiement', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.statusIdle,
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                HapticHelper.success();
                notifier.markPaid(table.label);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Paiement TPE validé pour ${table.label} !'),
                    backgroundColor: AppColors.statusIdle,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
            ),
          ] else if (isPaid) ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.done_all_rounded, size: 14, color: AppColors.statusIdle),
              label: const Text('Libérer', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.surfaceBorder),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                HapticHelper.light();
                notifier.resetTable(table.label);
              },
            ),
          ] else ...[
            OutlinedButton.icon(
              icon: const Icon(Icons.add_card_rounded, size: 14, color: AppColors.primaryLight),
              label: const Text('+ TPE', style: TextStyle(fontSize: 11, color: AppColors.primaryLight)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: AppColors.primary.withOpacity(0.5)),
                padding: const EdgeInsets.symmetric(vertical: 6),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              ),
              onPressed: () {
                HapticHelper.light();
                notifier.markPending(table.label, amount: 12.50);
              },
            ),
          ],
        ],
      ),
    );
  }
}
