import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/task_model.dart';
import 'task_wizard_controller.dart';

/// Suivi d'une opération (toutes les commandes envoyées ensemble).
final batchTrackingProvider =
    StreamProvider.autoDispose.family<DeliveryBatch, String>((ref, batchId) {
  final tasksRepo = ref.watch(tasksRepositoryProvider);
  return tasksRepo.watchBatch(batchId);
});
