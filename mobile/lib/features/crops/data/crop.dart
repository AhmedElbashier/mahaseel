// lib/features/crops/data/crop.dart
import 'location.dart';

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
  final String? sellerName;   // ← مهم
  final String? sellerPhone;  // ← مهم

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
    final location = LocationData(
      lat: _toDouble(loc['lat'] ?? j['lat']),
      lng: _toDouble(loc['lng'] ?? j['lng']),
      state: (loc['state'] ?? j['state']) as String?,
      locality: (loc['locality'] ?? j['locality']) as String?,
      address: (loc['address'] ?? j['address']) as String?,
    );

    final imgs = <String>[];
    final apiImages = j['images'];
    if (apiImages is List) imgs.addAll(apiImages.whereType<String>());
    final main = j['image_url'] as String?;
    if (main != null && main.isNotEmpty) imgs.insert(0, main);

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
      images: imgs,
      location: location,
    );
  }

  @override
  String toString() =>
      'Crop(id=$id, sellerName=$sellerName, sellerPhone=$sellerPhone)';
}
