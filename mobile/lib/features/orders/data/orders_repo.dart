import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../models/order.dart';

class OrdersRepo {
  final _dio = ApiClient().dio;

  Future<Order> createOrder(int cropId, double qty, {String? note}) async {
    final res = await _dio.post('/orders', data: {
      'crop_id': cropId,
      'qty': qty,
      if (note != null) 'note': note,
    });
    return Order.fromJson(res.data);
  }

  Future<List<Order>> fetchSellerOrders(int sellerId) async {
    final res = await _dio.get('/orders/seller/$sellerId');
    return (res.data as List).map((o) => Order.fromJson(o)).toList();
  }
}
