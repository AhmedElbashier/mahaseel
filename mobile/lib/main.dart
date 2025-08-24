import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:mahaseel/services/api_client.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import 'core/app_config.dart';
import 'core/debug/riverpod_observer.dart';
import 'routing/app_router.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/settings/state/settings_controller.dart';

final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

Future<void> _initHive() async {
  final dir = await getApplicationDocumentsDirectory();
  await Hive.initFlutter(dir.path);
  await Hive.openBox('crops_cache');  // list cache
  await Hive.openBox('crop_details'); // details cache
  await Hive.openBox('pending_ops');  // retry queue
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await _initHive();
  ApiClient().init();
  debugPrint('BASE_URL = ${AppConfig.apiBaseUrl}');
  await Firebase.initializeApp();

  // Flutter errors → Crashlytics
  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;

  // Async errors outside Flutter
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };

  final container = ProviderContainer(observers: [SimpleLogger()]);
  final authControllerProvider =
  StateNotifierProvider<AuthController, AuthState>((ref) {
    return AuthController(ref);
  });

  runZonedGuarded(() {
    // 👇 Provide the same container to the whole app
    runApp(UncontrolledProviderScope(
      container: container,
      child: const MahaseelApp(),
    ));
  }, (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  });
}

class MahaseelApp extends ConsumerWidget {
  const MahaseelApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    const seed = Color(0xFF2E7D32);
    final lightScheme = ColorScheme.fromSeed(seedColor: seed);
    final darkScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      debugShowCheckedModeBanner: false,
      title: 'Mahaseel',
      themeMode: themeMode,
      darkTheme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Roboto',
        colorSchemeSeed: const Color(0xFF2E7D32),
        brightness: Brightness.dark,
      ),
      routerConfig: router,
      locale: locale,
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
    );
  }
}
