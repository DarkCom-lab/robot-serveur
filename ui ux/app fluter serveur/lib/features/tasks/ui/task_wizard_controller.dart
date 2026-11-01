import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../../robot/data/mock_robot_repository.dart';
import '../../robot/data/robot_repository.dart';
import '../../robot/domain/payment_status.dart';
import '../../robot/domain/robot_state.dart';
import '../../robot/domain/slot_assignment.dart';
import '../../robot/ui/robot_controller.dart';
import '../data/http_orders_repository.dart';
import '../data/http_tasks_repository.dart';
import '../data/mock_orders_repository.dart';
import '../data/mock_tasks_repository.dart';
import '../data/orders_repository.dart';
import '../data/tasks_repository.dart';
import '../domain/delivery_request.dart';
import '../domain/pending_order.dart';
import '../domain/placement_option.dart';
import '../domain/task_model.dart';
import 'table_payments_provider.dart';

// ---------------------------------------------------------------------------
// Repositories
// ---------------------------------------------------------------------------
final ordersRepositoryProvider = Provider<OrdersRepository>((ref) {
  return AppConfig.useMock ? MockOrdersRepository() : HttpOrdersRepository();
});

final tasksRepositoryProvider = Provider<TasksRepository>((ref) {
  final robot = ref.watch(robotRepositoryProvider);
  if (robot is MockRobotRepository) return MockTasksRepository(robot);
  return HttpTasksRepository();
});

/// Commandes en attente (autoDispose : rechargées à chaque ouverture).
final pendingOrdersProvider = FutureProvider.autoDispose<List<PendingOrder>>((ref) async {
  return ref.watch(ordersRepositoryProvider).getPendingOrders();
});

// ---------------------------------------------------------------------------
// État de l'assistant « Passer des commandes »
//   Étape 0 : choisir UNE OU PLUSIEURS parties libres du robot
//   Étape 1 : pour chaque partie, toucher la table du client sur le plan
//   Étape 2 : TPE ou non (par commande) + départ, puis UN seul envoi
// ---------------------------------------------------------------------------
class TaskWizardState {
  static const int lastStep = 2;

  final int currentStep;

  /// Parties choisies, dans l'ordre de sélection (= ordre de la tournée).
  final List<PlacementChoice> selectedPlacements;

  /// Partie -> commande (table) du client.
  final Map<PlacementChoice, PendingOrder> assignments;

  /// Mode de paiement choisi par commande (clé = id de commande).
  final Map<String, PaymentMode> paymentModes;

  /// Partie qui recevra la prochaine table touchée (étape 1).
  final PlacementChoice? activePlacement;

  final bool deliverNow;
  final bool isSubmitting;

  /// Vrai après un envoi réussi : bloque tout second envoi.
  final bool hasSubmitted;
  final String? errorMessage;

  const TaskWizardState({
    this.currentStep = 0,
    this.selectedPlacements = const [],
    this.assignments = const {},
    this.paymentModes = const {},
    this.activePlacement,
    this.deliverNow = true,
    this.isSubmitting = false,
    this.hasSubmitted = false,
    this.errorMessage,
  });

  int get count => selectedPlacements.length;

  bool isSelected(PlacementChoice c) => selectedPlacements.contains(c);

  /// Parties qui n'ont pas encore de table.
  List<PlacementChoice> get unassignedPlacements =>
      selectedPlacements.where((p) => !assignments.containsKey(p)).toList();

  bool get allAssigned => count > 0 && unassignedPlacements.isEmpty;

  /// Partie qui reçoit la prochaine table : l'active, sinon la 1re sans table.
  PlacementChoice? get targetPlacement {
    final active = activePlacement;
    if (active != null && isSelected(active)) return active;
    final free = unassignedPlacements;
    return free.isNotEmpty ? free.first : null;
  }

  /// Partie qui porte déjà la commande de cette table (ou `null`).
  PlacementChoice? placementForTable(String tableNumber) {
    for (final e in assignments.entries) {
      if (e.value.tableNumber == tableNumber) return e.key;
    }
    return null;
  }

  PaymentMode paymentFor(PendingOrder order) =>
      paymentModes[order.id] ?? order.initialPaymentMode;

  /// La liste finale « partie -> table », dans l'ordre de la tournée.
  List<DeliveryRequest> get requests => [
        for (final p in selectedPlacements)
          if (assignments[p] != null)
            DeliveryRequest(
              placement: p,
              order: assignments[p]!,
              paymentMode: paymentFor(assignments[p]!),
            ),
      ];

