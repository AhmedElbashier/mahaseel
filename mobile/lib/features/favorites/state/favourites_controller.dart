// lib/features/favourite/state/favourites_controller.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/ui/toast.dart';
import '../data/favorites_repo.dart';
import 'favorite_providers.dart';

class FavoriteListVM {
  final int id;
  final String name;
  final bool isDefault;
  final int count;
  FavoriteListVM({required this.id, required this.name, required this.isDefault, required this.count});
}

class FavoriteItemVM {
  final int id;       // 0 => toggled off sentinel from API
  final int cropId;
  FavoriteItemVM({required this.id, required this.cropId});
}

class FavouritesState {
  final bool loading;
  final List<FavoriteListVM> lists;
  final Map<int, List<FavoriteItemVM>> itemsByList; // listId -> items
  final Set<int> favoritedCropIdsDefault; // for quick heart status on cards
  final int? selectedListId;
  final String? error;

  FavouritesState({
    required this.loading,
    required this.lists,
    required this.itemsByList,
    required this.favoritedCropIdsDefault,
    required this.selectedListId,
    required this.error,
  });

  FavouritesState copyWith({
    bool? loading,
    List<FavoriteListVM>? lists,
    Map<int, List<FavoriteItemVM>>? itemsByList,
    Set<int>? favoritedCropIdsDefault,
    int? selectedListId,
    String? error,
  }) {
    return FavouritesState(
      loading: loading ?? this.loading,
      lists: lists ?? this.lists,
      itemsByList: itemsByList ?? this.itemsByList,
      favoritedCropIdsDefault: favoritedCropIdsDefault ?? this.favoritedCropIdsDefault,
      selectedListId: selectedListId ?? this.selectedListId,
      error: error,
    );
  }

  factory FavouritesState.init() => FavouritesState(
    loading: false,
    lists: const [],
    itemsByList: {},
    favoritedCropIdsDefault: <int>{},
    selectedListId: null,
    error: null,
  );
}

class FavouritesController extends StateNotifier<FavouritesState> {
  final FavoritesRepo _repo;
  FavouritesController(this._repo) : super(FavouritesState.init());

  Future<void> bootstrap() async {
    state = state.copyWith(loading: true, error: null);
    try {
      final lists = await _repo.getLists();
      // summary for counts (optional)
      final summary = await _repo.summary().catchError((_) => <Map<String, dynamic>>[]);
      final summaryById = {for (final s in summary) s['list_id'] as int: s};

      final vmLists = lists.map((l) => FavoriteListVM(
        id: l.id,
        name: l.name,
        isDefault: l.isDefault,
        count: (summaryById[l.id]?['count'] as int?) ?? 0,
      )).toList();

      // prefetch default list items for heart status
      final defaultList = vmLists.firstWhere((x) => x.isDefault, orElse: () => vmLists.first);
      final defaultItems = await _repo.getItems(listId: defaultList.id);
      final favIds = defaultItems.map((e) => e.cropId).toSet();

      state = state.copyWith(
        loading: false,
        lists: vmLists,
        selectedListId: defaultList.id,
        itemsByList: {
          defaultList.id: defaultItems.map((e) => FavoriteItemVM(id: e.id, cropId: e.cropId)).toList()
        },
        favoritedCropIdsDefault: favIds,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> selectList(int listId) async {
    state = state.copyWith(selectedListId: listId);
    if (state.itemsByList[listId] != null) return;
    try {
      final rows = await _repo.getItems(listId: listId);
      final map = Map<int, List<FavoriteItemVM>>.from(state.itemsByList);
      map[listId] = rows.map((e) => FavoriteItemVM(id: e.id, cropId: e.cropId)).toList();
      state = state.copyWith(itemsByList: map);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  bool isFavoritedInDefault(int cropId) => state.favoritedCropIdsDefault.contains(cropId);

  Future<void> toggleHeart({
    required BuildContext context,
    required int cropId,
    int? listId, // null => default
  }) async {
    // optimistic update for default list hearts
    final usingDefault = listId == null;
    if (usingDefault) {
      final fav = state.favoritedCropIdsDefault.contains(cropId);
      final next = Set<int>.from(state.favoritedCropIdsDefault);
      if (fav) next.remove(cropId); else next.add(cropId);
      state = state.copyWith(favoritedCropIdsDefault: next);
    }

    try {
      final res = await _repo.toggle(cropId: cropId, listId: listId);
      final turnedOff = res.id == 0;
      if (listId != null) {
        // keep list items consistent if currently selected
        final items = List<FavoriteItemVM>.from(state.itemsByList[listId] ?? []);
        if (turnedOff) {
          items.removeWhere((x) => x.cropId == cropId);
        } else {
          items.insert(0, FavoriteItemVM(id: res.id, cropId: cropId));
        }
        final map = Map<int, List<FavoriteItemVM>>.from(state.itemsByList);
        map[listId] = items;
        state = state.copyWith(itemsByList: map);
      }

      // feedback like Dubizzle
      showToast(context, turnedOff ? 'Removed from favourites' : 'Saved to favourites');
    } catch (e) {
      // revert optimistic change if failed
      if (usingDefault) {
        final next = Set<int>.from(state.favoritedCropIdsDefault);
        if (next.contains(cropId)) next.remove(cropId); else next.add(cropId);
        state = state.copyWith(favoritedCropIdsDefault: next);
      }
      showToast(context, 'Couldn\'t update favourite. Try again.');
    }
  }

  Future<void> createList(BuildContext context, String name) async {
    final list = await _repo.createList(name);
    final newLists = List<FavoriteListVM>.from(state.lists)
      ..add(FavoriteListVM(id: list.id, name: list.name, isDefault: list.isDefault, count: 0));
    state = state.copyWith(lists: newLists);
    showToast(context, 'List created');
  }

  Future<void> renameList(BuildContext context, int listId, String name) async {
    final res = await _repo.renameList(listId, name);
    final newLists = state.lists.map((l) => l.id == listId
        ? FavoriteListVM(id: l.id, name: res.name, isDefault: l.isDefault, count: l.count)
        : l).toList();
    state = state.copyWith(lists: newLists);
    showToast(context, 'List renamed');
  }

  Future<void> deleteList(BuildContext context, int listId) async {
    await _repo.deleteList(listId);
    final newLists = state.lists.where((l) => l.id != listId).toList();
    final map = Map<int, List<FavoriteItemVM>>.from(state.itemsByList)..remove(listId);
    int? newSelected = state.selectedListId == listId
        ? (newLists.isNotEmpty ? newLists.first.id : null)
        : state.selectedListId;
    state = state.copyWith(lists: newLists, itemsByList: map, selectedListId: newSelected);
    showToast(context, 'List deleted');
  }
}

// providers
final favouritesControllerProvider =
StateNotifierProvider<FavouritesController, FavouritesState>((ref) {
  final repo = ref.watch(favoritesRepoProvider); // from your repo provider
  return FavouritesController(repo);
});
