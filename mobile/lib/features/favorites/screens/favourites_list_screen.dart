// lib/features/favourite/screens/favourites_list_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/favourites_controller.dart';
import 'package:go_router/go_router.dart';

class FavouritesListScreen extends ConsumerWidget {
  final int listId;
  const FavouritesListScreen({super.key, required this.listId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final st = ref.watch(favouritesControllerProvider);
    final items = st.itemsByList[listId];

    if (items == null) {
      return const Center(child: CircularProgressIndicator());
    }
    if (items.isEmpty) {
      return _EmptyState();
    }

    // grid like Dubizzle
    return GridView.builder(
      padding: const EdgeInsets.all(12),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.72, crossAxisSpacing: 12, mainAxisSpacing: 12),
      itemCount: items.length,
      itemBuilder: (_, i) {
        final fav = items[i];
        // Use your own way to get crop data (provider or repo)
        // final crop = ref.watch(cropByIdProvider(fav.cropId)).value;
        // return CropCard(crop: crop); // ensure card shows FavouriteHeartButton overlay
        return _CropCardPlaceholder(cropId: fav.cropId);
      },
    );
  }
}

class _EmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.favorite_border, size: 48),
            const SizedBox(height: 12),
            const Text('No favourites yet', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text('Tap the heart on any crop to save it here.',
              textAlign: TextAlign.center,
              style: TextStyle(color: Theme.of(context).textTheme.bodySmall?.color),
            ),
            const SizedBox(height: 16),
            FilledButton(
              onPressed: () => context.go('/home'), // or your real listing path e.g. '/browse' or '/'
              child: const Text('Browse crops'),
            ),
          ],
        ),
      ),
    );
  }
}

class _CropCardPlaceholder extends StatelessWidget {
  final int cropId;
  const _CropCardPlaceholder({required this.cropId});
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
      ),
      child: Center(child: Text('Crop #$cropId')),
    );
  }
}
