// lib/features/crops/screens/crop_details_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import '../data/crop.dart';
import '../providers.dart';

class CropDetailsScreen extends ConsumerStatefulWidget {
  final int id;
  const CropDetailsScreen({super.key, required this.id});

  @override
  ConsumerState<CropDetailsScreen> createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends ConsumerState<CropDetailsScreen> {
  late Future<Crop> _future;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
  }

  void _share(Crop c) {
    final text = 'محصول: ${c.name}\nالسعر: ${c.price}/${c.unit}\nالموقع: ${c.location.state ?? ''} ${c.location.locality ?? ''}';
    Share.share(text);
  }

  Future<void> _openWhatsApp(Crop c) async {
    final raw = c.sellerPhone ?? '';
    // اترك أرقام فقط
    final phone = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رقم البائع غير متوفر')),
      );
      return;
    }

    final text = Uri.encodeComponent('مرحبا ${c.sellerName ?? ''}، أنا مهتم بمحصول ${c.name}.');

    final deepLink = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webLink  = Uri.parse('https://wa.me/$phone?text=$text');

    try {
      if (await canLaunchUrl(deepLink)) {
        final ok = await launchUrl(deepLink, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      if (await canLaunchUrl(webLink)) {
        final ok = await launchUrl(webLink, mode: LaunchMode.externalApplication);
        if (ok) return;
      }
      final ok = await launchUrl(webLink, mode: LaunchMode.inAppWebView);
      if (ok) return;

      await Clipboard.setData(ClipboardData(text: webLink.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تم نسخ رابط واتساب، الصقه في المتصفح')),
      );
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: webLink.toString()));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('تعذّر فتح واتساب – تم نسخ الرابط')),
      );
    }
  }





  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تفاصيل المحصول')),
      body: FutureBuilder<Crop>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError || !snap.hasData) {
            return Center(child: Text('خطأ في التحميل: ${snap.error}'));
          }
          final c = snap.data!;
          final gallery = c.images;
          final hasGallery = gallery.isNotEmpty;
          final fallbackUrl = c.mainImageUrl;
          Widget galleryWidget;
          if (hasGallery) {
            galleryWidget = SizedBox(
              height: 220,
              child: PageView(
                children: [
                  for (final url in gallery)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(url, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.grey.shade200),
                      ),
                    ),
                ],
              ),
            );
          } else if (fallbackUrl != null) {
            galleryWidget = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(fallbackUrl, height: 220, fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(height: 160, color: Colors.grey.shade200),
              ),
            );
          } else {
            galleryWidget = Container(
              height: 160,
              decoration: BoxDecoration(
                color: Colors.grey.shade200,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: const Text('لا توجد صور'),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              galleryWidget, // ← استخدمه هنا بدل التكرار
              const SizedBox(height: 16),
              Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text('${c.price} / ${c.unit}', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 6),
              Text('النوع: ${c.type} • الكمية: ${c.qty} ${c.unit}'),
              const SizedBox(height: 12),
              if (c.notes != null && c.notes!.isNotEmpty) Text(c.notes!),
              const SizedBox(height: 16),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const CircleAvatar(child: Icon(Icons.person)),
                title: Text(c.sellerName ?? 'البائع'),
                subtitle: Text(c.sellerPhone ?? '—'),
                trailing: (c.sellerPhone?.trim().isNotEmpty ?? false)
                    ? FilledButton.icon(
                  onPressed: () => _openWhatsApp(c),
                  icon: const Icon(Icons.chat),
                  label: const Text('واتساب'),
                )
                    : null,
              ),
              const SizedBox(height: 8),
              Container(
                height: 160,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                alignment: Alignment.center,
                child: const Text('معاينة الخريطة هنا (يوم 16)'),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () => _share(c),
                icon: const Icon(Icons.share),
                label: const Text('مشاركة'),
              ),
            ],
          );
        },
      ),
    );
  }
}
