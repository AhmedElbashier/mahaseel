import 'package:flutter/material.dart';

class AdvertisingScreen extends StatelessWidget {
  const AdvertisingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final items = const [
      {'title': 'إعلان مميز', 'desc': 'إبراز إعلانك أعلى النتائج لمدة 7 أيام.'},
      {'title': 'متجر موثّق', 'desc': 'شارة توثيق وواجهة مخصصة للبائعين.'},
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('الإعلانات')),
        body: ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: items.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            if (i == 0) {
              return _HeroCard(
                title: 'نمِّ ظهور منتجاتك',
                subtitle: 'باقات ترويج تناسب ميزانيتك',
              );
            }
            final it = items[i - 1];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(it['title']!),
                subtitle: Text(it['desc']!),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {/* TODO: advertising purchase flow */},
              ),
            );
          },
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String title, subtitle;
  const _HeroCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.green.shade400, Colors.green.shade200]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white)),
        const SizedBox(height: 6),
        Text(subtitle, style: const TextStyle(color: Colors.white)),
        const SizedBox(height: 10),
        FilledButton.tonal(onPressed: () {/* TODO */}, child: const Text('جرّب الآن')),
      ]),
    );
  }
}
