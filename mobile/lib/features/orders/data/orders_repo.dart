import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../models/order.dart';

class OrdersRepo {
  final Dio _dio = ApiClient().dio;

  Future<Order> createOrder(int cropId, double qty, {String? note}) async {
    final res = await _dio.post('/orders', data: {
      'crop_id': cropId,
      'qty': qty,
      if (note != null && note.isNotEmpty) 'note': note,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    return Order.fromJson(data);
  }

  /// NOTE: Your path here is `/orders/seller/{sellerId}`.
  /// If the backend uses `/sales/orders`, adjust accordingly.
  Future<List<Order>> fetchSellerOrders(int sellerId) async {
    final res = await _dio.get('/orders/seller/$sellerId');
    final list = (res.data as List);
    return list
        .map((e) => Order.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
  }

  /// If you want buyer orders with status filter:
  Future<List<Order>> fetchBuyerOrders({String? status, int page = 1, int limit = 20}) async {
    final res = await _dio.get('/orders', queryParameters: {
      if (status != null && status != 'all') 'status': status,
      'page': page,
      'limit': limit,
    });
    final data = (res.data as Map).cast<String, dynamic>();
    final items = (data['items'] as List? ?? const [])
        .map((e) => Order.fromJson((e as Map).cast<String, dynamic>()))
        .toList();
    return items;
  }
}
