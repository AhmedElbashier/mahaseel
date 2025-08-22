// lib/features/auth/data/auth_repo.dart
import '../../../services/api_client.dart';

class AuthRepo {
  final _dio = ApiClient().dio;

  Future<String?> login({required String phone}) async {
    final res = await _dio.post('/auth/login', data: {'phone': phone});
    // dev: server may include {dev_otp: '123456'} to display during development
    return (res.data is Map && res.data['dev_otp'] is String)
        ? res.data['dev_otp'] as String
        : null;
  }

  Future<void> register({required String phone, required String name}) async {
    await _dio.post('/auth/register', data: {'phone': phone, 'name': name});
  }

  Future<String> verify({required String phone, required String otp}) async {
    final res = await _dio.post('/auth/verify', data: {'phone': phone, 'otp': otp});
    return (res.data as Map)['access_token'] as String;
  }
}
