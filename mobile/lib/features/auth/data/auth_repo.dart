// lib/features/auth/data/auth_repo.dart
import '../../../services/api_client.dart';
import '../phone_formatter.dart'; // <-- ensures formatPhone is available

class AuthRepo {
  final _dio = ApiClient().dio;

  Future<String?> login({required String phone}) async {
    final normalized = formatPhone(phone);
    final res = await _dio.post('/auth/login', data: {'phone': normalized});
    // dev: server may include {dev_otp: '123456'} to display during development
    return (res.data is Map && res.data['dev_otp'] is String)
        ? res.data['dev_otp'] as String
        : null;
  }

  Future<void> register({required String phone, required String name}) async {
    final normalized = formatPhone(phone);
    await _dio.post('/auth/register', data: {'phone': normalized, 'name': name});
  }

  Future<String> verify({required String phone, required String otp}) async {
    final normalized = formatPhone(phone);
    final res = await _dio.post('/auth/verify', data: {'phone': normalized, 'otp': otp});
    print('[OTP] verify phone=${formatPhone(phone)} otp=$otp');

    return (res.data as Map)['access_token'] as String;
  }
}
