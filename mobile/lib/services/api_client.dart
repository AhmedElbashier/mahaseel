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
  bool _refreshing = false;

  /// Call once in main() AFTER dotenv.load().
  // lib/services/api_client.dart
  void init() {
    if (_initialized) return;
    _initialized = true;

    final baseUrl = dotenv.env['API_BASE_URL'] ?? 'https://staging.mahaseel.com';
    if (kReleaseMode && !baseUrl.startsWith('https://')) {
      throw StateError('API_BASE_URL must use HTTPS in release builds');
    }

    // NEW: read optional path prefix ('' locally, '/api/v1' on envs that need it)
    final pathPrefix = (dotenv.env['API_PATH_PREFIX'] ?? '').trim();

    // Normalize slashes once
    String _joinBase(String a, String b) {
      final left = a.endsWith('/') ? a.substring(0, a.length - 1) : a;
      final right = b.isEmpty
          ? ''
          : (b.startsWith('/') ? b : '/$b');
      return '$left$right';
    }

    dio = Dio(BaseOptions(
      baseUrl: _joinBase(baseUrl, pathPrefix),  // ← no more hardcoded /api/v1
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      responseType: ResponseType.json,
    ));

    // 1) X-Request-ID, 2) Auth header, 3) Logging, 4) Auto-refresh ... (unchanged)
    dio.interceptors.add(RequestIdInterceptor());
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
    dio.interceptors.add(PiiSafeLogInterceptor(sampleRate: 1.0));
    dio.interceptors.add(InterceptorsWrapper(
      onError: (error, handler) async {
        final status = error.response?.statusCode;
        final req = error.requestOptions;
        final triedRefresh = req.extra['__tried_refresh__'] == true;
        if ((status == 401 || status == 403) && !triedRefresh) {
          req.extra['__tried_refresh__'] = true;
          final ok = await _tryRefresh();
          if (ok) {
            final newToken = await _storage.read(key: 'jwt');
            if (newToken != null) {
              req.headers['Authorization'] = 'Bearer $newToken';
            }
            try {
              final clone = await dio.fetch(req);
              return handler.resolve(clone);
            } catch (_) {}
          }
          await clearAllTokens();
          if (onUnauthorized != null) await onUnauthorized!();
        }
        handler.next(error);
      },
    ));
  }


  Future<void> saveToken(String token) async =>
      _storage.write(key: 'jwt', value: token);

  Future<void> saveTokens({required String access, String? refresh}) async {
    await _storage.write(key: 'jwt', value: access);
    if (refresh != null && refresh.isNotEmpty) {
      await _storage.write(key: 'refresh_jwt', value: refresh);
    }
  }

  Future<void> clearToken() async =>
      _storage.delete(key: 'jwt');

  Future<void> clearAllTokens() async {
    await _storage.delete(key: 'jwt');
    await _storage.delete(key: 'refresh_jwt');
  }

  Future<bool> hasToken() async {
    final t = await _storage.read(key: 'jwt');
    return t != null && t.isNotEmpty;// <-- ensure not empty
  }

  Future<bool> _tryRefresh() async {
    if (_refreshing) return false;
    _refreshing = true;
    try {
      final refresh = await _storage.read(key: 'refresh_jwt');
      if (refresh == null || refresh.isEmpty) return false;
      final res = await dio.post('/auth/refresh', data: {'refresh_token': refresh});
      final map = (res.data as Map).cast<String, dynamic>();
      final newAccess = (map['access_token'] ?? '').toString();
      if (newAccess.isEmpty) return false;
      await _storage.write(key: 'jwt', value: newAccess);
      return true;
    } catch (_) {
      return false;
    } finally {
      _refreshing = false;
    }
  }
}
