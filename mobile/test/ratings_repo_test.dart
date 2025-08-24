import 'package:flutter_test/flutter_test.dart';
import 'package:mahaseel/features/ratings/data/ratings_repo.dart';
import 'package:mahaseel/services/api_client.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:dio/dio.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    ApiClient().init();
    ApiClient().dio.interceptors.clear();
  });

  test('submitRating succeeds', () async {
    ApiClient().dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(requestOptions: options, statusCode: 201));
      }),
    );
    FlutterSecureStorage.setMockInitialValues({'jwt': 'token'});
    final repo = RatingsRepo();
    await repo.submitRating(sellerId: 1, stars: 5);
  });

  test('submitRating duplicate throws', () async {
    ApiClient().dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 400,
          data: {'detail': 'You already rated this seller/crop'},
        ));
      }),
    );
    FlutterSecureStorage.setMockInitialValues({'jwt': 'token'});
    final repo = RatingsRepo();
    expect(
      () => repo.submitRating(sellerId: 1, stars: 5),
      throwsA(predicate((e) => e.toString().contains('ALREADY_RATED'))),
    );
  });
}
