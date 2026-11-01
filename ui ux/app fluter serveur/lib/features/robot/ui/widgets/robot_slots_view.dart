import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../../tasks/domain/placement_option.dart';
import '../../domain/floor_model.dart';
import '../../domain/payment_status.dart';

/// Le robot vu de face : 3 étages IDENTIQUES, chacun coupé en 2 parties
/// A (gauche) et B (droite). L'étage 1 est en bas.
///
/// - Vert  = partie LIBRE
/// - Rouge = partie OCCUPÉE (numéro de table + icône TPE si besoin)
/// - Ambre = partie CHOISIE (avec son numéro d'ordre dans la tournée)
///
/// Si [onToggle] est fourni, les parties libres sont touchables et on peut
/// en choisir PLUSIEURS. Sinon la vue est en lecture seule.
class RobotSlotsView extends StatelessWidget {
  final List<RobotFloor> floors;

  /// Parties choisies, dans l'ordre (numéro affiché = position + 1).
  final List<PlacementChoice> selected;

  final ValueChanged<PlacementChoice>? onToggle;

  const RobotSlotsView({
    super.key,
    required this.floors,
    this.selected = const [],
    this.onToggle,
  });

  static const double _labelWidth = 52;
  static const double _slotHeight = 66;

  @override
  Widget build(BuildContext context) {
    final sorted = List<RobotFloor>.from(floors)..sort((a, b) => b.id.compareTo(a.id));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildColumnHeader(),
        const SizedBox(height: 6),
        for (final floor in sorted) ...[
          _buildFloor(floor),
          _buildPoles(),
        ],
        _buildBase(),
      ],
    );
  }

  Widget _buildColumnHeader() {
    Widget h(String letter, String name) => Expanded(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 18,
                height: 18,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: AppColors.surfaceHighlight,
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(letter,
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w800, color: AppColors.textPrimary)),
              ),
              const SizedBox(width: 6),
              Text(name, style: AppTypography.labelSmall),
            ],
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(left: _labelWidth),
      child: Row(children: [h('A', 'GAUCHE'), const SizedBox(width: 6), h('B', 'DROITE')]),
    );
  }

  Widget _buildFloor(RobotFloor floor) {
    return Row(
      children: [
        SizedBox(
          width: _labelWidth,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('ÉTAGE',
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                      color: AppColors.textMuted)),
              Text('${floor.id}', style: AppTypography.titleLarge.copyWith(height: 1.1)),
            ],
          ),
        ),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Color(0xFF5B6270), Color(0xFF3F4552)],
              ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: const [
                BoxShadow(color: Color(0x55000000), blurRadius: 6, offset: Offset(0, 3)),
              ],
            ),
            child: Row(
              children: [
                Expanded(child: _buildSlot(floor, floor.zoneA)),
                const SizedBox(width: 5),
                Expanded(child: _buildSlot(floor, floor.zoneB)),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSlot(RobotFloor floor, ZoneSlot slot) {
    final choice = PlacementChoice(floorId: floor.id, zoneKey: slot.zoneKey);
    final orderIndex = selected.indexOf(choice);
    final isSelected = orderIndex >= 0;
    final interactive = onToggle != null;
    final isDimmed = interactive && slot.isOccupied;
    final isPaid = slot.isOccupied && slot.paymentStatus == PaymentStatus.tpePaid;

    final Color bg;
    final Color border;
    if (isSelected) {
      bg = AppColors.zoneSelected;
      border = AppColors.accentCream;
    } else if (slot.isFree) {
      bg = AppColors.slotFree;
      border = AppColors.slotFreeBorder;
    } else if (isPaid) {
      bg = AppColors.slotFree;
      border = AppColors.statusIdle;
    } else {
      bg = AppColors.slotOccupied;
      border = AppColors.slotOccupiedBorder;
    }

    final String title;
    final String subtitle;
    final Color titleColor;
    IconData? icon;
    if (isSelected) {
      title = 'CHOISIE';
      subtitle = slot.fullLabel;
      titleColor = AppColors.textPrimary;
    } else if (slot.isFree) {
      title = 'LIBRE';
      subtitle = slot.fullLabel;
      titleColor = AppColors.statusIdle;
      icon = interactive ? Icons.add_circle_outline_rounded : Icons.check_circle_outline_rounded;
    } else {
      title = slot.tableNumber ?? 'Occupée';
      titleColor = AppColors.textPrimary;
      if (isPaid) {
        subtitle = 'Payé';
      } else if (slot.isStored) {
        subtitle = 'Attend le départ';
      } else if (slot.paymentStatus == PaymentStatus.tpePending) {
        subtitle = 'TPE en attente';
      } else {
        subtitle = slot.fullLabel;
      }
    }

    final semantics = StringBuffer('${floor.label}, partie ${slot.zoneKey} ${slot.label}, ');
    if (isSelected) {
      semantics.write('choisie, numéro ${orderIndex + 1}');
    } else if (slot.isFree) {
      semantics.write('libre');
    } else {
      semantics.write('occupée par ${slot.tableNumber ?? 'une commande'}');
      if (slot.paymentStatus != PaymentStatus.none) semantics.write(', ${slot.paymentStatus.label}');
    }

    final VoidCallback? onTap =
        interactive && (slot.isFree || isSelected) ? () => onToggle!(choice) : null;

    return Semantics(
      button: onTap != null,
      selected: isSelected,
      label: semantics.toString(),
      excludeSemantics: true,
      child: AnimatedOpacity(
        duration: const Duration(milliseconds: 200),
        opacity: isDimmed ? 0.5 : 1,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: _slotHeight,
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(color: border, width: isSelected ? 2.5 : 1.5),
          ),
          child: Material(
            type: MaterialType.transparency,
            child: InkWell(
              key: ValueKey('slot-${choice.shortCode}'),
              borderRadius: BorderRadius.circular(9),
              onTap: onTap,
              child: Stack(
                children: [
                  Positioned.fill(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 22),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (icon != null) ...[
                                Icon(icon, size: 15, color: titleColor),
                                const SizedBox(width: 4),
                              ],
                              Flexible(
                                child: Text(title,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: titleColor)),
                              ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(subtitle,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                        ],
                      ),
                    ),
                  ),
                  if (isSelected) Positioned(left: 5, top: 5, child: _orderBadge(orderIndex + 1)),
                  if (!isSelected && slot.isOccupied && slot.paymentStatus != PaymentStatus.none)
                    Positioned(right: 4, top: 4, child: TpeStatusIcon(status: slot.paymentStatus)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _orderBadge(int n) => Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: const BoxDecoration(color: AppColors.accentCream, shape: BoxShape.circle),
        child: Text('$n',
            style: const TextStyle(
                fontSize: 11, fontWeight: FontWeight.w900, color: AppColors.textOnPrimary)),
      );

  /// Les 2 tiges qui relient les étages.
  Widget _buildPoles() {
    Widget pole() => Container(
          width: 7,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF2E333D),
            borderRadius: BorderRadius.circular(2),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(left: _labelWidth + 34, right: 34),
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [pole(), pole()]),
    );
  }

  /// Base roulante du robot.
  Widget _buildBase() {
    Widget wheel() => Container(
          width: 26,
          height: 10,
          decoration: BoxDecoration(
            color: const Color(0xFF111827),
            borderRadius: BorderRadius.circular(4),
          ),
        );
    return Padding(
      padding: const EdgeInsets.only(left: _labelWidth),
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF2E333D),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            wheel(),
            const Padding(
              padding: EdgeInsets.only(bottom: 9),
              child: Text('FABTINO', style: AppTypography.labelSmall),
            ),
            wheel(),
          ],
        ),
      ),
    );
  }
}

