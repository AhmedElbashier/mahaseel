// lib/services/logging_interceptor.dart
import 'dart:math';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show kReleaseMode, debugPrint;
// optional Crashlytics breadcrumbs
// import 'package:firebase_crashlytics/firebase_crashlytics.dart';

/// Attach an X-Request-ID if missing. Register this BEFORE PiiSafeLogInterceptor.
class RequestIdInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (!options.headers.containsKey('X-Request-ID')) {
      final rid = '${DateTime.now().microsecondsSinceEpoch}-${Random().nextInt(1 << 32)}';
      options.headers['X-Request-ID'] = rid;
    }
    handler.next(options);
  }
}

class PiiSafeLogInterceptor extends Interceptor {
  // Sample rate: e.g., log 100% in debug, 20% in profile, 0% in release.
  final double sampleRate;
  PiiSafeLogInterceptor({this.sampleRate = 1.0});

  // Keys that must be redacted (headers, query, body maps)
  static const _sensitiveKeys = {
    'authorization', 'cookie', 'set-cookie', 'x-api-key',
    'token', 'otp', 'password', 'phone',
  };

  // Store start time to compute duration
  static const _tsKey = '__start_ts_us__';

  bool _shouldLog() {
    if (kReleaseMode) return false; // never log in release
    // in debug/profile, allow sampling
    return Random().nextDouble() < sampleRate;
  }

  Map<String, dynamic> _redactMap(Map data) {
    final out = <String, dynamic>{};
    data.forEach((k, v) {
      final key = k.toString();
      final lower = key.toLowerCase();
      if (_sensitiveKeys.contains(lower)) {
        out[key] = '***';
      } else if (v is Map) {
        out[key] = _redactMap(v);
      } else if (v is List) {
        out[key] = v.map((e) => e is Map ? _redactMap(e) : e).toList();
      } else {
        out[key] = v;
      }
    });
    return out;
  }

  String _truncate(dynamic body, {int max = 300}) {
    final s = body?.toString() ?? '';
    if (s.length <= max) return s;
    return '${s.substring(0, max)}…(${s.length - max} more chars)';
  }

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler h) {
    if (!_shouldLog()) return h.next(options);

    // mark start time
    options.extra[_tsKey] = DateTime.now().microsecondsSinceEpoch;

    // mask path segments like /auth/*
    final maskedPath = options.path.replaceAll(RegExp(r'/auth/.*'), '/auth/**');

    // redact headers + query + (small) body
    final redactedHeaders = _redactMap(options.headers);
    final redactedQuery = _redactMap(options.queryParameters);
    final bodyPreview = options.data is Map
        ? _redactMap(options.data as Map)
        : _truncate(options.data);

    debugPrint('[REQ] ${options.method} $maskedPath '
        'qp=$redactedQuery '
        'hdr=$redactedHeaders '
        'body=$bodyPreview');

    h.next(options);
  }

  @override
  void onResponse(Response r, ResponseInterceptorHandler h) {
    if (_shouldLog()) {
      final startUs = (r.requestOptions.extra[_tsKey] as int?) ?? 0;
      final durMs = startUs == 0
          ? null
          : (DateTime.now().microsecondsSinceEpoch - startUs) / 1000.0;

      debugPrint('[RES] ${r.requestOptions.method} ${r.requestOptions.path} '
          '-> ${r.statusCode} '
          '${durMs != null ? '(${durMs.toStringAsFixed(1)} ms)' : ''}');
    }
    h.next(r);
  }

  @override
  void onError(DioException e, ErrorInterceptorHandler h) {
    if (_shouldLog()) {
      final startUs = (e.requestOptions.extra[_tsKey] as int?) ?? 0;
      final durMs = startUs == 0
          ? null
          : (DateTime.now().microsecondsSinceEpoch - startUs) / 1000.0;

      debugPrint('[ERR] ${e.requestOptions.method} ${e.requestOptions.path} '
          '-> ${e.response?.statusCode} ${e.type} '
          '${durMs != null ? '(${durMs.toStringAsFixed(1)} ms)' : ''}');

      // Optional Crashlytics breadcrumb (non-fatal)
      // FirebaseCrashlytics.instance.log(
      //   'net err ${e.requestOptions.method} ${e.requestOptions.path} '
      //   'status=${e.response?.statusCode} type=${e.type} '
      //   '${durMs != null ? 'dur=${durMs.toStringAsFixed(1)}ms' : ''}',
      // );
    }
    h.next(e);
  }
}
