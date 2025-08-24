class Order {
  final int id;
  final double qty;
  final String? note;
  final String status;
  final int cropId;
  final int? buyerId;

  Order({
    required this.id,
    required this.qty,
    this.note,
    required this.status,
    required this.cropId,
    this.buyerId,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      qty: (json['qty'] as num).toDouble(),
      note: json['note'],
      status: json['status'],
      cropId: json['crop_id'],
      buyerId: json['buyer_id'],
    );
  }
}
