import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._();
  factory ApiClient() => _i;
  ApiClient._();
  late final Dio dio = Dio(BaseOptions(
    baseUrl: dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000',
    connectTimeout: const Duration(seconds: 15),
    receiveTimeout: const Duration(seconds: 20),
  ))
    ..interceptors.add(LogInterceptor(
      request: true, requestBody: true,
      responseBody: true, error: true,
    ));


  final _storage = const FlutterSecureStorage();

  void attachAuth() {
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null) options.headers['Authorization'] = 'Bearer $token';
        handler.next(options);
      },
    ));
  }

  Future<void> saveToken(String token) async => _storage.write(key: 'jwt', value: token);
  Future<void> clearToken() async => _storage.delete(key: 'jwt');
  Future<bool> hasToken() async => (await _storage.read(key: 'jwt')) != null;


}
