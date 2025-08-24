import 'package:dio/dio.dart';
import '../../../services/api_client.dart';
import '../models/rating.dart';

class RatingsRepo {
  final Dio _dio = ApiClient().dio;

  Future<SellerRatingSummary> fetchSellerSummary(int sellerId) async {
    final res = await _dio.get('/ratings/seller/$sellerId');
    return SellerRatingSummary.fromJson(res.data as Map<String, dynamic>);
  }

  Future<void> submitRating({
    required int sellerId,
    required RatingCreate rating,
  }) async {
    // backend expects POST /ratings with JSON and uses JWT to know buyer
    final payload = rating.toJson();
    payload['seller_id'] = sellerId; // if your backend reads seller from body
    await _dio.post('/ratings', data: payload);
  }
}
