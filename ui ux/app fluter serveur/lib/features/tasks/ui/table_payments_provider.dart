import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/storage/table_payment_storage_service.dart';
import '../../robot/domain/payment_status.dart';
import '../../robot/ui/robot_controller.dart';
import '../domain/table_payment_state.dart';
import 'task_wizard_controller.dart';

/// Provider pour le service de stockage local SharedPreferences des tables.
final tablePaymentStorageProvider = Provider<TablePaymentStorageService>((ref) {
  return TablePaymentStorageService();
});

/// Notifier gérant la liste des tables et leurs statuts de paiement TPE.
class TablePaymentsNotifier extends StateNotifier<Map<String, TablePaymentInfo>> {
  final TablePaymentStorageService _storage;
  final Ref _ref;

  TablePaymentsNotifier(this._storage, this._ref)
      : super(TablePaymentStorageService.createDefaultTablePayments()) {
    _loadFromStorage();
  }

  Future<void> _loadFromStorage() async {
    final loaded = await _storage.loadTablePayments();
    if (mounted) {
      state = loaded;
    }
  }

  /// Passe une table en statut "TPE Non payé / En attente" (Orange/Rouge).
  Future<void> markPending(String tableNumber, {double? amount, String? orderId}) async {
    final current = state[tableNumber] ??
        TablePaymentInfo(tableNumber: tableNumber, updatedAt: DateTime.now());
    final updated = current.copyWith(
      status: TableTpeStatus.pending,
      amount: amount ?? current.amount,
      orderId: orderId ?? current.orderId,
      updatedAt: DateTime.now(),
    );
    final newState = Map<String, TablePaymentInfo>.from(state)..[tableNumber] = updated;
    state = newState;
    await _storage.saveTablePayments(newState);
  }

  /// Valide et confirme le paiement TPE -> passe immédiatement à "Payé" (Vert).
  Future<void> markPaid(String tableNumber) async {
    final current = state[tableNumber] ??
        TablePaymentInfo(tableNumber: tableNumber, updatedAt: DateTime.now());
    final updated = current.copyWith(
      status: TableTpeStatus.paid,
      updatedAt: DateTime.now(),
    );
    final newState = Map<String, TablePaymentInfo>.from(state)..[tableNumber] = updated;
    state = newState;
    await _storage.saveTablePayments(newState);

    // Si le robot est actuellement à cette table en attente de paiement TPE,
    // on valide également au niveau des livraisons.
    try {
      final robotRepo = _ref.read(robotRepositoryProvider);
      final tasksRepo = _ref.read(tasksRepositoryProvider);
      final robotStatus = await robotRepo.getRobotStatus();
      for (final floor in robotStatus.floors) {
        for (final slot in floor.slots) {
          if (slot.tableNumber == tableNumber &&
              slot.paymentStatus == PaymentStatus.tpePending &&
              slot.taskId != null) {
            await tasksRepo.markPaymentDone(slot.taskId!);
          }
        }
      }
    } catch (_) {
      // Ignorer si le robot n'est pas actif à cette table
    }
  }

  /// Réinitialise l'état d'une table (Libre / Aucun paiement).
  Future<void> resetTable(String tableNumber) async {
    final updated = TablePaymentInfo(
      tableNumber: tableNumber,
      status: TableTpeStatus.none,
      updatedAt: DateTime.now(),
    );
    final newState = Map<String, TablePaymentInfo>.from(state)..[tableNumber] = updated;
    state = newState;
    await _storage.saveTablePayments(newState);
  }

  /// Réinitialise toutes les tables.
  Future<void> resetAll() async {
    final clean = TablePaymentStorageService.createDefaultTablePayments();
    state = clean;
    await _storage.clearAll();
  }
}

final tablePaymentsProvider =
    StateNotifierProvider<TablePaymentsNotifier, Map<String, TablePaymentInfo>>((ref) {
  final storage = ref.watch(tablePaymentStorageProvider);
  return TablePaymentsNotifier(storage, ref);
});
