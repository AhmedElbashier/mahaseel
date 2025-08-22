// lib/features/crops/data/crops_repo.dart
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
  final Dio _dio = ApiClient().dio;

  Future<Paginated<Crop>> fetch({required int page, int limit = 20}) async {
    final res = await _dio.get('/crops', queryParameters: {
      'page': page,
      'limit': limit,
    });

    final data = res.data;

    // Case 1: server returns a plain array: [...]
    if (data is List) {
      final items = data
          .map((e) => Crop.fromJson(e as Map<String, dynamic>))
          .toList();

      // Synthesize "total" so your hasMore calc works:
      // if we got a full page, pretend there is at least one more item.
      final bool fullPage = items.length >= limit;
      final syntheticTotal = fullPage ? (page * limit + 1) : (page - 1) * limit + items.length;

      return Paginated<Crop>(items, page, limit, syntheticTotal);
    }

    // Case 2: server returns a paginated object: { items, total, page, limit }
    if (data is Map<String, dynamic>) {
      final itemsJson = (data['items'] as List?) ?? const [];
      final items = itemsJson
          .map((e) => Crop.fromJson(e as Map<String, dynamic>))
          .toList();

      return Paginated<Crop>(
        items,
        (data['page'] as num?)?.toInt() ?? page,
        (data['limit'] as num?)?.toInt() ?? limit,
        (data['total'] as num?)?.toInt() ?? items.length,
      );
    }

    throw StateError('Unexpected /crops response type: ${data.runtimeType}');
  }
}
