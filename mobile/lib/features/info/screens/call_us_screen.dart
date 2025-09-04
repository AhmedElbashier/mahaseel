import 'package:flutter/material.dart';

class CallUsScreen extends StatelessWidget {
  const CallUsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final contacts = const [
      {'label': 'المبيعات', 'phone': '+971 5x xxx xxxx'},
      {'label': 'الدعم', 'phone': '+249 9x xxx xxxx'},
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اتصل بنا')),
        body: ListView.separated(
          itemCount: contacts.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final c = contacts[i];
            return ListTile(
              leading: const Icon(Icons.call_outlined),
              title: Text(c['label']!),
              subtitle: Text(c['phone']!),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: tel: link */},
            );
          },
        ),
      ),
    );
  }
}
