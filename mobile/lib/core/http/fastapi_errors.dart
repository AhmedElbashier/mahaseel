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

/// Returns a user-friendly error message for common FastAPI envelopes and statuses.
String friendlyError(Object error) {
  if (error is! DioException) return 'حدث خطأ، حاول لاحقاً';
  final r = error.response;
  final code = r?.statusCode ?? 0;
  final data = r?.data;

  String? fromEnvelope(Map m) {
    final err = m['error'];
    if (err is Map && err['message'] is String) return err['message'] as String;
    if (m['detail'] is String) return m['detail'] as String;
    return null;
  }

  if (data is Map) {
    final msg = fromEnvelope(data);
    if (msg != null && msg.isNotEmpty) return msg;
  }

  switch (code) {
    case 400:
      return 'طلب غير صالح';
    case 401:
      return 'المصادقة مطلوبة';
    case 403:
      return 'غير مسموح لك بالوصول';
    case 404:
      return 'غير موجود';
    case 409:
      return 'تعارض في البيانات';
    case 429:
      return 'محاولات كثيرة، حاول لاحقاً';
    case 500:
      return 'خطأ داخلي، حاول لاحقاً';
    default:
      return 'خطأ غير متوقع (${code == 0 ? 'شبكة' : code})';
  }
}
