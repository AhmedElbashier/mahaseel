// lib/features/crops/data/crop.dart
import '../../../core/http/url.dart';
import '../data/location.dart';

class Crop {
  final int id;
  final String name;
  final String type;
  final double qty;
  final double price;
  final String unit;
  final LocationData location;
  final String? notes;

  final int sellerId;
  final String? sellerName;
  final String? sellerPhone;

  final String? imageUrl;
  final List<String> images;

  Crop({
    required this.id,
    required this.name,
    required this.type,
    required this.qty,
    required this.price,
    required this.unit,
    required this.location,
    required this.sellerId,
    this.notes,
    this.sellerName,
    this.sellerPhone,
    this.imageUrl,
    this.images = const [],
  });

  static double _toDouble(dynamic v, [double fb = 0.0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fb;
    return fb;
  }

  factory Crop.fromJson(Map<String, dynamic> j) {
    final loc = (j['location'] as Map<String, dynamic>?) ?? const {};
    String? main;
    final gallery = <String>[];
    final location = LocationData(
      lat: _toDouble(loc['lat'] ?? j['lat']),
      lng: _toDouble(loc['lng'] ?? j['lng']),
      state: (loc['state'] ?? j['state']) as String?,
      locality: (loc['locality'] ?? j['locality']) as String?,
      address: (loc['address'] ?? j['address']) as String?,
    );

    // shape A: image_url + images (array of strings)
    if (j['image_url'] != null && j['image_url'] is String) {
      main = ensureAbsoluteUrl(j['image_url'] as String);
    }
    if (j['images'] is List) {
      for (final e in (j['images'] as List)) {
        if (e is String) gallery.add(ensureAbsoluteUrl(e));
        else if (e is Map && e['url'] is String) gallery.add(ensureAbsoluteUrl(e['url']));
      }
    }

    // shape B: media: [{url, is_main}, ...]
    if (j['media'] is List) {
      final media = (j['media'] as List).whereType<Map>();
      // pick main first if exists
      final mainItem = media.firstWhere(
            (m) => (m['is_main'] == true),
        orElse: () => {},
      );
      if (main == null && mainItem.isNotEmpty && mainItem['url'] is String) {
        main = ensureAbsoluteUrl(mainItem['url']);
      }
      for (final m in media) {
        if (m['url'] is String) gallery.add(ensureAbsoluteUrl(m['url']));
      }
    }

    // fallback: if main is still null, use first gallery item
    main ??= (gallery.isNotEmpty ? gallery.first : null);

    return Crop(
      id: (j['id'] as num).toInt(),
      name: (j['name'] ?? '') as String,
      type: (j['type'] ?? '') as String,
      qty: _toDouble(j['qty']),
      price: _toDouble(j['price']),
      unit: (j['unit'] ?? '') as String,
      notes: j['notes'] as String?,
      sellerId: (j['seller_id'] as num).toInt(),
      sellerName: j['seller_name'] as String?,     // ← يقرأ snake_case
      sellerPhone: j['seller_phone'] as String?,   // ← يقرأ snake_case
      imageUrl: main,
      images: gallery,
      location: location,
    );
  }

  @override
  String toString() =>
      'Crop(id=$id, sellerName=$sellerName, sellerPhone=$sellerPhone)';
}
