import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

final connectivityStreamProvider = StreamProvider<bool>((ref) async* {
  final connectivity = Connectivity();
  // Emit initial state
  final initial = await connectivity.checkConnectivity();
  yield initial != ConnectivityResult.none;
  // Listen for changes
  await for (final results in connectivity.onConnectivityChanged) {
    if (results is List<ConnectivityResult>) {
      yield !results.contains(ConnectivityResult.none);
    } else if (results is ConnectivityResult) {
      yield results != ConnectivityResult.none;
    }
  }
});

