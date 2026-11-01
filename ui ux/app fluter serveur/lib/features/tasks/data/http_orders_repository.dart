import '../../../core/network/api_client.dart';
import '../domain/pending_order.dart';
import 'orders_repository.dart';

/// Implémentation réseau connectée à l'API des commandes.
///
/// Endpoint appelé :
/// GET /api/orders?status=pending
class HttpOrdersRepository implements OrdersRepository {
  final ApiClient _apiClient;

  HttpOrdersRepository({ApiClient? apiClient})
      : _apiClient = apiClient ?? ApiClient();

  @override
  Future<List<PendingOrder>> getPendingOrders() async {
    final response = await _apiClient.get('/api/orders?status=pending');
    if (response is List) {
      final orders = response
          .map((item) => PendingOrder.fromJson(item as Map<String, dynamic>))
          .toList();
      orders.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      return orders;
    }
    return [];
  }

  @override
  Future<void> removePendingOrder(String orderId) async {
    await _apiClient.post('/api/orders/$orderId/dispatch');
  }
}
