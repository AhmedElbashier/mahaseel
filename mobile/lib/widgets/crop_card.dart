
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../features/crops/models/crop.dart';

/// A modern, responsive crop card with glassmorphism effects, improved animations,
/// and contemporary visual design following Material 3 principles.
class CropCard extends StatefulWidget {
  const CropCard({super.key, required this.crop, this.onTap});

  final Crop crop;
  final VoidCallback? onTap;

  @override
  State<CropCard> createState() => _CropCardState();
}

class _CropCardState extends State<CropCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
    _elevationAnimation = Tween<double>(
      begin: 2.0,
      end: 8.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeOutCubic,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _handleTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final crop = widget.crop;
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

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

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
            child: Material(
              elevation: _elevationAnimation.value,
              borderRadius: BorderRadius.circular(20),
              shadowColor: colorScheme.primary.withOpacity(0.2),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: GestureDetector(
                  onTapDown: _handleTapDown,
                  onTapUp: _handleTapUp,
                  onTapCancel: _handleTapCancel,
                  onTap: widget.onTap,
                  child: MouseRegion(
                    onEnter: (_) => setState(() => _isHovered = true),
                    onExit: (_) => setState(() => _isHovered = false),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: _isHovered
                              ? colorScheme.primary.withOpacity(0.3)
                              : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 10,
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Enhanced image with shimmer loading
                            Hero(
                              tag: 'crop-${crop.id}',
                              child: thumbUrl == null
                                  ? _buildPlaceholder(colorScheme)
                                  : CachedNetworkImage(
                                imageUrl: thumbUrl,
                                fit: BoxFit.cover,
                                memCacheWidth: (300 * dpr).round(),
                                memCacheHeight: (200 * dpr).round(),
                                fadeInDuration:
                                const Duration(milliseconds: 300),
                                placeholder: (c, _) =>
                                    _buildShimmerPlaceholder(),
                                errorWidget: (c, _, __) =>
                                    _buildPlaceholder(colorScheme),
                              ),
                            ),

                            // Modern gradient overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.1),
                                    Colors.black.withOpacity(0.7),
                                  ],
                                  stops: const [0.0, 0.6, 1.0],
                                ),
                              ),
                            ),

                            // Content overlay with glassmorphism
                            Positioned(
                              bottom: 0,
                              left: 0,
                              right: 0,
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      Colors.transparent,
                                      Colors.black.withOpacity(0.8),
                                    ],
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      crop.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: theme.textTheme.titleLarge?.copyWith(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        shadows: [
                                          Shadow(
                                            offset: const Offset(0, 1),
                                            blurRadius: 3,
                                            color: Colors.black.withOpacity(0.5),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (locationText.isNotEmpty) ...[
                                      const SizedBox(height: 4),
                                      Row(
                                        children: [
                                          Icon(
                                            Icons.location_on_rounded,
                                            size: 14,
                                            color: Colors.white.withOpacity(0.9),
                                          ),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              locationText,
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: Colors.white.withOpacity(0.9),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                            ),

                            // Modern price badge with glassmorphism
                            PositionedDirectional(
                              top: 12,
                              start: 12,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary.withOpacity(0.95),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black.withOpacity(0.2),
                                      blurRadius: 8,
                                      offset: const Offset(0, 2),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.payments_rounded,
                                      size: 16,
                                      color: colorScheme.onPrimary,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      priceText,
                                      style: TextStyle(
                                        color: colorScheme.onPrimary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                            // New badge with modern styling
                            if (crop.isNew)
                              PositionedDirectional(
                                top: 12,
                                end: 12,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      colors: [
                                        Colors.red.shade400,
                                        Colors.red.shade600,
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(16),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.red.withOpacity(0.3),
                                        blurRadius: 6,
                                        offset: const Offset(0, 2),
                                      ),
                                    ],
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.fiber_new_rounded,
                                        size: 14,
                                        color: Colors.white,
                                      ),
                                      const SizedBox(width: 2),
                                      Text(
                                        'جديد',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 11,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildPlaceholder(ColorScheme colorScheme) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            colorScheme.surfaceVariant,
            colorScheme.surfaceVariant.withOpacity(0.7),
          ],
        ),
      ),
      child: Center(
        child: Icon(
          Icons.image_rounded,
          size: 48,
          color: colorScheme.onSurfaceVariant.withOpacity(0.5),
        ),
      ),
    );
  }

  Widget _buildShimmerPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.grey.shade200,
            Colors.grey.shade100,
            Colors.grey.shade200,
          ],
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}
