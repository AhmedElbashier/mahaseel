import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../features/crops/models/crop.dart';

/// A responsive crop card that shows the crop image with overlayed information
/// and small badges. It uses [LayoutBuilder] to adapt to the available width and
/// keeps a fixed aspect ratio for the image using [AspectRatio].
class CropCard extends StatefulWidget {
  const CropCard({super.key, required this.crop, this.onTap});

  final Crop crop;
  final VoidCallback? onTap;

  @override
  State<CropCard> createState() => _CropCardState();
}

class _CropCardState extends State<CropCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;

    // price text
    final priceText = '${crop.price.toStringAsFixed(0)} ${crop.unit}';

    // location line
    final locationParts = <String>[
      if ((crop.location.state ?? '').isNotEmpty) crop.location.state!,
      if ((crop.location.locality ?? '').isNotEmpty) crop.location.locality!,
    ];
    final locationText = locationParts.join('، ');

    // thumb url (prefer main image, fallback to first)
    final String? thumbUrl =
        crop.imageUrl ?? (crop.images.isNotEmpty ? crop.images.first : null);

    final dpr = MediaQuery.of(context).devicePixelRatio;

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final height = width / (16 / 9);

        return AnimatedScale(
          duration: const Duration(milliseconds: 150),
          scale: _pressed ? 0.98 : 1,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: widget.onTap,
                onHighlightChanged: (v) => setState(() => _pressed = v),
                child: AspectRatio(
                  aspectRatio: 16 / 9,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      // Image with hero animation for transitions
                      Hero(
                        tag: 'crop-${crop.id}',
                        child: thumbUrl == null
                            ? Container(color: Colors.grey.shade200)
                            : CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: (width * dpr).round(),
                                memCacheHeight: (height * dpr).round(),
                                fadeInDuration:
                                    const Duration(milliseconds: 200),
                                placeholder: (c, _) => const Center(
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2),
                                  ),
                                ),
                                errorWidget: (c, _, __) => Container(
                                    color: Colors.grey.shade200),
                              ),
                      ),

                      // Gradient overlay with text information
                      Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: const BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, Colors.black54],
                            ),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                crop.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(color: Colors.white),
                              ),
                              if (locationText.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  locationText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      color: Colors.white70, fontSize: 12),
                                ),
                              ],
                            ],
                          ),
                        ),
                      ),

                      // Price badge
                      PositionedDirectional(
                        top: 8,
                        start: 8,
                        child: _Badge(
                          color: Colors.green.shade700,
                          child: Text('السعر: $priceText'),
                        ),
                      ),

                      // Location badge
                      if (locationText.isNotEmpty)
                        PositionedDirectional(
                          top: 8,
                          end: 8,
                          child: _Badge(
                            color: Colors.black.withOpacity(0.6),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.place,
                                    size: 12, color: Colors.white),
                                const SizedBox(width: 2),
                                Text(locationText),
                              ],
                            ),
                          ),
                        ),

                      // New badge
                      if (crop.isNew)
                        PositionedDirectional(
                          bottom: 8,
                          start: 8,
                          child: const _Badge(
                            color: Colors.redAccent,
                            child: Text('جديد'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Simple badge used to display small pieces of information on top of the
/// image. Uses [Directionality] aware paddings for RTL support.
class _Badge extends StatelessWidget {
  const _Badge({required this.child, required this.color});

  final Widget child;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
      ),
      child: DefaultTextStyle(
        style: const TextStyle(color: Colors.white, fontSize: 12),
        child: child,
      ),
    );
  }
}

