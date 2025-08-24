import 'package:flutter_test/flutter_test.dart';
import 'package:mahaseel/features/orders/data/orders_repo.dart';
import 'package:mahaseel/services/api_client.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiClient().init();
    ApiClient().dio.interceptors.clear();
  });

  test('createOrder returns data on success', () async {
    ApiClient().dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 201,
          data: {
            'id': 1,
            'qty': 2.0,
            'note': null,
            'status': 'new',
            'crop_id': 1,
            'buyer_id': 1,
          },
        ));
      }),
    );
    final repo = OrdersRepo();
    final order = await repo.createOrder(1, 2.0);
    expect(order.qty, 2.0);
    expect(order.cropId, 1);
  });

  test('createOrder throws on failure', () async {
    ApiClient().dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        handler.reject(DioException(
          requestOptions: options,
          response: Response(requestOptions: options, statusCode: 500),
          type: DioExceptionType.badResponse,
        ));
      }),
    );
    final repo = OrdersRepo();
    expect(() => repo.createOrder(1, 1.0), throwsA(isA<DioException>()));
  });
}
