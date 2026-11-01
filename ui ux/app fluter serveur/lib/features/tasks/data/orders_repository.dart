import '../domain/pending_order.dart';

/// Interface pour la gestion des commandes en attente de livraison.
abstract class OrdersRepository {
  /// Récupère la liste des commandes en attente (triées par heure d'arrivée).
  /// Endpoint backend réel : GET /api/orders?status=pending
  Future<List<PendingOrder>> getPendingOrders();

  /// Marque une commande comme prise en charge par le robot.
  Future<void> removePendingOrder(String orderId);
}