  int get tpeCount => requests.where((r) => r.withTpe).length;

  bool get canGoToNextStep => currentStep == 0 ? selectedPlacements.isNotEmpty : allAssigned;

  bool get canSubmit => currentStep == lastStep && allAssigned && !isSubmitting && !hasSubmitted;

  TaskWizardState copyWith({
    int? currentStep,
    List<PlacementChoice>? selectedPlacements,
    Map<PlacementChoice, PendingOrder>? assignments,
    Map<String, PaymentMode>? paymentModes,
    PlacementChoice? activePlacement,
    bool clearActive = false,
    bool? deliverNow,
    bool? isSubmitting,
    bool? hasSubmitted,
    String? errorMessage,
    bool clearError = false,
  }) {
    return TaskWizardState(
      currentStep: currentStep ?? this.currentStep,
      selectedPlacements: selectedPlacements ?? this.selectedPlacements,
      assignments: assignments ?? this.assignments,
      paymentModes: paymentModes ?? this.paymentModes,
      activePlacement: clearActive ? null : (activePlacement ?? this.activePlacement),
      deliverNow: deliverNow ?? this.deliverNow,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      hasSubmitted: hasSubmitted ?? this.hasSubmitted,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

/// Résultat d'un envoi réussi.
class SubmitResult {
  final DeliveryBatch batch;
  final bool deliverNow;
  const SubmitResult({required this.batch, required this.deliverNow});
}

class TaskWizardController extends StateNotifier<TaskWizardState> {
  final OrdersRepository _ordersRepo;
  final TasksRepository _tasksRepo;
  final RobotRepository _robotRepo;
  final Ref? _ref;

  TaskWizardController({
    required OrdersRepository ordersRepo,
    required TasksRepository tasksRepo,
    required RobotRepository robotRepo,
    Ref? ref,
  })  : _ordersRepo = ordersRepo,
        _tasksRepo = tasksRepo,
        _robotRepo = robotRepo,
        _ref = ref,
        super(const TaskWizardState());

  bool get _locked => state.hasSubmitted || state.isSubmitting;

  // ------------------------------------------------------------ Étape 0 & Presets

  /// Réorganise l'ordre des destinations (par exemple table 3 puis table 1 puis table 5).
  void reorderDestinations(int oldIndex, int newIndex) {
    if (_locked) return;
    if (oldIndex < 0 || oldIndex >= state.selectedPlacements.length) return;
    final list = List<PlacementChoice>.from(state.selectedPlacements);
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    if (newIndex < 0 || newIndex >= list.length) return;
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(selectedPlacements: list, clearError: true);
  }

  void moveDestinationUp(int index) {
    if (index > 0) {
      reorderDestinations(index, index - 1);
    }
  }

  void moveDestinationDown(int index) {
    if (index < state.selectedPlacements.length - 1) {
      reorderDestinations(index, index + 2);
    }
  }

  /// Applique un preset de sélection rapide (1 table, 2 tables, 3 tables, ou toutes les tables).
  void applyTablesPreset(RobotStateModel robot, List<PendingOrder> orders, int wantedCount) {
    if (_locked) return;
    clearSelection();
    final count = wantedCount.clamp(1, robot.freeSlotsCount);
    autoSelect(robot, wanted: count);
    autoAssign(orders);
  }

  /// Ajoute ou retire une partie de la sélection.
  void togglePlacement(PlacementChoice choice) {
    if (_locked) return;
    final list = List<PlacementChoice>.from(state.selectedPlacements);
    final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments);
    if (list.contains(choice)) {
      list.remove(choice);
      assignments.remove(choice);
    } else {
      list.add(choice);
    }
    state = state.copyWith(
      selectedPlacements: list,
      assignments: assignments,
      clearActive: true,
      clearError: true,
    );
  }

  /// « Choisir pour moi » : remplit automatiquement les meilleures parties
  /// libres jusqu'à [wanted] parties au total. Les parties déjà choisies
  /// sont gardées. Retourne le nombre de parties ajoutées.
  int autoSelect(RobotStateModel robot, {required int wanted}) {
    if (_locked) return 0;
    final missing = wanted - state.count;
    if (missing <= 0) return 0;
    final extra = PlacementChoice.computeBestAutoPlacements(
      robot,
      missing,
      alreadyChosen: state.selectedPlacements,
    );
    if (extra.isEmpty) return 0;
    state = state.copyWith(
      selectedPlacements: [...state.selectedPlacements, ...extra],
      clearActive: true,
      clearError: true,
    );
    return extra.length;
  }

  void clearSelection() {
    if (_locked) return;
    state = state.copyWith(
      selectedPlacements: const [],
      assignments: const {},
      clearActive: true,
      clearError: true,
    );
  }

  /// Ajoute ou retire directement une destination depuis la carte ou la liste des tables.
  void toggleTableDestination(PendingOrder order, RobotStateModel robot) {
    if (_locked) return;
    final existingPlacement = state.placementForTable(order.tableNumber);
    if (existingPlacement != null) {
      // Déjà présente : on la retire
      final list = List<PlacementChoice>.from(state.selectedPlacements)..remove(existingPlacement);
      final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments)..remove(existingPlacement);
      state = state.copyWith(
        selectedPlacements: list,
        assignments: assignments,
        clearActive: true,
        clearError: true,
      );
      return;
    }

    // Pas encore présente : trouver un slot cible
    PlacementChoice? target = state.targetPlacement;
    if (target == null) {
      // Toutes les parties choisies sont déjà assignées, essayons d'en allouer une libre
      final added = PlacementChoice.computeBestAutoPlacements(
        robot,
        1,
        alreadyChosen: state.selectedPlacements,
      );
      if (added.isNotEmpty) {
        final list = [...state.selectedPlacements, ...added];
        target = added.first;
        final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments);
        assignments[target] = order;
        state = state.copyWith(
          selectedPlacements: list,
          assignments: assignments,
          clearActive: true,
          clearError: true,
        );
        return;
      } else {
        state = state.copyWith(
          errorMessage: 'Le robot n\'a plus de partie libre disponible.',
        );
        return;
      }
    } else {
      assignOrder(order);
    }
  }

