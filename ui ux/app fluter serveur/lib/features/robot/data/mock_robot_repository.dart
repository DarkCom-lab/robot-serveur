import 'dart:async';
import '../../../core/config/mock_timeline.dart';
import '../../tasks/domain/delivery_request.dart';
import '../../tasks/domain/task_model.dart';
import '../domain/floor_model.dart';
import '../domain/payment_status.dart';
import '../domain/robot_state.dart';
import '../domain/robot_status.dart';
import '../domain/slot_assignment.dart';
import 'robot_repository.dart';

/// Implémentation MOCK du robot Fabtino. C'est aussi le « moteur » qui fait
/// avancer les livraisons, pour que l'écran du robot et l'écran de suivi
/// soient toujours d'accord :
///
/// - 3 étages identiques x 2 parties (A gauche / B droite) = 6 parties ;
/// - plusieurs commandes rangées en une seule opération ;
/// - tournée : une table après l'autre, dans l'ordre choisi ;
/// - TPE : le robot garde « TPE en attente » en mémoire et attend à la
///   table que le client appuie sur « J'ai terminé » (aucune alerte au
///   serveur). Il passe alors à « Payé », annonce
///   « C'est bon, paiement validé », puis repart ;
/// - recharge de la batterie et déclencheurs manuels pour les tests.
class MockRobotRepository implements RobotRepository {
  /// Accélère la simulation (1.0 = démo, 0.001 en tests).
  final double speed;

  late RobotStateModel _state;
  final StreamController<RobotStateModel> _robotController =
      StreamController<RobotStateModel>.broadcast();

  // --- Livraisons ---
  final Map<String, RobotTask> _tasks = {};
  final Map<String, List<String>> _batches = {};
  final StreamController<RobotTask> _taskController = StreamController<RobotTask>.broadcast();

  /// File de la tournée en cours (ids de livraisons, dans l'ordre de passage).
  final List<String> _tourQueue = [];
  bool _touring = false;
  String? _waitingPaymentTaskId;
  final List<Timer> _timers = [];
  Timer? _chargingTicker;
  int _idSeq = 0;

  /// Dernière phrase dite par le robot.
  String? lastAnnouncement;

  MockRobotRepository({this.speed = 1.0}) {
    _state = RobotStateModel.initial();
    _chargingTicker = Timer.periodic(_d(const Duration(seconds: 5)), (_) {
      if (_state.status == RobotStatus.charging) {
        final level = (_state.batteryPercentage + 5).clamp(0, 100);
        _emit(_state.copyWith(batteryPercentage: level));
      }
    });
  }

  /// État courant (lecture synchrone, utile aux tests).
  RobotStateModel get currentState => _state;

  Duration _d(Duration base) => Duration(microseconds: (base.inMicroseconds * speed).round());

  void _after(Duration base, void Function() action) {
    late Timer t;
    t = Timer(_d(base), () {
      _timers.remove(t);
      action();
    });
    _timers.add(t);
  }

  void _emit(RobotStateModel next) {
    _state = next.copyWith(lastUpdated: DateTime.now());
    if (!_robotController.isClosed) _robotController.add(_state);
  }

  void _updateTask(RobotTask task) {
    _tasks[task.id] = task;
    if (!_taskController.isClosed) _taskController.add(task);
  }

  void _updateSlot(int floorId, String zoneKey, ZoneSlot Function(ZoneSlot) change) {
    final floors = _state.floors
        .map((f) => f.id == floorId ? f.withSlot(zoneKey, change(f.slotByKey(zoneKey))) : f)
        .toList();
    _emit(_state.copyWith(floors: floors));
  }

  // ====================================================================
  // RobotRepository
  // ====================================================================

  @override
  Future<RobotStateModel> getRobotStatus() async {
    await Future.delayed(_d(const Duration(milliseconds: 150)));
    return _state;
  }

  @override
  Stream<RobotStateModel> watchRobotStatus() async* {
    yield _state;
    yield* _robotController.stream;
  }

