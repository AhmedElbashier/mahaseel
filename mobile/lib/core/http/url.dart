// lib/core/http/url.dart
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

String ensureAbsoluteUrl(String? url) {
  if (url == null || url.isEmpty) return '';
  if (url.startsWith('http://') || url.startsWith('https://')) return url;
  // handle leading slash or not
  var base = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000';
  if (kReleaseMode && base.startsWith('http://')) {
    // Enforce HTTPS in release builds
    base = base.replaceFirst('http://', 'https://');
  }
  if (url.startsWith('/')) return '$base$url';
  return '$base/$url';
}
