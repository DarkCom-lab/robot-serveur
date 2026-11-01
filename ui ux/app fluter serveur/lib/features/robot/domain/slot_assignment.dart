import 'payment_status.dart';

/// Une commande à ranger dans une partie précise du robot.
class SlotAssignment {
  final int floorId; // 1, 2 ou 3
  final String zoneKey; // 'A' (gauche) ou 'B' (droite)
  final String orderId;
  final String? taskId;
  final String tableNumber;
  final String itemsSummary;
  final PaymentStatus paymentStatus;

  const SlotAssignment({
    required this.floorId,
    required this.zoneKey,
    required this.orderId,
    this.taskId,
    required this.tableNumber,
    required this.itemsSummary,
    this.paymentStatus = PaymentStatus.none,
  });
}
