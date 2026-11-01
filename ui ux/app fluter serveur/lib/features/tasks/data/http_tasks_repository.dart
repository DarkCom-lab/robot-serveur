import 'dart:async';
import '../../../core/network/api_client.dart';
import '../domain/delivery_request.dart';
import '../domain/task_model.dart';
import 'tasks_repository.dart';

/// Implémentation réseau connectée à l'API des livraisons robot.
///
/// Endpoints appelés :
/// POST /api/robot/tasks/batch              -> Plusieurs commandes en une fois
/// GET  /api/robot/tasks/batch/:batchId     -> Suivi d'une opération
/// POST /api/robot/tasks/:id/payment-done   -> Le client a fini de payer (TPE)
class HttpTasksRepository implements TasksRepository {
  final ApiClient _apiClient;

  HttpTasksRepository({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  @override
  Future<DeliveryBatch> createDeliveryBatch({
    required List<DeliveryRequest> requests,
    required bool deliverNow,
  }) async {
    final response = await _apiClient.post(
      '/api/robot/tasks/batch',
      body: {
        'deliverNow': deliverNow,
        'tasks': requests.map((r) => r.toJson()).toList(),
      },
    );
    if (response is Map<String, dynamic>) return DeliveryBatch.fromJson(response);
    throw ApiException(statusCode: 500, message: 'Réponse d\'envoi invalide');
  }

  @override
  Future<DeliveryBatch> getBatch(String batchId) async {
    final response = await _apiClient.get('/api/robot/tasks/batch/$batchId');
    if (response is Map<String, dynamic>) return DeliveryBatch.fromJson(response);
    throw ApiException(statusCode: 500, message: 'Réponse de suivi invalide');
  }

  @override
  Stream<DeliveryBatch> watchBatch(String batchId) async* {
    // Polling de secours (le WebSocket /ws/robot peut aussi pousser l'état).
    while (true) {
      try {
        final batch = await getBatch(batchId);
        yield batch;
        if (batch.isFinished) break;
      } catch (_) {}
      await Future.delayed(const Duration(seconds: 3));
    }
  }

  @override
  Future<RobotTask> markPaymentDone(String taskId) async {
    final response = await _apiClient.post('/api/robot/tasks/$taskId/payment-done');
    if (response is Map<String, dynamic>) return RobotTask.fromJson(response);
    throw ApiException(statusCode: 500, message: 'Réponse paiement invalide');
  }
}
