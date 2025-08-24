import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../models/rating.dart';

class RatingSummaryRow extends StatelessWidget {
  final SellerRatingSummary? summary;
  const RatingSummaryRow({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    if (summary == null) {
      return const SizedBox.shrink();
    }
    return Row(
      mainAxisAlignment: MainAxisAlignment.start,
      children: [
        RatingBarIndicator(
          rating: summary!.avg,
          itemBuilder: (context, _) => const Icon(Icons.star),
          itemSize: 22,
        ),
        const SizedBox(width: 8),
        Text('${summary!.avg.toStringAsFixed(1)} / 5'),
        const SizedBox(width: 8),
        Text('(${summary!.count} تقييم)'),
      ],
    );
  }
}
