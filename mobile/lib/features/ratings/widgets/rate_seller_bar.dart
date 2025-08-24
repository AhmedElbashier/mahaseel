import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

// lib/features/ratings/widgets/rate_seller_bar.dart (or inside same file)

class _RateSellerBar extends StatefulWidget {
  final Future<void> Function(int stars) onRated;
  final bool disabled;
  final int? initialStars; // NEW: prefill user’s stars if known

  const _RateSellerBar({
    required this.onRated,
    this.disabled = false,
    this.initialStars,       // NEW
  });

  @override
  State<_RateSellerBar> createState() => _RateSellerBarState();
}

class _RateSellerBarState extends State<_RateSellerBar> {
  double _current = 0;
  bool _submitting = false;

  @override
  void initState() {
    super.initState();
    _current = (widget.initialStars ?? 0).toDouble();
  }

  @override
  void didUpdateWidget(covariant _RateSellerBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the controller later learns myStars, sync it in
    if (oldWidget.initialStars != widget.initialStars && widget.initialStars != null) {
      _current = widget.initialStars!.toDouble();
    }
  }

  @override
  Widget build(BuildContext context) {
    final locked = widget.disabled || _submitting;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قيّم البائع', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: locked,
          child: Opacity(
            opacity: locked ? 0.5 : 1.0,
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
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: (widget.disabled || _current == 0 || _submitting)
              ? null
              : () async {
            setState(() => _submitting = true);
            try {
              await widget.onRated(_current.toInt());
            } finally {
              if (mounted) setState(() => _submitting = false);
            }
          },
          icon: _submitting
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.send),
          label: Text(_submitting
              ? 'جارٍ الإرسال...'
              : (widget.disabled ? 'تم التقييم' : 'إرسال التقييم')),
        ),
        if (widget.disabled && _current > 0) ...[
          const SizedBox(height: 6),
          Text('تم تسجيل تقييمك: ${'★' * _current.toInt()}${'☆' * (5 - _current.toInt())}',
              style: const TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ],
    );
  }
}
