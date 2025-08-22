import 'package:dio/dio.dart';
import '../../../../services/api_client.dart';
import 'crop.dart';

class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  Paginated(this.items, this.page, this.limit, this.total);
}

class CropsRepo {
  final _dio = ApiClient().dio;

  Future<Paginated<Crop>> fetch({required int page, int limit = 20}) async {
    final res = await _dio.get('/crops', queryParameters: {
      'page': page,
      'limit': limit,
    });
    final data = res.data as Map<String, dynamic>;
    final items = (data['items'] as List).map((e) => Crop.fromJson(e)).toList();
    return Paginated<Crop>(
      items,
      (data['page'] as num).toInt(),
      (data['limit'] as num).toInt(),
      (data['total'] as num).toInt(),
    );
  }
}
