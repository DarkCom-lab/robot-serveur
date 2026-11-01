import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/config/app_config.dart';
import '../data/robot_repository.dart';
import '../data/mock_robot_repository.dart';
import '../data/http_robot_repository.dart';
import '../domain/robot_state.dart';
import '../domain/robot_status.dart';

/// Provider du singleton de Repository Robot.
final robotRepositoryProvider = Provider<RobotRepository>((ref) {
  if (AppConfig.useMock) {
    final repo = MockRobotRepository();
    ref.onDispose(repo.dispose);
    return repo;
  }
  final repo = HttpRobotRepository();
  ref.onDispose(repo.dispose);
  return repo;
});

/// Provider réactif en temps réel de l'état du robot.
final robotStateStreamProvider = StreamProvider<RobotStateModel>((ref) {
  final repository = ref.watch(robotRepositoryProvider);
  return repository.watchRobotStatus();
});

/// Actions de contrôle et de simulation.
class RobotActionController {
  final RobotRepository _repository;

  RobotActionController(this._repository);

  void setBattery(int percent) => _repository.simulateBatteryLevel(percent);
  void occupyAllSlots() => _repository.simulateOccupyAllSlots();
  void halfOccupied() => _repository.simulateHalfOccupied();
  void dispatchStored() => _repository.dispatchStoredOrders();
  void freeAllSlots() => _repository.simulateFreeAllSlots();
  void setStatus(RobotStatus status) => _repository.simulateStatus(status);
  void setCharging(bool charging) => _repository.simulateCharging(charging);
}

final robotActionControllerProvider = Provider<RobotActionController>((ref) {
  return RobotActionController(ref.watch(robotRepositoryProvider));
});
