import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class RateSellerBar extends StatefulWidget {
  final void Function(int stars) onRated;
  final bool disabled; // if you detect user already rated in UI state
  const RateSellerBar({super.key, required this.onRated, this.disabled = false});

  @override
  State<RateSellerBar> createState() => _RateSellerBarState();
}

class _RateSellerBarState extends State<RateSellerBar> {
  double _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قيّم البائع', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: widget.disabled,
          child: RatingBar.builder(
            initialRating: _current,
            minRating: 1,
            maxRating: 5,
            allowHalfRating: false,
            itemBuilder: (context, _) => const Icon(Icons.star),
            itemSize: 32,
            onRatingUpdate: (val) => setState(() => _current = val),
            updateOnDrag: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: widget.disabled || _current == 0 ? null : () {
            widget.onRated(_current.toInt());
          },
          icon: const Icon(Icons.send),
          label: const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}
