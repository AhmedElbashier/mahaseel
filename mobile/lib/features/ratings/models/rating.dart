class RatingCreate {
  final int stars;      // 1..5
  final int? cropId;    // optional

  RatingCreate({required this.stars, this.cropId});

  Map<String, dynamic> toJson() => {
    'stars': stars,
    if (cropId != null) 'crop_id': cropId,
  };
}

class SellerRatingSummary {
  final double avg;
  final int count;

  SellerRatingSummary({required this.avg, required this.count});

  factory SellerRatingSummary.fromJson(Map<String, dynamic> json) {
    return SellerRatingSummary(
      avg: (json['avg'] as num).toDouble(),
      count: (json['count'] as num).toInt(),
    );
  }
}