  @override
  Future<void> assignOrders(
    List<SlotAssignment> assignments, {
    required bool deliverNow,
  }) async {
    var floors = _state.floors;
    for (final a in assignments) {
      floors = floors
          .map((f) => f.id == a.floorId
              ? f.withSlot(
                  a.zoneKey,
                  ZoneSlot(
                    zoneKey: a.zoneKey,
                    orderId: a.orderId,
                    taskId: a.taskId,
                    tableNumber: a.tableNumber,
                    itemsSummary: a.itemsSummary,
                    paymentStatus: a.paymentStatus,
                    isStored: !deliverNow,
                  ))
              : f)
          .toList();
    }
    _emit(_state.copyWith(floors: floors));

    if (deliverNow) {
      _startTour([
        for (final a in assignments)
          if (a.taskId != null) a.taskId!,
      ]);
    }
  }

  @override
  Future<void> dispatchStoredOrders() async {
    final ids = <String>[];
    final floors = _state.floors.map((f) {
      var floor = f;
      for (final s in f.slots) {
        if (s.isOccupied && s.isStored) {
          if (s.taskId != null) ids.add(s.taskId!);
          floor = floor.withSlot(s.zoneKey, s.copyWith(isStored: false));
        }
      }
      return floor;
    }).toList();
    if (ids.isEmpty) return;
    _emit(_state.copyWith(floors: floors));
    for (final id in ids) {
      final t = _tasks[id];
      if (t != null) _updateTask(t.copyWith(isStored: false));
    }
    _startTour(ids);
  }

  @override
  Future<void> freeSlot({required int floorId, required String zoneKey}) async {
    _updateSlot(floorId, zoneKey, (_) => ZoneSlot(zoneKey: zoneKey));
  }

  // ====================================================================
  // Moteur des livraisons (utilisé par MockTasksRepository)
  // ====================================================================

  /// Crée les fiches de livraison d'une opération (sans toucher aux parties :
  /// c'est [assignOrders] qui range les plateaux).
  DeliveryBatch createBatch(List<DeliveryRequest> requests, {required bool deliverNow}) {
    final stamp = DateTime.now().millisecondsSinceEpoch % 100000;
    final batchId = 'OP-$stamp-${_idSeq++}';
    final ids = <String>[];
    for (var i = 0; i < requests.length; i++) {
      final r = requests[i];
      final task = RobotTask(
        id: 'TSK-$stamp-${_idSeq++}',
        batchId: batchId,
        stopIndex: i,
        orderId: r.order.id,
        tableNumber: r.order.tableNumber,
        floorId: r.placement.floorId,
        zoneKey: r.placement.zoneKey,
        paymentStatus: PaymentStatus.initial(withTpe: r.withTpe),
        currentStep: DeliveryStep.pending,
        isStored: !deliverNow,
        createdAt: DateTime.now(),
      );
      ids.add(task.id);
      _updateTask(task);
    }
    _batches[batchId] = ids;
    return batch(batchId)!;
  }

  DeliveryBatch? batch(String batchId) {
    final ids = _batches[batchId];
    if (ids == null) return null;
    return DeliveryBatch(
      id: batchId,
      tasks: [
        for (final id in ids)
          if (_tasks[id] != null) _tasks[id]!
      ],
    );
  }

  Stream<DeliveryBatch> watchBatch(String batchId) async* {
    final first = batch(batchId);
    if (first == null) throw Exception('Opération introuvable');
    yield first;
    yield* _taskController.stream.where((t) => t.batchId == batchId).map((_) => batch(batchId)!);
  }

