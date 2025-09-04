import 'package:flutter/material.dart';

class LawsTermsScreen extends StatelessWidget {
  const LawsTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const text = '''
مرحبا بك في محاصيل (Mahaseel).
باستخدامك للتطبيق فإنك توافق على الشروط التالية:

1) الاستخدام العادل
2) حقوق وواجبات البائع والمشتري
3) سياسة الخصوصية وحماية البيانات
4) سياسة المحتوى والوسائط

*هذه صفحة عامة — اربطها لاحقاً بصفحة CMS ديناميكية.*
''';
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('القوانين والشروط')),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(child: Text(text, style: const TextStyle(height: 1.6))),
        ),
      ),
    );
  }
}
