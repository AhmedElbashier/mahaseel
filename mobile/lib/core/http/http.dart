import 'package:dio/dio.dart';
import '../app_config.dart';

class Http {
  static final Dio dio =
      Dio(
          BaseOptions(
            baseUrl: AppConfig.apiBaseUrl,
            connectTimeout: const Duration(seconds: 10),
            receiveTimeout: const Duration(seconds: 15),
            headers: {'Accept': 'application/json'},
          ),
        )
        ..interceptors.add(
          InterceptorsWrapper(
            onRequest: (options, handler) => handler.next(options),
            onResponse: (resp, handler) => handler.next(resp),
            onError: (e, handler) {
              // normalize errors
              return handler.next(e);
            },
          ),
        );
}
