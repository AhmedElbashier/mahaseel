class Crop {
  final int id;
  final String name;
  final String? type;
  final double? price;
  final String? unit;
  final double? qty;
  final String? state;
  final String? locality;
  final String? address;
  final String? imageUrl;

  Crop({
    required this.id,
    required this.name,
    this.type,
    this.price,
    this.unit,
    this.qty,
    this.state,
    this.locality,
    this.address,
    this.imageUrl,
  });

  factory Crop.fromJson(Map<String, dynamic> j) => Crop(
    id: j['id'] as int,
    name: (j['name'] ?? '') as String,
    type: j['type'] as String?,
    price: (j['price'] is int) ? (j['price'] as int).toDouble() : j['price'] as double?,
    unit: j['unit'] as String?,
    qty: (j['qty'] is int) ? (j['qty'] as int).toDouble() : j['qty'] as double?,
    state: j['state'] as String?,
    locality: j['locality'] as String?,
    address: j['address'] as String?,
    imageUrl: j['image_url'] as String?,
  );
}
