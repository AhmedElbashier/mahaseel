import 'package:flutter/material.dart';

class MySearchesScreen extends StatelessWidget {
  const MySearchesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final saved = <Map<String, String>>[]; // TODO: bind to state
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('عمليات بحثي')),
        body: saved.isEmpty
            ? _Empty()
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemBuilder: (_, i) {
            final it = saved[i];
            return ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              tileColor: Theme.of(context).colorScheme.surface,
              leading: const Icon(Icons.search),
              title: Text(it['name'] ?? 'بحث محفوظ'),
              subtitle: Text(it['summary'] ?? 'فلتر: الكل'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () {/* TODO: apply this search */},
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemCount: saved.length,
        ),
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: const [
          Icon(Icons.saved_search, size: 64, color: Colors.black26),
          SizedBox(height: 12),
          Text('لا توجد عمليات بحث محفوظة', style: TextStyle(fontWeight: FontWeight.w700)),
          SizedBox(height: 6),
          Text('قم بحفظ أي بحث من شاشة المنتجات للعودة إليه لاحقًا', textAlign: TextAlign.center, style: TextStyle(color: Colors.black54)),
        ]),
      ),
    );
  }
}