  /// Le client a appuyé sur « J'ai terminé » sur le robot.
  RobotTask markPaymentDone(String taskId) {
    int? floorId;
    String? zoneKey;
    for (final f in _state.floors) {
      for (final s in f.slots) {
        if (s.taskId == taskId) {
          floorId = f.id;
          zoneKey = s.zoneKey;
        }
      }
    }
    final task = _tasks[taskId];

    if (task != null) {
      if (task.paymentStatus == PaymentStatus.tpePaid) return task; // Déjà fait.
      if (task.paymentStatus != PaymentStatus.tpePending) {
        throw Exception('Cette commande ne demande pas de paiement TPE.');
      }
      if (!task.isDelivered) {
        throw Exception("Le robot n'est pas encore à la table.");
      }
    } else if (floorId == null) {
      throw Exception('Commande introuvable sur le robot.');
    }

    lastAnnouncement = PaymentStatus.paidAnnouncement;
    final paid = task?.copyWith(paymentStatus: PaymentStatus.tpePaid, completedAt: DateTime.now());
    if (paid != null) _updateTask(paid);

    if (floorId != null && zoneKey != null) {
      final f = floorId, z = zoneKey;
      _updateSlot(f, z, (s) => s.copyWith(paymentStatus: PaymentStatus.tpePaid));
      // « Payé » reste visible un instant sur le robot, puis la partie se libère.
      _after(MockTimeline.paidDisplay, () {
        final current = _state.floors.firstWhere((x) => x.id == f).slotByKey(z);
        if (current.taskId == taskId) _updateSlot(f, z, (_) => ZoneSlot(zoneKey: z));
        if (_waitingPaymentTaskId == taskId) {
          _waitingPaymentTaskId = null;
          _nextStop();
        }
      });
    } else if (_waitingPaymentTaskId == taskId) {
      _waitingPaymentTaskId = null;
      _nextStop();
    }

    return paid ??
        RobotTask(
          id: taskId,
          batchId: taskId,
          orderId: '',
          tableNumber: '',
          floorId: floorId!,
          zoneKey: zoneKey!,
          paymentStatus: PaymentStatus.tpePaid,
          currentStep: DeliveryStep.delivered,
          createdAt: DateTime.now(),
        );
  }

  // --- Tournée ---

  void _startTour(List<String> taskIds) {
    if (taskIds.isEmpty) return;
    _tourQueue.addAll(taskIds);
    if (_touring) return; // Ajoutées à la tournée en cours.
    _touring = true;

    final first = _tasks[_tourQueue.first];
    _emit(_state.copyWith(
      status: RobotStatus.delivering,
      activeTaskId: first?.batchId,
      activeDestinationTable: first?.tableNumber,
    ));

    _after(MockTimeline.picking, () => _advanceQueued(DeliveryStep.picking));
    _after(MockTimeline.rolling, () => _advanceQueued(DeliveryStep.delivering));
    _after(MockTimeline.firstArrival, _arriveAtCurrentStop);
  }

  void _advanceQueued(DeliveryStep step) {
    for (final id in List.of(_tourQueue)) {
      final t = _tasks[id];
      if (t != null && t.currentStep.index < step.index) {
        _updateTask(t.copyWith(currentStep: step));
      }
    }
  }

  void _arriveAtCurrentStop() {
    if (_tourQueue.isEmpty) return _endTour();
    final id = _tourQueue.first;
    final task = _tasks[id];
    if (task == null) {
      _tourQueue.removeAt(0);
      return _arriveAtCurrentStop();
    }
    final waitsTpe = task.paymentStatus == PaymentStatus.tpePending;
    _updateTask(task.copyWith(
      currentStep: DeliveryStep.delivered,
      completedAt: waitsTpe ? null : DateTime.now(),
    ));
    _emit(_state.copyWith(activeDestinationTable: task.tableNumber));

    if (waitsTpe) {
      // Le robot attend, en silence, que le client finisse de payer.
      _waitingPaymentTaskId = id;
      return;
    }
    // Sans TPE : le robot marque l'arrêt à la table pendant dwellAtStop,
    // puis le plateau est récupéré, et il repart vers la destination suivante.
    _after(MockTimeline.dwellAtStop, () {
      _updateSlot(task.floorId, task.zoneKey, (_) => ZoneSlot(zoneKey: task.zoneKey));
      _nextStop();
    });
  }

  void _nextStop() {
    if (_tourQueue.isNotEmpty) _tourQueue.removeAt(0);
    if (_tourQueue.isEmpty) return _endTour();
    _advanceQueued(DeliveryStep.delivering);
    final next = _tasks[_tourQueue.first];
    _emit(_state.copyWith(activeDestinationTable: next?.tableNumber));
    _after(MockTimeline.perStop, _arriveAtCurrentStop);
  }

