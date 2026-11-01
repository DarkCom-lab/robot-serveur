import 'dart:async';
import '../../robot/data/mock_robot_repository.dart';
import '../domain/delivery_request.dart';
import '../domain/task_model.dart';
import 'tasks_repository.dart';

/// Mock des livraisons. Il s'appuie sur [MockRobotRepository], qui fait
/// avancer la tournée : l'écran du robot et l'écran de suivi restent
/// donc parfaitement synchronisés (parties, statut TPE, arrivées...).
class MockTasksRepository implements TasksRepository {
  final MockRobotRepository _robot;

  MockTasksRepository(this._robot);

  Duration _latency(int ms) => Duration(microseconds: (ms * 1000 * _robot.speed).round());

  @override
  Future<DeliveryBatch> createDeliveryBatch({
    required List<DeliveryRequest> requests,
    required bool deliverNow,
  }) async {
    if (requests.isEmpty) throw Exception('Aucune commande à envoyer.');
    await Future.delayed(_latency(450)); // Latence réseau simulée
    return _robot.createBatch(requests, deliverNow: deliverNow);
  }

  @override
  Future<DeliveryBatch> getBatch(String batchId) async {
    await Future.delayed(_latency(150));
    final b = _robot.batch(batchId);
    if (b == null) throw Exception('Opération introuvable');
    return b;
  }

  @override
  Stream<DeliveryBatch> watchBatch(String batchId) => _robot.watchBatch(batchId);

  @override
  Future<RobotTask> markPaymentDone(String taskId) async {
    await Future.delayed(_latency(250));
    return _robot.markPaymentDone(taskId);
  }
}
