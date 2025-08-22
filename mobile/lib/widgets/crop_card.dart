import 'package:flutter/material.dart';
import '../../data/crop.dart';

class CropCard extends StatelessWidget {
  const CropCard({super.key, required this.crop, this.onTap});
  final Crop crop;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final priceText = (crop.price != null && crop.unit != null)
        ? '${crop.price!.toStringAsFixed(0)} ${crop.unit}'
        : (crop.price != null ? crop.price!.toStringAsFixed(0) : '—');

    final locationText = [crop.state, crop.locality].where((e) => (e ?? '').isNotEmpty).join('، ');

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
              child: crop.imageUrl == null
                  ? Container(color: Colors.grey.shade200)
                  : Image.network(crop.imageUrl!, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200)),
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
