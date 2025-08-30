// lib/features/auth/data/auth_repo.dart
import '../../../services/api_client.dart';
import '../phone_formatter.dart'; // <-- ensures formatPhone is available
import 'package:flutter/foundation.dart';
import 'package:dio/dio.dart';
import '../../../core/http/fastapi_errors.dart';

class AuthRepo {
  final _dio = ApiClient().dio;

  Future<String?> login({required String phone}) async {
    final normalized = formatPhone(phone);
    final res = await _dio.post('/auth/login', data: {'phone': normalized});
    // dev: server may include {dev_otp: '123456'} to display during development
    if (kReleaseMode) return null;
    return (res.data is Map && res.data['dev_otp'] is String)
        ? res.data['dev_otp'] as String
        : null;
  }

  Future<void> register({required String phone, required String name}) async {
    final normalized = formatPhone(phone);
    await _dio.post('/auth/register', data: {'phone': normalized, 'name': name});
  }

  Future<Map<String, String>> verify({required String phone, required String otp}) async {
    try {
      final normalized = formatPhone(phone);
      final res = await _dio.post('/auth/verify', data: {'phone': normalized, 'otp': otp});
      if (kDebugMode) {
        debugPrint('[OTP] verify phone=${formatPhone(phone)} otp=$otp');
      }
      final map = (res.data as Map).cast<String, dynamic>();
      return {
        'access_token': (map['access_token'] ?? '').toString(),
        'refresh_token': (map['refresh_token'] ?? '').toString(),
      };
    } on DioException catch (e) {
      // Surface friendlier messages for lockouts/rate limits
      if ((e.response?.statusCode ?? 0) == 429) {
        final data = e.response?.data;
        if (data is Map && data['error'] is Map) {
          final err = (data['error'] as Map).cast<String, dynamic>();
          final msg = (err['message'] ?? '').toString();
          final until = err['locked_until'];
          if (until is String && until.isNotEmpty) {
            try {
              final dt = DateTime.tryParse(until);
              if (dt != null) {
                final minutes = dt.difference(DateTime.now()).inMinutes.clamp(1, 60);
                throw Exception('محاولات كثيرة، حاول بعد ${minutes} دقيقة');
              }
            } catch (_) {}
          }
          if (msg.isNotEmpty) throw Exception(msg);
        }
      }
      throw Exception(friendlyError(e));
    }
  }
  Future<Map<String, dynamic>> meRaw() async {
    final res = await _dio.get('/auth/me');
    return (res.data as Map).cast<String, dynamic>();
  }


}
