// lib/features/crops/data/crops_repo.dart
import 'dart:io';
import 'package:dio/dio.dart';

import '../../../services/api_client.dart';
import './crop.dart';
import './location.dart';

class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  Paginated(this.items, this.page, this.limit, this.total);
}

class CropsRepo {
  final Dio _dio = ApiClient().dio;

  // --- Day 15: details screen needs this
  Future<Crop> getById(int id) async {
    final res = await _dio.get('/crops/$id');
    final crop = Crop.fromJson(res.data as Map<String, dynamic>);
    // DEBUG
    // ignore: avoid_print
    print('repo.getById -> sellerPhone=${crop.sellerPhone}, sellerName=${crop.sellerName}');
    return crop;
  }
  Future<Crop> createJson({
    required String name,
    required String type,
    required double qty,
    required double price,
    required String unit,
    required LocationData location,
    String? notes,
  }) async {
    final res = await _dio.post('/crops', data: {
      'name': name,
      'type': type,
      'qty': qty,
      'price': price,
      'unit': unit,
      'location': {
        'lat': location.lat,
        'lng': location.lng,
        'state': location.state,
        'locality': location.locality,
        'address': location.address,
      },
      'notes': notes,
    });
    return Crop.fromJson(res.data as Map<String, dynamic>);
  }
  Future<Crop> create({
    required String name,
    required String type,
    required double qty,
    required double price,
    required String unit,
    required LocationData location,
    String? notes,
    List<File> images = const [],
  }) async {
    // No image support on the API yet → send JSON
    if (images.isEmpty) {
      return createJson(
        name: name,
        type: type,
        qty: qty,
        price: price,
        unit: unit,
        location: location,
        notes: notes,
      );
    }

    // (When backend supports uploads, keep this block.)
    final form = FormData.fromMap({
      'name': name,
      'type': type,
      'qty': qty,
      'price': price,
      'unit': unit,
      'notes': notes,
      'location.lat': location.lat,
      'location.lng': location.lng,
      'location.state': location.state,
      'location.locality': location.locality,
      'location.address': location.address,
      'images': [
        for (final f in images)
          await MultipartFile.fromFile(
            f.path,
            filename: f.uri.pathSegments.isNotEmpty ? f.uri.pathSegments.last : 'image.jpg',
          ),
      ],
    });
    final res = await _dio.post('/crops', data: form);
    return Crop.fromJson(res.data as Map<String, dynamic>);
  }


  Future<Paginated<Crop>> fetch({required int page, int limit = 20}) async {
    final offset = (page - 1) * limit;
    final res = await _dio.get('/crops', queryParameters: {
      'limit': limit,
      'offset': offset,
    });

    final data = res.data;

    if (data is List) {
      final items = data
          .map((e) => Crop.fromJson(e as Map<String, dynamic>))
          .toList();

      final bool fullPage = items.length >= limit;
      final syntheticTotal =
          fullPage ? (page * limit + 1) : (page - 1) * limit + items.length;

      return Paginated<Crop>(items, page, limit, syntheticTotal);
    }

    if (data is Map<String, dynamic>) {
      final itemsJson = (data['items'] as List?) ?? const [];
      final items = itemsJson
          .map((e) => Crop.fromJson(e as Map<String, dynamic>))
          .toList();

      final int pageFromResponse = (data['page'] as num?)?.toInt() ??
          ((data['offset'] as num?) != null
              ? ((data['offset'] as num) ~/ ((data['limit'] as num?)?.toInt() ?? limit) + 1)
              : page);
      return Paginated<Crop>(
        items,
        pageFromResponse,
        (data['limit'] as num?)?.toInt() ?? limit,
        (data['total'] as num?)?.toInt() ?? items.length,
      );
    }

    throw StateError('Unexpected /crops response type: ${data.runtimeType}');
  }
}
