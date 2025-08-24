import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/settings_controller.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          title: const Text('اللغة'),
          trailing: DropdownButton<Locale>(
            value: locale,
            items: const [
              DropdownMenuItem(value: Locale('ar'), child: Text('العربية')),
              DropdownMenuItem(value: Locale('en'), child: Text('English')),
            ],
            onChanged: (loc) {
              if (loc != null) {
                ref.read(localeProvider.notifier).setLocale(loc);
              }
            },
          ),
        ),
        SwitchListTile(
          title: const Text('الوضع الداكن'),
          value: themeMode == ThemeMode.dark,
          onChanged: (val) {
            ref
                .read(themeModeProvider.notifier)
                .setTheme(val ? ThemeMode.dark : ThemeMode.light);
          },
        ),
      ],
    );
  }
}
