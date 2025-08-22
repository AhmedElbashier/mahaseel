import 'package:dio/dio.dart';
import '../core/http.dart';

class HealthService {
  static Future<Object> isUp() async {
    try {
      final Response r = await Http.dio.get('/healthz');
      return r.statusCode = 200;
    } catch (_) {
      return false;
    }
  }
}
