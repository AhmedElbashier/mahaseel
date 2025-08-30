// lib/services/api_client.dart
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/foundation.dart';
import 'logging_interceptor.dart';

class ApiClient {
  static final ApiClient _i = ApiClient._();
  factory ApiClient() => _i;
  ApiClient._();

  final _storage = const FlutterSecureStorage();

  /// We create Dio inside init() AFTER .env is loaded.
  late final Dio dio;

  bool _initialized = false;
  /// Callback triggered when the backend returns 401/403.
  Future<void> Function()? onUnauthorized;

  /// Call once in main() AFTER dotenv.load().
  void init() {
    if (_initialized) return;
    _initialized = true;

    final baseUrl =
        dotenv.env['API_BASE_URL'] ?? 'https://staging.mahaseel.com';
    if (kReleaseMode && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL must use HTTPS in release builds');
    }

    dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ));

    // 1) Add X-Request-ID for backend correlation
    dio.interceptors.add(RequestIdInterceptor());

    // 2) Auth header
    dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await _storage.read(key: 'jwt');
        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        } else {
          options.headers.remove('Authorization');
        }
        handler.next(options);
      },
    ));

    // 3) PII-safe logging (debug/profile only)
    dio.interceptors.add(PiiSafeLogInterceptor(
      sampleRate: 1.0, // you can set 0.2 in profile if too chatty
    ));

    // 4) Logout on expired/invalid token
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        if (status == 401 || status == 403) {
          await clearToken();
          if (onUnauthorized != null) {
            await onUnauthorized!();
          }
        }
        handler.next(error);
      },
      onResponse: (response, handler) async {
        final status = response.statusCode;
        if (status == 401 || status == 403) {
          await clearToken();
          if (onUnauthorized != null) {
            await onUnauthorized!();
          }
        }
        handler.next(response);
      },
    ));

    // ⚠️ Remove the default Dio LogInterceptor; ours is safer.
    // dio.interceptors.add(LogInterceptor(...));  // ← delete this
  }

  Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt', value: token);

  Future<void> clearToken() async =>
      _storage.delete(key: 'jwt');

  Future<bool> hasToken() async {
    final t = await _storage.read(key: 'jwt');
    return t != null && t.isNotEmpty;// <-- ensure not empty
  }
}
