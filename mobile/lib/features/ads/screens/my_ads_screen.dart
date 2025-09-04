import 'package:flutter/material.dart';

class MyAdsScreen extends StatelessWidget {
  const MyAdsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('إعلاناتي')),
        body: ListView(
          padding: const EdgeInsets.all(12),
          children: [
            _Tip('اعرض منتجاتك بشكل جذّاب مع صور واضحة وسعر مناسب.'),
            const SizedBox(height: 8),
            _Empty(
              title: 'لا توجد إعلانات بعد',
              subtitle: 'ابدأ بنشر أول محصول لك الآن',
              cta: 'إضافة إعلان',
              onTap: () {
                // TODO: go to add-crop screen
                // context.go('/add-crop');
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _Tip extends StatelessWidget {
  final String text;
  const _Tip(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.blue.shade50, borderRadius: BorderRadius.circular(12)),
      child: Row(children: [
        const Icon(Icons.info_outline, size: 18, color: Colors.blue),
        const SizedBox(width: 8),
        Expanded(child: Text(text)),
      ]),
    );
  }
}

class _Empty extends StatelessWidget {
  final String title, subtitle, cta;
  final VoidCallback onTap;
  const _Empty({required this.title, required this.subtitle, required this.cta, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 12),
      alignment: Alignment.center,
      child: Column(children: [
        const Icon(Icons.grid_view_outlined, size: 64, color: Colors.black26),
        const SizedBox(height: 12),
        Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.black54)),
        const SizedBox(height: 16),
        FilledButton(onPressed: onTap, child: Text(cta)),
      ]),
    );
  }
}
