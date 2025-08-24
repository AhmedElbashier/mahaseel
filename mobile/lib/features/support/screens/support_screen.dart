import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("الدعم الفني")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text("الأسئلة الشائعة", style: TextStyle(fontSize: 18)),
          ListTile(
            title: const Text("كيف أتواصل مع المزارع؟"),
            subtitle: const Text("اضغط زر الواتساب داخل صفحة المحصول."),
          ),
          ListTile(
            title: const Text("لماذا يختفي المحصول من القائمة؟"),
            subtitle: const Text("قد يكون انتهى أو أغلقه البائع."),
          ),
          const Divider(),
          const Text("تواصل معنا", style: TextStyle(fontSize: 18)),
          ListTile(
            leading: const Icon(Icons.email),
            title: const Text("البريد الإلكتروني"),
            onTap: () => launchUrl(Uri.parse("mailto:support@mahaseel.com")),
          ),
          ListTile(
            leading: const Icon(Icons.chat_sharp),
            title: const Text("واتساب"),
            onTap: () => launchUrl(Uri.parse("https://wa.me/249900000000")),
          ),
        ],
      ),
    );
  }
}
