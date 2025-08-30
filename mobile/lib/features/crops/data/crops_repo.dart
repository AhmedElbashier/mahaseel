// lib/features/crops/data/crops_repo.dart
import 'dart:io';
import 'package:dio/dio.dart';

import '../models/crop.dart';
import './location.dart';

enum SortOption { newest, priceAsc, priceDesc }

extension SortOptionX on SortOption {
  String get apiValue {
    switch (this) {
      case SortOption.newest:
        return 'newest';
      case SortOption.priceAsc:
        return 'price_asc';
      case SortOption.priceDesc:
        return 'price_desc';
    }
  }
}

class Paginated<T> {
  final List<T> items;
  final int page;
  final int limit;
  final int total;
  Paginated(this.items, this.page, this.limit, this.total);

  Paginated<T> copyWith({
    List<T>? items,
    int? page,
    int? limit,
    int? total,
  }) =>
      Paginated<T>(
        items ?? this.items,
        page ?? this.page,
        limit ?? this.limit,
        total ?? this.total,
      );
}

class CropsRepo {
  final Dio _dio;
  CropsRepo(this._dio);

  // --- Details
  Future<Crop> getById(int id) async {
    final res = await _dio.get('/crops/$id');
    return Crop.fromJson(res.data as Map<String, dynamic>);
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
    final res = await _dio.post(
      '/crops',
      data: {
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
      },
    );
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
            filename: f.uri.pathSegments.isNotEmpty
                ? f.uri.pathSegments.last
                : 'image.jpg',
          ),
      ],
    });
    final res = await _dio.post('/crops', data: form);
    return Crop.fromJson(res.data as Map<String, dynamic>);
  }

  Future<Paginated<Crop>> fetch({
    required int page,
    int limit = 20,
    String? type,
    String? state,
    double? minPrice,
    double? maxPrice,
    SortOption sort = SortOption.newest,
    String? query, // ✅ search (server via 'q', with client fallback)
  }) async {
    final queryParams = <String, dynamic>{
      'page': page,
      'limit': limit,
      if (type != null && type.isNotEmpty) 'type': type,
      if (state != null && state.isNotEmpty) 'state': state,
      if (minPrice != null) 'min_price': minPrice,
      if (maxPrice != null) 'max_price': maxPrice,
      'sort': sort.apiValue,
      if (query != null && query.isNotEmpty) 'q': query,
    };

    final res = await _dio.get('/crops', queryParameters: queryParams);
    final data = res.data;

    List<Crop> _parseList(List list) =>
        list.map((e) => Crop.fromJson(e as Map<String, dynamic>)).toList();

    // ---- Legacy: API returns a bare List
    if (data is List) {
      List<Crop> items = _parseList(data);

      // Client-side search fallback if needed
      if ((query ?? '').trim().isNotEmpty) {
        final q = _normalize(query!);
        items = items.where((c) {
          final name = _normalize(c.name);
          final typeStr = _normalize(c.type);
          final stateStr = _normalize(c.location.state ?? '');
          return name.contains(q) || typeStr.contains(q) || stateStr.contains(q);
        }).toList();
      }


      final bool fullPage = items.length >= limit;
      final int total = fullPage
          ? (page * limit + 1)
          : (page - 1) * limit + items.length;

      // All ints here ✅
      return Paginated<Crop>(items, page, limit, total);
    }

    // ---- Modern: API returns { items, page, limit, total }
    if (data is Map<String, dynamic>) {
      final itemsJson = (data['items'] as List?) ?? const [];
      List<Crop> items = _parseList(itemsJson);

      // Client-side search fallback if backend ignored 'q'
      if ((query ?? '').trim().isNotEmpty && !queryParams.containsKey('q')) {
        final q = _normalize(query!);
        items = items.where((c) {
          final name = _normalize(c.name);
          final typeStr = _normalize(c.type);
          final stateStr = _normalize(c.location.state ?? '');
          return name.contains(q) || typeStr.contains(q) || stateStr.contains(q);
        }).toList();
      }


      final int outPage = (data['page'] is num)
          ? (data['page'] as num).toInt()
          : page;
      final int outLimit = (data['limit'] is num)
          ? (data['limit'] as num).toInt()
          : limit;
      final int outTotal = (data['total'] is num)
          ? (data['total'] as num).toInt()
          : items.length;

      // All ints here ✅
      return Paginated<Crop>(items, outPage, outLimit, outTotal);
    }

    throw StateError('Unexpected /crops response type: ${data.runtimeType}');
  }

  /// Simple normalize (lowercase, strip Arabic diacritics, normalize letters)
  String _normalize(String s) {
    var out = s.toLowerCase();
    const diacritics = [
      '\u064B','\u064C','\u064D','\u064E','\u064F','\u0650','\u0651','\u0652'
    ];
    for (final d in diacritics) {
      out = out.replaceAll(d, '');
    }
    out = out
        .replaceAll('أ', 'ا')
        .replaceAll('إ', 'ا')
        .replaceAll('آ', 'ا')
        .replaceAll('ى', 'ي')
        .replaceAll('ؤ', 'و')
        .replaceAll('ئ', 'ي')
        .replaceAll('ة', 'ه');
    return out.trim();
  }
}
