import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/favourites_controller.dart';

class FavouriteHeartButton extends ConsumerWidget {
  final int cropId;
  final EdgeInsets padding;
  final Color? bg;
  const FavouriteHeartButton({
    super.key,
    required this.cropId,
    this.padding = const EdgeInsets.all(8),
    this.bg,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(favouritesControllerProvider);
    // ✅ read directly from state
    final isFav = st.favoritedCropIdsDefault.contains(cropId);

    return Padding(
      padding: padding,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => ref
            .read(favouritesControllerProvider.notifier)
            .toggleHeart(context: context, cropId: cropId),
        child: Container(
          decoration: BoxDecoration(
            color: (bg ?? Colors.black.withOpacity(0.35)),
            shape: BoxShape.circle,
          ),
          padding: const EdgeInsets.all(6),
          child: Icon(
            isFav ? Icons.favorite : Icons.favorite_border,
            size: 20,
            color: isFav ? Colors.redAccent : Colors.white,
          ),
        ),
      ),
    );
  }
}
