import 'package:flutter/material.dart';

class BlogListScreen extends StatelessWidget {
  const BlogListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final posts = <Map<String, String>>[
      // TODO: load from /cms/blogs
      // {'title':'عنوان المقال','excerpt':'ملخص قصير','date':'2025-08-01'}
    ];
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المدونة')),
        body: posts.isEmpty
            ? const Center(child: Text('لا توجد مقالات بعد'))
            : ListView.separated(
          padding: const EdgeInsets.all(12),
          itemCount: posts.length,
          separatorBuilder: (_, __) => const SizedBox(height: 8),
          itemBuilder: (_, i) {
            final p = posts[i];
            return Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                title: Text(p['title'] ?? ''),
                subtitle: Text(p['excerpt'] ?? ''),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {/* TODO: open blog details */},
              ),
            );
          },
        ),
      ),
    );
  }
}
