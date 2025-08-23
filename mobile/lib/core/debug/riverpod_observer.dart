// lib/core/debug/riverpod_observer.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SimpleLogger extends ProviderObserver {
  @override
  void providerDidFail(ProviderBase provider, Object error, StackTrace stackTrace, ProviderContainer container) {
    // ignore: avoid_print
    print('🔴 Provider error in ${provider.name ?? provider.runtimeType}: $error');
  }
}