  // ------------------------------------------------------------ Étape 1

  void setActivePlacement(PlacementChoice choice) {
    if (!state.isSelected(choice)) return;
    state = state.copyWith(activePlacement: choice, clearError: true);
  }

  /// Pose la commande de cette table sur la partie active (ou la première
  /// partie sans table). Une même table ne va que sur une seule partie.
  void assignOrder(PendingOrder order) {
    if (_locked) return;
    final existing = state.placementForTable(order.tableNumber);
    final target = state.targetPlacement;
    final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments);

    if (target == null) {
      // Tout est attribué : toucher une table déjà posée la retire.
      if (existing != null) {
        assignments.remove(existing);
        state = state.copyWith(assignments: assignments, activePlacement: existing, clearError: true);
      }
      return;
    }

    if (existing == target) {
      // Même table touchée deux fois : on l'enlève.
      assignments.remove(target);
      state = state.copyWith(assignments: assignments, activePlacement: target, clearError: true);
      return;
    }
    if (existing != null) assignments.remove(existing); // On la déplace.
    assignments[target] = order;

    // Passe automatiquement à la partie suivante sans table.
    PlacementChoice? next;
    for (final p in state.selectedPlacements) {
      if (!assignments.containsKey(p)) {
        next = p;
        break;
      }
    }
    state = state.copyWith(
      assignments: assignments,
      activePlacement: next,
      clearActive: next == null,
      clearError: true,
    );
  }

  void clearAssignment(PlacementChoice choice) {
    if (_locked) return;
    final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments)..remove(choice);
    state = state.copyWith(assignments: assignments, activePlacement: choice, clearError: true);
  }

  /// Remplit les parties sans table avec les commandes les plus anciennes
  /// qui ne sont pas encore posées.
  void autoAssign(List<PendingOrder> ordersOldestFirst) {
    if (_locked) return;
    final assignments = Map<PlacementChoice, PendingOrder>.from(state.assignments);
    final usedTables = assignments.values.map((o) => o.tableNumber).toSet();
    final it = ordersOldestFirst.where((o) => !usedTables.contains(o.tableNumber)).iterator;
    for (final p in state.selectedPlacements) {
      if (assignments.containsKey(p)) continue;
      if (!it.moveNext()) break;
      assignments[p] = it.current;
    }
    state = state.copyWith(assignments: assignments, clearActive: true, clearError: true);
  }

  // ------------------------------------------------------------ Étape 2

  void setPaymentMode(PendingOrder order, PaymentMode mode) {
    if (_locked) return;
    state = state.copyWith(paymentModes: {...state.paymentModes, order.id: mode}, clearError: true);
  }

  void setDeliverNow(bool value) {
    if (_locked) return;
    state = state.copyWith(deliverNow: value, clearError: true);
  }

  // ------------------------------------------------------------ Navigation

  void nextStep() {
    if (state.currentStep < TaskWizardState.lastStep && state.canGoToNextStep) {
      state = state.copyWith(currentStep: state.currentStep + 1, clearActive: true, clearError: true);
    }
  }

  void previousStep() {
    if (state.currentStep > 0 && !_locked) {
      state = state.copyWith(currentStep: state.currentStep - 1, clearError: true);
    }
  }

  /// Retour direct à une étape déjà vue (barre d'étapes).
  void goToStep(int step) {
    if (step < 0 || step >= state.currentStep || _locked) return;
    state = state.copyWith(currentStep: step, clearError: true);
  }

  // ------------------------------------------------------------ Envoi

  /// Re-vérifie l'état réel du robot, puis envoie TOUTES les commandes
  /// en une seule opération. Bloque le double envoi.
  Future<SubmitResult?> submit() async {
    if (state.isSubmitting || state.hasSubmitted) return null; // Anti-double envoi
    if (!state.allAssigned) {
      state = state.copyWith(errorMessage: 'Choisissez une table pour chaque partie.');
      return null;
    }

    final requests = state.requests;
    state = state.copyWith(isSubmitting: true, clearError: true);

    try {
      // 1. Re-vérification de l'état réel du robot juste avant l'envoi.
      final robot = await _robotRepo.getRobotStatus();

      if (!robot.canAcceptNewTask) {
        state = state.copyWith(
          isSubmitting: false,
          errorMessage: robot.disabledReason ?? "Le robot n'est plus disponible.",
        );
        return null;
      }

      final taken = <PlacementChoice>[];
      for (final r in requests) {
        final floor = robot.floors.where((f) => f.id == r.placement.floorId);
        if (floor.isEmpty || floor.first.slotByKey(r.placement.zoneKey).isOccupied) {
          taken.add(r.placement);
        }
      }
      if (taken.isNotEmpty) {
        final labels = taken.map((p) => p.shortCode).join(', ');
        state = state.copyWith(
          isSubmitting: false,
          currentStep: 0,
          selectedPlacements: state.selectedPlacements.where((p) => !taken.contains(p)).toList(),
          assignments: Map<PlacementChoice, PendingOrder>.from(state.assignments)
            ..removeWhere((p, _) => taken.contains(p)),
          errorMessage: taken.length == 1
              ? 'La partie $labels vient d\'être occupée. Choisissez une autre partie.'
              : 'Les parties $labels viennent d\'être occupées. Choisissez d\'autres parties.',
        );
        return null;
      }

      // 2. Un seul envoi pour toutes les commandes.
      final deliverNow = state.deliverNow;
      final batch = await _tasksRepo.createDeliveryBatch(requests: requests, deliverNow: deliverNow);

      // 3. Les plateaux sont rangés dans les parties (mock ; en HTTP le
      //    backend l'a déjà fait lors du POST).
      final taskByOrder = {for (final t in batch.tasks) t.orderId: t};
      await _robotRepo.assignOrders(
        [
          for (final r in requests)
            SlotAssignment(
              floorId: r.placement.floorId,
              zoneKey: r.placement.zoneKey,
              orderId: r.order.id,
              taskId: taskByOrder[r.order.id]?.id,
              tableNumber: r.order.tableNumber,
              itemsSummary: r.order.itemsSummary,
              paymentStatus: PaymentStatus.initial(withTpe: r.withTpe),
            ),
        ],
        deliverNow: deliverNow,
      );

      for (final r in requests) {
        await _ordersRepo.removePendingOrder(r.order.id);
        if (r.withTpe && _ref != null) {
          _ref!.read(tablePaymentsProvider.notifier).markPending(
                r.order.tableNumber,
                amount: r.order.totalPrice,
                orderId: r.order.id,
              );
        }
      }

      state = state.copyWith(isSubmitting: false, hasSubmitted: true);
      return SubmitResult(batch: batch, deliverNow: deliverNow);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Échec de l\'envoi : ${e.toString().replaceAll('Exception: ', '')}',
      );
      return null;
    }
  }
}

final taskWizardControllerProvider =
    StateNotifierProvider.autoDispose<TaskWizardController, TaskWizardState>((ref) {
  return TaskWizardController(
    ordersRepo: ref.watch(ordersRepositoryProvider),
    tasksRepo: ref.watch(tasksRepositoryProvider),
    robotRepo: ref.watch(robotRepositoryProvider),
    ref: ref,
  );
});
