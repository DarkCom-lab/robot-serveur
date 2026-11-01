import '../domain/delivery_request.dart';
import '../domain/task_model.dart';

/// Interface pour l'envoi et le suivi des livraisons du robot.
abstract class TasksRepository {
  /// Envoie PLUSIEURS commandes au robot en UNE seule opération.
  ///
  /// Endpoint backend réel : POST /api/robot/tasks/batch
  /// Body : { deliverNow: bool,
  ///          tasks: [ { orderId, tableNumber, floor: 1-3, zone: "a" | "b",
  ///                     paymentMode: "tpe" | "none" } ] }
  /// Réponse : { batchId, tasks: [ RobotTask ] }
  ///
  /// L'ordre de [requests] = ordre de passage aux tables.
  Future<DeliveryBatch> createDeliveryBatch({
    required List<DeliveryRequest> requests,
    required bool deliverNow,
  });

  /// État instantané d'une opération.
  /// Endpoint backend : GET /api/robot/tasks/batch/:batchId
  Future<DeliveryBatch> getBatch(String batchId);

  /// Suivi en continu d'une opération (toutes ses livraisons).
  Stream<DeliveryBatch> watchBatch(String batchId);

  /// Le client a fini de payer sur le TPE du robot (« J'ai terminé »).
  /// Le robot passe la commande à « Payé » et annonce
  /// « C'est bon, paiement validé ».
  ///
  /// Endpoint backend : POST /api/robot/tasks/:id/payment-done
  Future<RobotTask> markPaymentDone(String taskId);
}
