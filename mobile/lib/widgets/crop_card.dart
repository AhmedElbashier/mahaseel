import 'package:flutter/material.dart';
import '../features/crops/data/crop.dart';

class CropCard extends StatelessWidget {
  const CropCard({super.key, required this.crop, this.onTap});
  final Crop crop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    // ignore: unnecessary_null_comparison
    final priceText = '${crop.price.toStringAsFixed(0)} ${crop.unit}';

    final locationText = [crop.location.state, crop.location.locality].where((e) => (e ?? '').isNotEmpty).join('، ');
    final String? thumbUrl = crop.imageUrl ??
        ((crop.images.isNotEmpty) ? crop.images.first : null);

    return Card(
      clipBehavior: Clip.antiAlias,
      elevation: 0.5,
      child: InkWell(
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              width: 110, height: 100,
              child: (thumbUrl == null)
                  ? Container(color: Colors.grey.shade200)
                  : Image.network(
                thumbUrl,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
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
                    Text(crop.name,
                        maxLines: 1, overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium),
                    const SizedBox(height: 6),
                    Text('السعر: $priceText',
                        style: Theme.of(context).textTheme.bodyMedium),
                    const SizedBox(height: 4),
                    if (locationText.isNotEmpty)
                      Row(
                        children: [
                          const Icon(Icons.place, size: 16),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(locationText,
                                maxLines: 1, overflow: TextOverflow.ellipsis),
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
    );
  }
}
