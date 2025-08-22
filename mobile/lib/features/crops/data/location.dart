// lib/features/crops/models/location.dart
class LocationData {
  final double lat;
  final double lng;
  final String? state;
  final String? locality;
  final String? address;

  const LocationData({
    required this.lat,
    required this.lng,
    this.state,
    this.locality,
    this.address,
  });

  Map<String, dynamic> toJson() => {
    'lat': lat,
    'lng': lng,
    'state': state,
    'locality': locality,
    'address': address,
  };

  static double _toDouble(dynamic v, [double fallback = 0.0]) {
    if (v is num) return v.toDouble();
    if (v is String) return double.tryParse(v) ?? fallback;
    return fallback;
  }

  factory LocationData.fromJson(Map<String, dynamic> j) => LocationData(
    lat: _toDouble(j['lat']),
    lng: _toDouble(j['lng']),
    state: j['state'] as String?,
    locality: j['locality'] as String?,
    address: j['address'] as String?,
  );
}
