// lib/main.dart
import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'package:mahaseel/services/api_client.dart';
import 'core/theme/app_theme.dart';
import 'routing/app_router.dart';
import 'core/app_config.dart';
import 'core/debug/riverpod_observer.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> _initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('crops_cache');   // list cache
  await Hive.openBox('crop_details');  // details cache
  await Hive.openBox('pending_ops');   // retry queue
}

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await dotenv.load(fileName: ".env");
    await _initHive();
    ApiClient().init();

    debugPrint('BASE_URL = ${AppConfig.apiBaseUrl}');

    await Firebase.initializeApp();

    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      FirebaseCrashlytics.instance.recordFlutterError(details);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };

    // Riverpod root container (logs with SimpleLogger)
    final container = ProviderContainer(observers: [SimpleLogger()]);

    runApp(
      UncontrolledProviderScope(
        container: container,
        child: const MahaseelApp(),
      ),
    );
  }, (Object error, StackTrace stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MahaseelApp extends ConsumerWidget {
  const MahaseelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'محاصيل',
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      routerConfig: router,
    );
  }
}
