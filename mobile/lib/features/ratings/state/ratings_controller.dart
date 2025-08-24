import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ratings_repo.dart';
import '../models/rating.dart';

final ratingsRepoProvider = Provider<RatingsRepo>((ref) => RatingsRepo());

class RatingsState {
  final bool loading;
  final SellerRatingSummary? summary;
  final String? error;

  RatingsState({this.loading = false, this.summary, this.error});

  RatingsState copyWith({bool? loading, SellerRatingSummary? summary, String? error}) {
    return RatingsState(
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      error: error,
    );
  }
}

class RatingsController extends StateNotifier<RatingsState> {
  RatingsController(this.ref): super(RatingsState());
  final Ref ref;

  Future<void> loadSummary(int sellerId) async {
    state = state.copyWith(loading: true, error: null);
    try {
      final repo = ref.read(ratingsRepoProvider);
      final summary = await repo.fetchSellerSummary(sellerId);
      state = RatingsState(loading: false, summary: summary);
    } catch (e) {
      state = RatingsState(loading: false, error: 'تعذر تحميل التقييمات');
    }
  }

  Future<bool> rateSeller({
    required int sellerId,
    required int stars,
    int? cropId,
  }) async {
    try {
      final repo = ref.read(ratingsRepoProvider);
      await repo.submitRating(sellerId: sellerId, rating: RatingCreate(stars: stars, cropId: cropId));
      // refresh after submit
      await loadSummary(sellerId);
      return true;
    } catch (e) {
      // if duplicate, backend returns 400—show friendly message
      state = state.copyWith(error: 'لقد قمت بالتقييم مسبقًا لهذا البائع/المحصول');
      return false;
    }
  }
}

final ratingsControllerProvider =
StateNotifierProvider<RatingsController, RatingsState>((ref) {
  return RatingsController(ref);
});
