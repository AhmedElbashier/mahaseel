import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../../../services/api_client.dart';
import '../models/rating_summary.dart';

class RatingsRepo {
  final _dio = ApiClient().dio;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  /// GET /ratings/seller/{sellerId}
  Future<RatingSummary> getSellerSummary(int sellerId) async {
    final url = '/ratings/seller/$sellerId';
    print('🌐 GET ${_dio.options.baseUrl}$url');
    try {
      final res = await _dio.get(url);

      if (res.statusCode == 200) {
        final data = res.data;
        // tolerate Map<dynamic,dynamic> or String JSON
        if (data is Map) {
          return RatingSummary.fromJson(
              data.map((k, v) => MapEntry(k.toString(), v)));
        }
        if (data is String && data.isNotEmpty) {
          final decoded = jsonDecode(data);
          if (decoded is Map) {
            return RatingSummary.fromJson(
                Map<String, dynamic>.from(decoded));
          }
        }
        throw Exception('SUMMARY_PARSE_ERROR');
      }
      throw Exception('SUMMARY_HTTP_${res.statusCode}');
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      final body = e.response?.data;
      print('❌ GET ratings summary failed: $sc $body');
      if (body is Map && body['detail'] is String) {
        throw Exception(body['detail']);
      }
      throw Exception('SUMMARY_HTTP_$sc');
    }
  }


  /// POST /ratings  body: { seller_id, stars, crop_id? }  -> 201
  Future<void> submitRating({
    required int sellerId,
    required int stars, // 1..5
    int? cropId,
  }) async {
    // 1) read JWT
    final token = await _secure.read(key: 'jwt');
    if (token == null || token.isEmpty) {
      throw Exception('NOT_AUTHENTICATED'); // controller will translate
    }

    // 2) prepare request
    final body = <String, dynamic>{
      'seller_id': sellerId,
      'stars': stars,
      if (cropId != null) 'crop_id': cropId,
    };

    // 3) send
    try {
      final res = await _dio.post(
        '/ratings',
        data: body,
        options: Options(headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        }),
      );

      // backend returns 201 on success
      if (res.statusCode != 201 && res.statusCode != 200) {
        throw Exception('HTTP_${res.statusCode}');
      }
    } on DioException catch (e) {
      final sc = e.response?.statusCode;
      final data = e.response?.data;

      // Debug once to see the server body (optional)
      // debugPrint('[RAT][POST] err $sc body=$data');

      // If backend sends {"detail": "..."} bubble it up
      if (data is Map && data['detail'] is String) {
        final detail = (data['detail'] as String).toLowerCase();
        if (sc == 400 && detail.contains('already rated')) {
          throw Exception('ALREADY_RATED');
        }
        throw Exception(data['detail']);
      }

      if (sc == 400) throw Exception('ALREADY_RATED'); // safe default
      if (sc != null) throw Exception('HTTP_$sc');
      throw Exception('REQUEST_FAILED');
    }
  }
}