/// Petite icône ronde du statut de paiement (TPE en attente / Payé).
class TpeStatusIcon extends StatelessWidget {
  final PaymentStatus status;
  final double size;

  const TpeStatusIcon({super.key, required this.status, this.size = 20});

  @override
  Widget build(BuildContext context) {
    if (status == PaymentStatus.none) return const SizedBox.shrink();
    return Tooltip(
      message: status.label,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: status.color,
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.background, width: 1.5),
        ),
        child: Icon(status.icon, size: size * 0.62, color: Colors.white),
      ),
    );
  }
}

/// Légende : libre, occupée, choisie, TPE.
class RobotSlotsLegend extends StatelessWidget {
  final bool showSelected;
  final bool showTpe;

  const RobotSlotsLegend({super.key, this.showSelected = false, this.showTpe = true});

  @override
  Widget build(BuildContext context) {
    Widget box(Color bg, Color border, String text) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 14,
              height: 14,
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: border, width: 1.5),
              ),
            ),
            const SizedBox(width: 6),
            Text(text, style: AppTypography.bodyMedium),
          ],
        );
    Widget icon(PaymentStatus s) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TpeStatusIcon(status: s, size: 16),
            const SizedBox(width: 6),
            Text(s.label, style: AppTypography.bodyMedium),
          ],
        );
    return Wrap(
      alignment: WrapAlignment.center,
      spacing: 16,
      runSpacing: 8,
      children: [
        box(AppColors.slotFree, AppColors.slotFreeBorder, 'Libre'),
        box(AppColors.slotOccupied, AppColors.slotOccupiedBorder, 'Occupée'),
        if (showSelected) box(AppColors.zoneSelected, AppColors.accentCream, 'Choisie'),
        if (showTpe) icon(PaymentStatus.tpePending),
        if (showTpe) icon(PaymentStatus.tpePaid),
      ],
    );
  }
}
