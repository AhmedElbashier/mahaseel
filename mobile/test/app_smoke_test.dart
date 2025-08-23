// test/app_smoke_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahaseel/main.dart' show MahaseelApp;

void main() {
  testWidgets('app boots to home', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: MahaseelApp()));
    await tester.pumpAndSettle();
    expect(find.byType(MahaseelApp), findsOneWidget);
  });
}
