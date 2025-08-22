import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/crop.dart';
import '../data/crops_repo.dart';

final cropsRepoProvider = Provider<CropsRepo>((ref) => CropsRepo());

class CropsState {
  final List<Crop> items;
  final bool loading;
  final bool loadingMore;
  final bool hasMore;
  final String? error;
  final int page;

  CropsState({
    required this.items,
    required this.loading,
    required this.loadingMore,
    required this.hasMore,
    required this.page,
    this.error,
  });

  factory CropsState.initial() => CropsState(
    items: const [],
    loading: true,
    loadingMore: false,
    hasMore: true,
    page: 1,
  );

  CropsState copyWith({
    List<Crop>? items,
    bool? loading,
    bool? loadingMore,
    bool? hasMore,
    int? page,
    String? error,
  }) =>
      CropsState(
        items: items ?? this.items,
        loading: loading ?? this.loading,
        loadingMore: loadingMore ?? this.loadingMore,
        hasMore: hasMore ?? this.hasMore,
        page: page ?? this.page,
        error: error,
      );
}

final cropsControllerProvider =
StateNotifierProvider<CropsController, CropsState>((ref) {
  return CropsController(ref);
});

class CropsController extends StateNotifier<CropsState> {
  CropsController(this.ref) : super(CropsState.initial()) {
    loadFirstPage();
  }

  final Ref ref;

  Future<void> loadFirstPage() async {
    state = CropsState.initial();
    try {
      final repo = ref.read(cropsRepoProvider);
      const page = 1;
      final result = await repo.fetch(page: page);
      state = state.copyWith(
        items: result.items,
        loading: false,
        hasMore: (result.page * result.limit) < result.total,
        page: page,
        error: null,
      );
    } catch (e) {
      state = state.copyWith(loading: false, error: e.toString());
    }
  }

  Future<void> refresh() => loadFirstPage();

  Future<void> loadNextPage() async {
    if (!state.hasMore || state.loadingMore) return;
    state = state.copyWith(loadingMore: true);
    try {
      final repo = ref.read(cropsRepoProvider);
      final next = state.page + 1;
      final result = await repo.fetch(page: next);
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
}
