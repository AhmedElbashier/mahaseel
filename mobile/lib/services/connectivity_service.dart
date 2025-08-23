import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();

  // connectivity_plus now emits a List<ConnectivityResult>
  Stream<List<ConnectivityResult>> get onChanges =>
      _connectivity.onConnectivityChanged;

  Future<bool> get isOnline async {
    final res = await _connectivity.checkConnectivity(); // single result
    return res != ConnectivityResult.none;
  }
}
