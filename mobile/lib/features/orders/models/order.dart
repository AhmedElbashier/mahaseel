class Order {
  final int id;
  final String status;          // pending|confirmed|shipped|delivered|canceled
  final int? cropId;            // for simple intent-to-buy
  final double? qty;            // quantity buyer requested
  final String? note;
  final int? buyerId;

  // optional richer fields
  final String? code;
  final DateTime? createdAt;
  final double? total;
  final List<OrderItem>? items;

  const Order({
    required this.id,
    required this.status,
    this.cropId,
    this.qty,
    this.note,
    this.buyerId,
    this.code,
    this.createdAt,
    this.total,
    this.items,
  });

  factory Order.fromJson(Map<String, dynamic> j) {
    double? _toDouble(dynamic v) {
      if (v == null) return null;
      if (v is int) return v.toDouble();
      if (v is double) return v;
      return double.tryParse('$v');
    }

    return Order(
      id: j['id'] as int,
      status: (j['status'] ?? 'pending') as String,
      cropId: j['crop_id'] as int?,
      qty: _toDouble(j['qty']),
      note: j['note'] as String?,
      buyerId: j['buyer_id'] as int?,
      code: j['code'] as String?,
      createdAt: j['created_at'] != null ? DateTime.tryParse(j['created_at']) : null,
      total: _toDouble(j['total']),
      items: (j['items'] as List?)
          ?.map((e) => OrderItem.fromJson((e as Map).cast<String, dynamic>()))
          .toList(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status,
    if (cropId != null) 'crop_id': cropId,
    if (qty != null) 'qty': qty,
    if (note != null) 'note': note,
    if (buyerId != null) 'buyer_id': buyerId,
    if (code != null) 'code': code,
    if (createdAt != null) 'created_at': createdAt!.toIso8601String(),
    if (total != null) 'total': total,
    if (items != null) 'items': items!.map((e) => e.toJson()).toList(),
  };
}

class OrderItem {
  final int id;
  final String name;
  final String? imageUrl;
  final double price;
  final double qty;

  const OrderItem({
    required this.id,
    required this.name,
    this.imageUrl,
    required this.price,
    required this.qty,
  });

  factory OrderItem.fromJson(Map<String, dynamic> j) {
    double _toDouble(dynamic v) =>
        v is int ? v.toDouble() : (v is double ? v : double.tryParse('$v') ?? 0);

    return OrderItem(
      id: j['id'] as int,
      name: (j['name'] ?? '') as String,
      imageUrl: j['image_url'] as String?,
      price: _toDouble(j['price']),
      qty: _toDouble(j['qty']),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    if (imageUrl != null) 'image_url': imageUrl,
    'price': price,
    'qty': qty,
  };
}
