import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/ratings_repo.dart';
import 'ratings_controller.dart';

final ratingsRepoProvider = Provider<RatingsRepo>((ref) => RatingsRepo());

final ratingsControllerProvider =
StateNotifierProvider<RatingsController, RatingsState>(
      (ref) => RatingsController(ref),
);
