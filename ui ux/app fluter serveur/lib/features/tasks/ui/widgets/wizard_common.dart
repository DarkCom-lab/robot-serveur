import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_typography.dart';
import '../../domain/pending_order.dart';

/// En-tête d'étape : grand titre + phrase d'aide + compteur optionnel.
class WizardStepHeader extends StatelessWidget {
  final String title;
  final String hint;
  final Widget? trailing;

  const WizardStepHeader({super.key, required this.title, required this.hint, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppTypography.displayMedium),
              const SizedBox(height: 4),
              Text(hint, style: AppTypography.bodyMedium.copyWith(fontSize: 14)),
            ],
          ),
        ),
        if (trailing != null) ...[const SizedBox(width: 12), trailing!],
      ],
    );
  }
}

/// Pastille « 2A » représentant une partie du robot.
class SlotCodeChip extends StatelessWidget {
  final String code;
  final bool active;
  final double size;

  const SlotCodeChip({super.key, required this.code, this.active = true, this.size = 40});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? AppColors.primary : AppColors.surfaceHighlight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: active ? AppColors.accentCream : AppColors.surfaceBorder,
          width: active ? 2 : 1.2,
        ),
      ),
      child: Text(
        code,
        style: TextStyle(
          fontSize: size * 0.36,
          fontWeight: FontWeight.w900,
          color: active ? AppColors.textOnPrimary : AppColors.textSecondary,
        ),
      ),
    );
  }
}

/// Compteur arrondi (ex. « 3 / 6 »).
class CountPill extends StatelessWidget {
  final String text;
  final Color color;
  const CountPill({super.key, required this.text, this.color = AppColors.primaryLight});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(text, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
    );
  }
}

/// Sélecteur compact « Sans TPE | TPE » pour une commande.
class PaymentToggle extends StatelessWidget {
  final PaymentMode value;
  final ValueChanged<PaymentMode> onChanged;
  final String orderLabel;

  const PaymentToggle({
    super.key,
    required this.value,
    required this.onChanged,
    required this.orderLabel,
  });

  @override
  Widget build(BuildContext context) {
    Widget option(PaymentMode mode, String label, IconData icon, Color color) {
      final selected = value == mode;
      return Expanded(
        child: Semantics(
          button: true,
          selected: selected,
          label: '$orderLabel : $label',
          excludeSemantics: true,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: () => onChanged(mode),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              height: 44,
              decoration: BoxDecoration(
                color: selected ? color.withOpacity(0.2) : Colors.transparent,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(color: selected ? color : Colors.transparent, width: 1.8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 17, color: selected ? color : AppColors.textMuted),
                  const SizedBox(width: 6),
                  Text(label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: selected ? AppColors.textPrimary : AppColors.textMuted,
                      )),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          option(PaymentMode.none, 'Sans TPE', Icons.check_circle_outline_rounded,
              AppColors.paymentCash),
          const SizedBox(width: 3),
          option(PaymentMode.tpe, 'TPE', Icons.contactless_rounded, AppColors.paymentTpe),
        ],
      ),
    );
  }
}

String formatPrice(double value) => '${value.toStringAsFixed(2).replaceAll('.', ',')} €';
