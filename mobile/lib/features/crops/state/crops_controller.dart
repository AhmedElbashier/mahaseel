import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/crop.dart';
import '../data/crops_repo.dart';
import '../data/crop_filters.dart';
import 'providers.dart';

// DI for repo
final cropsRepoProvider = Provider<CropsRepo>((ref) => CropsRepo(ref.read(dioProvider)));

/// Immutable UI state
class CropsState {
  final List<Crop> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final int page;
  final String? query;

  CropsState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.page,
    this.error,
    this.query,
  });

  factory CropsState.initial() => CropsState(
    items: const [],
    loading: true,
    loadingMore: false,
    hasMore: true,
    page: 1,
    query: null,
  );

  CropsState copyWith({
    List<Crop>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? error,
    String? query,
  }) =>
      CropsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error ?? this.error,
        query: query ?? this.query,
      );
}

// Provider
final cropsControllerProvider = StateNotifierProvider<CropsController, CropsState>((ref) {
  return CropsController(ref);
});

class CropsController extends StateNotifier<CropsState> {
  CropsController(this.ref) : super(CropsState.initial()) {
    _init();
  }

  final Ref ref;

  // active filter values
  String? _type;
  String? _state; // geographic state/region filter
  double? _minPrice;
  double? _maxPrice;
  SortOption _sort = SortOption.newest;

  static const _cacheBox = 'crops_cache';
  static const _cacheKey = 'items';

  Future<void> _init() async {
    final saved = await CropFilters.load();
    _type = saved.type;
    _state = saved.state;
    _minPrice = saved.minPrice;
    _maxPrice = saved.maxPrice;
    _sort = saved.sort;
    await loadFirstPage();
  }

  /// Apply filters + sort + query (any of them may be null)
  Future<void> applyFilters({
    String? type,
    String? stateFilter, // <-- renamed to avoid shadowing
    double? minPrice,
    double? maxPrice,
    SortOption? sort,
    String? query, // search text
  }) async {
    _type = type;
    _state = stateFilter;
    _minPrice = minPrice;
    _maxPrice = maxPrice;
    if (sort != null) _sort = sort;

    // keep query in notifier state (use this.state to be explicit)
    if (query != null) {
      final newQuery = query.trim();
      this.state = this.state.copyWith(query: newQuery.isEmpty ? null : newQuery);
    }

    // persist non-query filters (query is volatile, so we don’t persist it)
    await CropFilters.save(CropFilters(
      type: _type,
      state: _state,
      minPrice: _minPrice,
      maxPrice: _maxPrice,
      sort: _sort,
    ));

    await Hive.box(_cacheBox).clear();
    await loadFirstPage();
  }

  Future<void> loadFirstPage() async {
    // preserve current query when resetting
    final currentQuery = state.query;
    state = CropsState.initial().copyWith(query: currentQuery);

    final box = Hive.box(_cacheBox);
    final cached = box.get(_cacheKey);
    if (cached is List) {
      final items = cached
          .whereType<Map>()
          .map((e) => Crop.fromJson(Map<String, dynamic>.from(e)))
          .toList();
      state = state.copyWith(items: items, loading: false, page: 1, error: null);
    }

    try {
      final repo = ref.read(cropsRepoProvider);
      const page = 1;
      final result = await repo.fetch(
        page: page,
        limit: 20,
        type: _type,
        state: _state,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sort,
        query: state.query, // forward query to API
      );

      await box.put(_cacheKey, result.items.map((e) => e.toJson()).toList());

      state = state.copyWith(
        items: result.items,
        loading: false,
        hasMore: (state.query?.isNotEmpty ?? false)
            ? false
            : (result.page * result.limit) < result.total,
        page: page,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() async {
    await Hive.box(_cacheBox).clear();
    await loadFirstPage();
  }

  Future<void> loadNextPage() async {
    if ((state.query?.isNotEmpty ?? false)) return; // don't paginate while searching
    if (!state.hasMore || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final repo = ref.read(cropsRepoProvider);
      final next = state.page + 1;
      final result = await repo.fetch(
        page: next,
        limit: 20,
        type: _type,
        state: _state,
        minPrice: _minPrice,
        maxPrice: _maxPrice,
        sort: _sort,
        query: state.query,
      );
      state = state.copyWith(
        items: [...state.items, ...result.items],
        loadingMore: false,
        hasMore: (result.page * result.limit) < result.total,
        page: next,
      );
    } catch (e) {
      state = state.copyWith(loadingMore: false, error: e.toString());
    }
  }

  /// Search helper
  Future<void> search(String q) async {
    final cleaned = q.trim();
    await applyFilters(query: cleaned.isEmpty ? null : cleaned);
  }
}
