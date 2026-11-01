import 'pending_order.dart';
import 'placement_option.dart';

/// Une ligne de l'opération « partie -> table » prête à être envoyée au robot.
class DeliveryRequest {
  final PlacementChoice placement;
  final PendingOrder order;
  final PaymentMode paymentMode;

  const DeliveryRequest({
    required this.placement,
    required this.order,
    required this.paymentMode,
  });

  bool get withTpe => paymentMode == PaymentMode.tpe;

  Map<String, dynamic> toJson() => {
        'orderId': order.id,
        'tableNumber': order.tableNumber,
        'floor': placement.floorId,
        'zone': placement.zoneKey.toLowerCase(),
        'paymentMode': paymentMode.code,
      };
}
