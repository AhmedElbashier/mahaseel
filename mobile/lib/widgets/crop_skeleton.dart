
import 'package:flutter/material.dart';

/// Modern skeleton loader with shimmer animation effect
class CropSkeleton extends StatefulWidget {
  const CropSkeleton({super.key});

  @override
  State<CropSkeleton> createState() => _CropSkeletonState();
}

class _CropSkeletonState extends State<CropSkeleton>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutSine,
    ));
    _animationController.repeat();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Material(
            elevation: 2,
            borderRadius: BorderRadius.circular(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 16 / 10,
                child: Stack(
                  children: [
                    // Base skeleton
                    Container(
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceVariant.withOpacity(0.3),
                      ),
                    ),

                    // Shimmer effect
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(_animation.value * 200, 0),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.centerLeft,
                              end: Alignment.centerRight,
                              colors: [
                                Colors.transparent,
                                colorScheme.surface.withOpacity(0.8),
                                Colors.transparent,
                              ],
                              stops: const [0.0, 0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                    ),

                    // Content placeholders
                    Positioned(
                      bottom: 16,
                      left: 16,
                      right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            height: 20,
                            width: double.infinity * 0.7,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 14,
                            width: double.infinity * 0.5,
                            decoration: BoxDecoration(
                              color: colorScheme.onSurface.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(7),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Price badge placeholder
                    Positioned(
                      top: 12,
                      left: 12,
                      child: Container(
                        height: 32,
                        width: 80,
                        decoration: BoxDecoration(
                          color: colorScheme.onSurface.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Grid of skeleton loaders for initial loading state
class CropSkeletonGrid extends StatelessWidget {
  final int itemCount;

  const CropSkeletonGrid({
    super.key,
    this.itemCount = 6,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 16 / 10,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) => const CropSkeleton(),
    );
  }
}
