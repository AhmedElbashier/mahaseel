import 'package:flutter/material.dart';

class LanguagePickerScreen extends StatefulWidget {
  const LanguagePickerScreen({super.key});
  @override
  State<LanguagePickerScreen> createState() => _LanguagePickerScreenState();
}

class _LanguagePickerScreenState extends State<LanguagePickerScreen> {
  String selected = 'العربية'; // TODO: bind to provider
  final langs = const ['العربية', 'English'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختر اللغة')),
        body: ListView.separated(
          itemCount: langs.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final l = langs[i];
            return RadioListTile<String>(
              value: l, groupValue: selected,
              onChanged: (v) => setState(() => selected = v!),
              title: Text(l),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () {
              // TODO: ref.read(languageProvider.notifier).state = selected;
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ),
      ),
    );
  }
}
