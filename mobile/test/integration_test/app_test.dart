import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahaseel/main.dart' show MahaseelApp;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    // Mock path_provider
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    pathChannel.setMockMethodCallHandler((MethodCall call) async {
      return Directory.systemTemp.path;
    });

    // Mock flutter_secure_storage
    const storageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    storageChannel.setMockMethodCallHandler((MethodCall call) async {
      switch (call.method) {
        case 'read': return null; // no token stored
        case 'write': return true;
        case 'delete': return true;
        case 'deleteAll': return true;
        default: return null;
      }
    });
  });

  tearDownAll(() {
    const pathChannel = MethodChannel('plugins.flutter.io/path_provider');
    pathChannel.setMockMethodCallHandler(null);

    const storageChannel = MethodChannel('plugins.it_nomads.com/flutter_secure_storage');
    storageChannel.setMockMethodCallHandler(null);
  });

  testWidgets('launches and shows home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MahaseelApp()));
    await tester.pumpAndSettle();

    expect(find.byType(MahaseelApp), findsOneWidget);
  });
}
