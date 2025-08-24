class RatingSummary {
  final double avg;
  final int count;
  const RatingSummary({required this.avg, required this.count});

  factory RatingSummary.fromJson(Map<String, dynamic> json) {
    return RatingSummary(
      avg: (json['avg'] as num?)?.toDouble() ?? 0.0,
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}
