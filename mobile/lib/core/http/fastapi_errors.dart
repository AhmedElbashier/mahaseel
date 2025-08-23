// lib/core/http/fastapi_errors.dart
import 'package:dio/dio.dart';

Map<String, String> mapFastApi422(Object error) {
  if (error is! DioException) return {};
  final r = error.response;
  if (r?.statusCode != 422) return {};
  final data = r!.data;
  if (data is! Map || data['detail'] is! List) return {};
  final issues = <String, String>{};
  for (final item in (data['detail'] as List)) {
    final loc = (item['loc'] as List?)?.map((e) => e.toString()).toList() ?? const [];
    final msg = (item['msg'] ?? '').toString();
    if (loc.length >= 2) {
      // e.g., ["body","qty"] → "qty"
      issues[loc.last] = msg;
    }
  }
  return issues;
}
