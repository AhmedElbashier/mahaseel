import 'package:dio/dio.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._();
  factory ApiClient() => _i;
  ApiClient._();

  final dio = Dio(BaseOptions(
    baseUrl: const String.fromEnvironment('BASE_URL', defaultValue: 'http://10.0.2.2:8000'),
    connectTimeout: const Duration(seconds: 10),
    receiveTimeout: const Duration(seconds: 15),
  ));
}