  void _endTour() {
    _touring = false;
    _waitingPaymentTaskId = null;
    _emit(_state.copyWith(
      status: _state.status == RobotStatus.delivering ? RobotStatus.idle : _state.status,
      clearActiveTask: true,
    ));
  }

  void _cancelTour() {
    for (final t in _timers) {
      t.cancel();
    }
    _timers.clear();
    _tourQueue.clear();
    _touring = false;
    _waitingPaymentTaskId = null;
  }

  // ====================================================================
  // ACTIONS DE SIMULATION (TESTS & DÉMO)
  // ====================================================================

  @override
  void simulateBatteryLevel(int percentage) =>
      _emit(_state.copyWith(batteryPercentage: percentage.clamp(0, 100)));

  /// Les 6 parties (3 étages x A/B) sont occupées.
  @override
  void simulateOccupyAllSlots() {
    _cancelTour();
    ZoneSlot s(String k, String id, String table, String items,
            [PaymentStatus p = PaymentStatus.none]) =>
        ZoneSlot(
            zoneKey: k,
            orderId: id,
            taskId: 'SIM-$id',
            tableNumber: table,
            itemsSummary: items,
            paymentStatus: p);
    _emit(_state.copyWith(
      floors: [
        RobotFloor(
            id: 3,
            zoneA: s('A', '#CMD-101', 'Table 4', '2x Café Crème'),
            zoneB: s('B', '#CMD-102', 'Table 8', '1x Matcha Latte', PaymentStatus.tpePending)),
        RobotFloor(
            id: 2,
            zoneA: s('A', '#CMD-103', 'Table 1', '1x Cappuccino'),
            zoneB: s('B', '#CMD-104', 'Table 6', '2x Espresso')),
        RobotFloor(
            id: 1,
            zoneA: s('A', '#CMD-105', 'Table 9', 'Petit-déjeuner', PaymentStatus.tpePending),
            zoneB: s('B', '#CMD-106', 'Table 3', '1x Thé menthe')),
      ],
      status: RobotStatus.delivering,
    ));
  }

  /// 3 parties occupées sur 6 (dont une avec « TPE en attente »).
  @override
  void simulateHalfOccupied() {
    _cancelTour();
    _emit(_state.copyWith(
      floors: const [
        RobotFloor(id: 3),
        RobotFloor(
          id: 2,
          zoneA: ZoneSlot(
              zoneKey: 'A',
              orderId: '#CMD-103',
              taskId: 'SIM-103',
              tableNumber: 'Table 1',
              itemsSummary: '1x Cappuccino',
              paymentStatus: PaymentStatus.tpePending),
        ),
        RobotFloor(
          id: 1,
          zoneA: ZoneSlot(
              zoneKey: 'A',
              orderId: '#CMD-105',
              taskId: 'SIM-105',
              tableNumber: 'Table 9',
              itemsSummary: 'Petit-déjeuner'),
          zoneB: ZoneSlot(
              zoneKey: 'B',
              orderId: '#CMD-106',
              taskId: 'SIM-106',
              tableNumber: 'Table 3',
              itemsSummary: '1x Thé menthe'),
        ),
      ],
      status: RobotStatus.idle,
      clearActiveTask: true,
    ));
  }

  @override
  void simulateFreeAllSlots() {
    _cancelTour();
    _emit(RobotStateModel.initial().copyWith(batteryPercentage: _state.batteryPercentage));
  }

  @override
  void simulateStatus(RobotStatus status) => _emit(_state.copyWith(
        status: status,
        isCharging: status == RobotStatus.charging,
      ));

  @override
  void simulateCharging(bool charging) => _emit(_state.copyWith(
        isCharging: charging,
        status: charging ? RobotStatus.charging : RobotStatus.idle,
      ));

  void dispose() {
    _chargingTicker?.cancel();
    _cancelTour();
    _robotController.close();
    _taskController.close();
  }
}
