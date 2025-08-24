import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../features/crops/models/crop.dart';

class CropCard extends StatelessWidget {
  const CropCard({super.key, required this.crop, this.onTap});
  final Crop crop;
  final VoidCallback? onTap;

  static const double _thumbW = 110;
  static const double _thumbH = 100;
  static const double _tileHeight = 120; // 100 image + 10 top + 10 bottom

  @override
  Widget build(BuildContext context) {
    // price text
    final priceText = '${crop.price.toStringAsFixed(0)} ${crop.unit}';

    // location line
    final locationParts = <String>[
      if ((crop.location.state ?? '').isNotEmpty) crop.location.state!,
      if ((crop.location.locality ?? '').isNotEmpty) crop.location.locality!,
    ];
    final locationText = locationParts.join('، ');

    // thumb url (prefer main image, fallback to first)
    final String? thumbUrl = crop.imageUrl ??
        (crop.images.isNotEmpty ? crop.images.first : null);

    final dpr = MediaQuery.of(context).devicePixelRatio;

    return SizedBox(
      height: _tileHeight,
      child: Card(
        clipBehavior: Clip.antiAlias,
        elevation: 0.5,
        margin: EdgeInsets.zero, // keep fixed height exact
        child: InkWell(
          onTap: onTap,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(
                width: _thumbW, height: _thumbH,
                child: thumbUrl == null
                    ? Container(color: Colors.grey.shade200)
                    : CachedNetworkImage(
                  imageUrl: thumbUrl,
                  fit: BoxFit.cover,
                  // request only what we render → smaller decode cost + memory
                  memCacheHeight: (_thumbH * dpr).round(),
                  fadeInDuration: const Duration(milliseconds: 120),
                  placeholder: (c, _) => const Center(
                    child: SizedBox(
                      width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                  errorWidget: (c, _, __) =>
                      Container(color: Colors.grey.shade200),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        crop.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'السعر: $priceText',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 4),
                      if (locationText.isNotEmpty)
                        Row(
                          children: [
                            const Icon(Icons.place, size: 16),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationText,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
      ),
    );
  }
}
