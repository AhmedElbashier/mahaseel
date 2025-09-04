import 'package:flutter/material.dart';

class CityPickerScreen extends StatefulWidget {
  const CityPickerScreen({super.key});
  @override
  State<CityPickerScreen> createState() => _CityPickerScreenState();
}

class _CityPickerScreenState extends State<CityPickerScreen> {
  String selected = 'كل الإمارات'; // TODO: bind to provider
  final cities = const ['كل الإمارات', 'الخرطوم', 'مدني', 'عطبرة', 'كسلا', 'بورتسودان'];

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('اختر المدينة')),
        body: ListView.separated(
          itemCount: cities.length,
          separatorBuilder: (_, __) => const Divider(height: 0),
          itemBuilder: (_, i) {
            final c = cities[i];
            return RadioListTile<String>(
              value: c, groupValue: selected,
              onChanged: (v) => setState(() => selected = v!),
              title: Text(c),
            );
          },
        ),
        bottomNavigationBar: SafeArea(
          minimum: const EdgeInsets.all(12),
          child: FilledButton(
            onPressed: () {
              // TODO: ref.read(cityProvider.notifier).state = selected;
              Navigator.pop(context);
            },
            child: const Text('تأكيد'),
          ),
        ),
      ),
    );
  }
}
