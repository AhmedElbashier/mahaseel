import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';


import '../../../services/api_client.dart';
import '../../../services/retry_queue.dart';
import '../../../services/connectivity_service.dart';
import '../data/crops_repo.dart';
import '../models/crop.dart';

final dioProvider = Provider<Dio>((ref) => ApiClient().dio);

final retryQueueProvider = Provider<RetryQueue>((ref) => RetryQueue());

final cropsRepoProvider = Provider<CropsRepo>((ref) => CropsRepo(ref.read(dioProvider)));

final connectivityProvider = StreamProvider<List<ConnectivityResult>>((ref) {
  final service = ConnectivityService();
  final sub = service.onChanges.listen((results) async {
    final online = results.any((r) => r != ConnectivityResult.none);
    if (online) {
      await ref.read(retryQueueProvider).flush(ref.read(dioProvider));
      FirebaseCrashlytics.instance.log('Flushed pending_ops');
      ref.invalidate(cropsListProvider);
    }
  });
  ref.onDispose(() => sub.cancel());
  return service.onChanges;
});


class CropsListNotifier extends AsyncNotifier<Paginated<Crop>> {
  @override
  Future<Paginated<Crop>> build() => ref.read(cropsRepoProvider).fetch(page: 1);

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => ref.read(cropsRepoProvider).fetch(page: 1));
  }

  Future<void> loadNext(int currentPage) async {
    final next = currentPage + 1;
    final res = await ref.read(cropsRepoProvider).fetch(page: next);
    final prev = state.value;
    if (prev == null) {
      state = AsyncData(res);
      return;
    }
    state = AsyncData(
      Paginated<Crop>(
        [...prev.items, ...res.items],
        res.page,
        res.limit,
        res.total,
      ),
    );
  }
}

final cropsListProvider =
AsyncNotifierProvider<CropsListNotifier, Paginated<Crop>>(() => CropsListNotifier());
