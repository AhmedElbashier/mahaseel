import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/rating_summary.dart';
import '../data/ratings_repo.dart';
import 'providers.dart';

// lib/features/ratings/state/ratings_controller.dart

class RatingsState {
  final bool loading;
  final RatingSummary? summary;
  final String? error;

  // NEW:
  final bool alreadyRated;   // lock UI when true
  final int? myStars;        // what the current user rated (if known)

  const RatingsState({
    this.loading = false,
    this.summary,
    this.error,
    this.alreadyRated = false, // NEW default
    this.myStars,              // NEW
  });

  RatingsState copyWith({
    bool? loading,
    RatingSummary? summary,
    String? error,
    bool? alreadyRated,  // NEW
    int? myStars,        // NEW (use nullable + a separate `clearMyStars` if needed)
  }) {
    return RatingsState(
      loading: loading ?? this.loading,
      summary: summary ?? this.summary,
      error: error,
      alreadyRated: alreadyRated ?? this.alreadyRated,
      myStars: myStars ?? this.myStars,
    );
  }
}


class RatingsController extends StateNotifier<RatingsState> {
  final Ref ref;
  RatingsController(this.ref) : super(const RatingsState());

  Future<void> loadSummary(int sellerId) async {
    state = state.copyWith(loading: true, error: '');
    try {
      final repo = ref.read(ratingsRepoProvider);
      final summary = await repo.getSellerSummary(sellerId);
      state = state.copyWith(summary: summary, error: '');
      debugPrint('✅ summary avg=${summary.avg} count=${summary.count}');
    } catch (e, st) {
      debugPrint('❌ loadSummary error: $e\n$st');
      state = state.copyWith(summary: null, error: _toArabicError(e), loading: false);
      return;
    }
    state = state.copyWith(loading: false);
  }


  Future<bool> rateSeller({required int sellerId, required int stars, int? cropId}) async {
    try {
      final repo = ref.read(ratingsRepoProvider);
      await repo.submitRating(sellerId: sellerId, stars: stars, cropId: cropId);

      // success path
      await loadSummary(sellerId);
      state = state.copyWith(
        alreadyRated: true,
        myStars: stars,
        error: 'شكراً على تقييمك!', // we reuse `error` slot as a notice banner
      );
      return true;

    } catch (e, st) {
      debugPrint('rateSeller failed: $e\n$st');

      final msg = e.toString();
      if (msg.contains('ALREADY_RATED')) {
        // treat as success but inform "already rated"
        await loadSummary(sellerId);
        state = state.copyWith(
          alreadyRated: true,
          myStars: stars, // best effort (you can omit if you prefer null)
          error: 'تم تسجيل تقييمك سابقاً لهذا البائع/المحصول.',
        );
        return true;
      }

      state = state.copyWith(error: _toArabicError(e));
      return false;
    }
  }

  String _toArabicError(Object e) {
    final msg = e.toString();
    if (msg.contains('ALREADY_RATED')) return 'تم تسجيل تقييمك سابقاً لهذا البائع/المحصول.';
    if (msg.contains('NOT_AUTHENTICATED')) return 'سجّل الدخول أولاً.';
    if (msg.contains('HTTP_400')) return 'الطلب غير صحيح (400).';
    if (msg.contains('HTTP_401')) return 'انتهت صلاحية الجلسة. سجّل الدخول مجدداً.';
    if (msg.contains('HTTP_403')) return 'غير مسموح لك بهذه العملية.';
    if (msg.contains('HTTP_404')) return 'غير موجود (404).';
    if (msg.contains('HTTP_422')) return 'قيمة التقييم غير صحيحة.';
    if (msg.contains('HTTP_500')) return 'خطأ في الخادم (500).';
    if (msg.contains('SUMMARY_HTTP_')) return 'تعذّر تحميل التقييم.';
    if (msg.contains('SUMMARY_PARSE_ERROR')) return 'تعذّر قراءة بيانات التقييم.';
    if (msg.contains('REQUEST_FAILED')) return 'تعذّر الوصول للخادم.';
    final clean = msg.replaceFirst('Exception: ', '');
    return clean.isNotEmpty ? clean : 'تعذّر إرسال التقييم.';
  }

}
