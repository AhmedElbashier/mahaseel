import 'package:flutter/material.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        ListTile(
          title: Text('اللغة'),
          subtitle: Text('العربية'),
        ),
        ListTile(
          title: Text('الوضع'),
          subtitle: Text('فاتح'),
        ),
      ],
    );
  }
}
