import 'dart:async';
import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/websocket_client.dart';
import '../domain/robot_state.dart';
import '../domain/robot_status.dart';
import '../domain/slot_assignment.dart';
import 'robot_repository.dart';

/// Implémentation réseau connectée à l'API réelle.
///
/// Endpoints utilisés :
/// GET /api/robot/status   -> { status, battery, floors: [ { id, zoneA, zoneB } ] }
///   (chaque partie : { zoneKey, orderId, taskId, tableNumber, paymentStatus })
/// WS  /ws/robot           -> événements en temps réel
class HttpRobotRepository implements RobotRepository {
  final ApiClient _apiClient;
  final WebSocketClient _wsClient;
  Timer? _pollingTimer;
  final StreamController<RobotStateModel> _controller =
      StreamController<RobotStateModel>.broadcast();

  HttpRobotRepository({
    ApiClient? apiClient,
    WebSocketClient? wsClient,
  })  : _apiClient = apiClient ?? ApiClient(),
        _wsClient = wsClient ?? WebSocketClient() {
    _listenWebSocket();
    _startPollingFallback();
  }

  void _listenWebSocket() {
    _wsClient.stream.listen((data) {
      if (data is Map<String, dynamic>) {
        try {
          _controller.add(RobotStateModel.fromJson(data));
        } catch (_) {}
      }
    });
  }

  void _startPollingFallback() {
    _pollingTimer = Timer.periodic(
      const Duration(milliseconds: AppConfig.pollingIntervalMs),
      (_) async {
        try {
          _controller.add(await getRobotStatus());
        } catch (_) {}
      },
    );
  }

  @override
  Future<RobotStateModel> getRobotStatus() async {
    final response = await _apiClient.get('/api/robot/status');
    if (response is Map<String, dynamic>) {
      return RobotStateModel.fromJson(response);
    }
    throw ApiException(statusCode: 500, message: 'Format de statut robot invalide');
  }

  @override
  Stream<RobotStateModel> watchRobotStatus() => _controller.stream;

  @override
  Future<void> assignOrders(
    List<SlotAssignment> assignments, {
    required bool deliverNow,
  }) async {
    // Rien à faire ici : les livraisons sont déjà créées en une fois par
    // TasksRepository.createDeliveryBatch (POST /api/robot/tasks/batch).
    // Le backend met à jour les parties et les renvoie via /api/robot/status
    // et le WebSocket.
  }

  @override
  Future<void> dispatchStoredOrders() async {
    await _apiClient.post('/api/robot/dispatch', body: {});
  }

  @override
  Future<void> freeSlot({required int floorId, required String zoneKey}) async {
    await _apiClient.post(
      '/api/robot/floors/free',
      body: {'floorId': floorId, 'zone': zoneKey},
    );
  }

  // En mode HTTP réel, les simulations locales sont désactivées.
  @override
  void simulateBatteryLevel(int percentage) {}
  @override
  void simulateCharging(bool charging) {}
  @override
  void simulateFreeAllSlots() {}
  @override
  void simulateOccupyAllSlots() {}
  @override
  void simulateHalfOccupied() {}
  @override
  void simulateStatus(RobotStatus status) {}

  void dispose() {
    _pollingTimer?.cancel();
    _wsClient.dispose();
    _controller.close();
  }
}
