import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../domain/cafe_table.dart';
import '../../domain/pending_order.dart';

/// Plan du café interactif pour les tables 1 à 10.
///
/// Permet la sélection libre de n'importe quelle table (1, 2, 3 ou toutes).
/// Affiche les numéros d'ordre de passage (1er, 2e, 3e arrêt) et les codes de plateaux.
class CafeMapWidget extends StatelessWidget {
  /// Commande par table (clé = "Table 4").
  final Map<String, PendingOrder> ordersByTable;

  /// Table -> code de la partie du robot attribuée (ex. "2A").
  final Map<String, String> assignedCodes;

  /// Table -> numéro d'ordre de passage (1, 2, 3...).
  final Map<String, int> stopOrderNumbers;

  /// Tables dont la commande sera payée par TPE.
  final Set<String> tpeTables;

  final ValueChanged<PendingOrder>? onSelect;

  const CafeMapWidget({
    super.key,
    required this.ordersByTable,
    this.assignedCodes = const {},
    this.stopOrderNumbers = const {},
    this.tpeTables = const {},
    this.onSelect,
  });

  static const double _tableSize = 54;

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 1.25,
      child: LayoutBuilder(
        builder: (context, box) {
          final w = box.maxWidth;
          final h = box.maxHeight;
          return Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: 10,
                  bottom: 10,
                  width: w * 0.26,
                  height: h * 0.15,
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceHighlight,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.smart_toy_outlined, size: 14, color: AppColors.textMuted),
                        SizedBox(width: 4),
                        Text(
                          'BAR',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                for (final t in CafeLayout.tables)
                  Positioned(
                    left: t.x * w - _tableSize / 2,
                    top: t.y * h - _tableSize / 2,
                    width: _tableSize,
                    height: _tableSize,
                    child: _buildTable(t),
                  ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildTable(CafeTable table) {
    final order = ordersByTable[table.label] ??
        PendingOrder(
          id: '#CMD-${table.label.replaceAll(' ', '')}',
          tableNumber: table.label,
          items: const ['Commande en salle'],
          totalPrice: 10.0,
          initialPaymentMode: PaymentMode.none,
          createdAt: DateTime.now(),
        );

    final code = assignedCodes[table.label];
    final isAssigned = code != null;
    final stopNumber = stopOrderNumbers[table.label];
    final withTpe = tpeTables.contains(table.label);

    final Color bg;
    final Color border;
    final Color text;
    if (isAssigned) {
      bg = AppColors.primary;
      border = AppColors.accentCream;
      text = AppColors.textOnPrimary;
    } else {
      bg = AppColors.surfaceElevated;
      border = AppColors.primary.withOpacity(0.5);
      text = AppColors.textPrimary;
    }

    return Semantics(
      button: onSelect != null,
      selected: isAssigned,
      label: isAssigned
          ? '${table.label}, arrêt $stopNumber, partie $code'
          : '${table.label}, disponible',
      excludeSemantics: true,
      child: GestureDetector(
        key: ValueKey('map-${table.label}'),
        behavior: HitTestBehavior.opaque,
        onTap: onSelect != null ? () => onSelect!(order) : null,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              curve: Curves.easeOut,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: bg,
                shape: BoxShape.circle,
                border: Border.all(color: border, width: isAssigned ? 3 : 1.5),
                boxShadow: isAssigned
                    ? [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 12)]
                    : null,
              ),
              child: Text(
                CafeLayout.shortLabel(table.label),
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: text),
              ),
            ),

            // Badge d'ordre de passage (ex : Arrêt #1, #2, #3...)
            if (isAssigned && stopNumber != null)
              Positioned(
                left: -4,
                top: -4,
                child: Container(
                  width: 22,
                  height: 22,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppColors.accentCream,
                    shape: BoxShape.circle,
                    border: Border.all(color: AppColors.background, width: 2),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4),
                    ],
                  ),
                  child: Text(
                    '$stopNumber',
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                      color: AppColors.background,
                    ),
                  ),
                ),
              ),

            // Badge de partie robot (ex : 1A, 2B...)
            if (isAssigned)
              Positioned(
                left: 0,
                right: 0,
                bottom: -10,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceElevated,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.primaryLight, width: 1.2),
                    ),
                    child: Text(
                      code,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryLight,
                      ),
                    ),
                  ),
                ),
              ),

            // Indicateur TPE sur la table
            if (withTpe)
              Positioned(
                right: -2,
                top: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(
                    color: AppColors.paymentTpe,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.contactless_rounded, size: 10, color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
