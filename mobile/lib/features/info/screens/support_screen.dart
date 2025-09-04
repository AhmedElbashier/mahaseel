import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      {'q': 'كيف أنشئ إعلانًا؟', 'a': 'من القائمة الرئيسية اختر "إضافة محصول" واتبع الحقول.'},
      {'q': 'كيف أتواصل مع البائع؟', 'a': 'عبر زر الواتساب في صفحة المنتج.'},
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الدعم')),
        body: ListView(
          children: [
            for (final f in faqs)
              ExpansionTile(
                leading: const Icon(Icons.help_outline),
                title: Text(f['q']!),
                children: [Padding(padding: const EdgeInsets.all(12), child: Text(f['a']!))],
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.mail_outline),
              title: const Text('مراسلتنا عبر البريد'),
              subtitle: const Text('support@mahaseel.app'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open email */},
            ),
            ListTile(
              leading: const Icon(FontAwesomeIcons.whatsapp, color: Colors.green),
              title: const Text('الدعم عبر واتساب'),
              subtitle: const Text('+249 9xxxxxxx'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: open wa.me link */},
            ),
          ],
        ),
      ),
    );
  }
}
