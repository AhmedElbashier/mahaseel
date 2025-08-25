import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahaseel/features/ratings/state/providers.dart';
import 'package:mahaseel/features/ratings/data/ratings_repo.dart';
import 'package:mahaseel/features/ratings/models/rating_summary.dart';

class _FailingRatingsRepo implements RatingsRepo {
  @override
  Future<RatingSummary> getSellerSummary(int sellerId) async {
    throw Exception('SUMMARY_HTTP_500');
  }

  @override
  Future<void> submitRating({required int sellerId, required int stars, int? cropId}) async {}
}

class _TestWidget extends ConsumerStatefulWidget {
  const _TestWidget();

  @override
  ConsumerState<_TestWidget> createState() => _TestWidgetState();
}

class _TestWidgetState extends ConsumerState<_TestWidget> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(ratingsControllerProvider.notifier).loadSummary(1));
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(ratingsControllerProvider);
    return MaterialApp(
      home: Scaffold(
        body: state.error?.isNotEmpty == true ? Text(state.error!) : const SizedBox(),
      ),
    );
  }
}

void main() {
  testWidgets('displays error message when summary load fails', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          ratingsRepoProvider.overrideWithValue(_FailingRatingsRepo()),
        ],
        child: const _TestWidget(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('تعذّر تحميل التقييم.'), findsOneWidget);
  });
}
