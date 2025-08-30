import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../crops/state/providers.dart';
import '../data/favorites_repo.dart';
import '../models/favorite.dart';

// Repo
final favoritesRepoProvider = Provider<FavoritesRepo>((ref) {
  final dio = ref.watch(dioProvider);
  return FavoritesRepo(dio);
});

// Lists
final favoriteListsProvider = FutureProvider<List<FavoriteList>>((ref) async {
  final repo = ref.watch(favoritesRepoProvider);
  return repo.getLists();
});

// Items per list
final favoriteItemsProvider = FutureProvider.family<List<FavoriteItem>, int?>((ref, listId) async {
  final repo = ref.watch(favoritesRepoProvider);
  return repo.getItems(listId: listId);
});

// quick check if a crop is in (default) favorites
final isFavoritedProvider = FutureProvider.family<bool, int>((ref, cropId) async {
  final repo = ref.watch(favoritesRepoProvider);
  final items = await repo.getItems(); // default list
  return items.any((x) => x.cropId == cropId);
});
