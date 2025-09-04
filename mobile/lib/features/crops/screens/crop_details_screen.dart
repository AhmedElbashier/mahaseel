// Simplified clean English Crop Details with brand-friendly actions
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../crops/state/providers.dart';

import '../../../widgets/brand_button.dart';
import '../models/crop.dart';
import '../data/location.dart';
import '../../auth/state/auth_controller.dart';
import 'package:mahaseel/features/chats/screens/chats_list_screen.dart' show chatRepoProvider;
import 'package:mahaseel/features/chats/screens/chats_thread_screen.dart';

class CropDetailsScreen extends ConsumerStatefulWidget {
  final int id;
  const CropDetailsScreen({super.key, required this.id});

  @override
  ConsumerState createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends ConsumerState<CropDetailsScreen> {
  // In a real app fetch from repo; here a placeholder future to keep structure
  late Future<Crop> _future;
  final PageController _page = PageController();
  int _index = 0;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
  }

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  void _share(Crop c) {
    final text = '''
Crop: ${c.name}
Price: ${c.price}/${c.unit}
Location: ${c.location.state ?? ''} ${c.location.locality ?? ''}
Seller: ${c.sellerName ?? 'Unknown'}
${c.notes?.isNotEmpty == true ? '\nNotes: ${c.notes}' : ''}
'''.trim();
    Share.share(text);
  }

  void _toast(String m) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(m)));

  String _digitsOnly(String? raw) => (raw ?? '').replaceAll(RegExp(r'[^0-9]'), '');

  Future<void> _callSeller(String? phone) async {
    final p = _digitsOnly(phone);
    if (p.isEmpty) {
      _toast('No phone number available');
      return;
    }
    final uri = Uri.parse('tel:$p');
    if (!await launchUrl(uri)) {
      _toast('Failed to start phone call');
    }
  }

  Future<void> _openWhatsApp(Crop c) async {
    final p = _digitsOnly(c.sellerPhone);
    if (p.isEmpty) {
      _toast('No phone number available');
      return;
    }
    final msg = Uri.encodeComponent('Hello ${c.sellerName ?? ''}, I am interested in ${c.name}.');
    final deep = Uri.parse('whatsapp://send?phone=$p&text=$msg');
    final web = Uri.parse('https://wa.me/$p?text=$msg');
    try {
      if (await canLaunchUrl(deep) && await launchUrl(deep, mode: LaunchMode.externalApplication)) return;
      if (await canLaunchUrl(web) && await launchUrl(web, mode: LaunchMode.externalApplication)) return;
      if (await launchUrl(web, mode: LaunchMode.inAppWebView)) return;
      await Clipboard.setData(ClipboardData(text: web.toString()));
      _toast('WhatsApp link copied to clipboard');
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: web.toString()));
      _toast('Couldn\'t open WhatsApp. Link copied to clipboard');
    }
  }

  Future<void> _openChat(Crop c) async {
    final me = ref.read(currentUserProvider);
    if (me == null) {
      _toast('Please log in to chat');
      return;
    }
    if (me.id.toString() == c.sellerId.toString()) {
      _toast('You cannot chat with your own listing');
      return;
    }
    try {
      final repo = ref.read(chatRepoProvider);
      final conv = await repo.createOrGetConversation(
        otherUserId: c.sellerId,
        listingId: c.id,
        role: 'buyer',
      );
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => ChatThreadScreen(conversationId: conv.id)),
      );
    } catch (e) {
      _toast('Failed to open chat');
    }
  }

  Future<void> _openNativeMap(LocationData loc) async {
    // Simplified fallback: copy coordinates to clipboard
    await Clipboard.setData(ClipboardData(text: 'https://maps.google.com/?q=${loc.lat},${loc.lng}'));
    if (!mounted) return;
    _toast('Map link copied to clipboard');
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(title: const Text('Crop Details')),
      body: FutureBuilder<Crop>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: Text('Loading crop…'));
          }
          final c = snap.data!;
          final images = c.images ?? <String>[];
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Gallery
              if (images.isNotEmpty)
                SizedBox(
                  height: 220,
                  child: PageView.builder(
                    controller: _page,
                    onPageChanged: (i) => setState(() => _index = i),
                    itemCount: images.length,
                    itemBuilder: (_, i) => ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.network(images[i], fit: BoxFit.cover),
                    ),
                  ),
                )
              else
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: cs.surfaceVariant,
                  ),
                  child: const Center(child: Icon(Icons.image, size: 48)),
                ),
              const SizedBox(height: 12),
              Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Text('${_index + 1}/${images.isEmpty ? 1 : images.length}')
              ]),

              const SizedBox(height: 16),
              Text(c.name, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.attach_money, size: 18),
                const SizedBox(width: 6),
                Text('${c.price} / ${c.unit}')
              ]),
              const SizedBox(height: 8),
              Row(children: [
                const Icon(Icons.place_outlined, size: 18),
                const SizedBox(width: 6),
                Text('${c.location.state ?? ''} ${c.location.locality ?? ''}')
              ]),
              if ((c.notes ?? '').isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(c.notes!, style: Theme.of(context).textTheme.bodyMedium)
              ],

              const SizedBox(height: 20),
              // Seller card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: cs.surface,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: cs.outline.withOpacity(.2)),
                ),
                child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                  CircleAvatar(
                    radius: 24,
                    child: Text((c.sellerName ?? 'U').trim().isNotEmpty ? (c.sellerName ?? 'U').trim()[0].toUpperCase() : 'U'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.sellerName ?? 'Unknown seller', style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(c.sellerPhone ?? 'No phone', style: TextStyle(color: cs.onSurfaceVariant)),
                    ]),
                  ),
                  IconButton(
                    tooltip: 'Call',
                    icon: const Icon(Icons.call),
                    onPressed: () => _callSeller(c.sellerPhone),
                  ),
                ]),
              ),

              const SizedBox(height: 12),
              Row(children: [
                Expanded(
                  child: PrimaryButton(
                    onPressed: () => _openChat(c),
                    icon: Icons.chat_bubble_outline,
                    label: 'Chat',
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlineButtonBrand(
                    onPressed: () => _openWhatsApp(c),
                    icon: Icons.whatsapp,
                    label: 'WhatsApp',
                    expanded: true,
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              Row(children: [
                Expanded(
                  child: OutlineButtonBrand(
                    onPressed: () => _share(c),
                    icon: Icons.ios_share,
                    label: 'Share',
                    expanded: true,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: PrimaryButton(
                    onPressed: () => _openNativeMap(c.location),
                    icon: Icons.map_outlined,
                    label: 'Open in Maps',
                    expanded: true,
                  ),
                ),
              ]),

              const SizedBox(height: 20),
              Text('Map preview', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 180,
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: LatLng(c.location.lat, c.location.lng), zoom: 14),
                    markers: {
                      Marker(markerId: MarkerId('crop_${c.id}'), position: LatLng(c.location.lat, c.location.lng))
                    },
                    zoomControlsEnabled: false,
                    tiltGesturesEnabled: false,
                    myLocationButtonEnabled: false,
                  ),
                ),
              ),
            ]),
          );
        },
      ),
    );
  }
}
