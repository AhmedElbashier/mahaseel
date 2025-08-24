// lib/features/crops/screens/crop_details_screen.dart
// NOTE: Day 16 (Maps) + Day 26 (Ratings) integrated.
// - Google Map preview with tap-to-open native maps
// - WhatsApp deep link
// - Share
// - Ratings summary + submit (1–5 stars) with Riverpod controller

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../ratings/state/ratings_controller.dart';
import '../models/crop.dart';
import '../data/location.dart';
import '../providers.dart';

class CropDetailsScreen extends ConsumerStatefulWidget {
  final int id;

  const CropDetailsScreen({super.key, required this.id});

  @override
  ConsumerState createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends ConsumerState<CropDetailsScreen> {
  late Future<Crop> _future;
  int? _loadedSummaryForSeller;

  // Whether location permission has been granted. Used to enable myLocation on the map.
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
    _requestLocationPermission();
  }

  /// Requests location permission from the user.
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _locationGranted =
          permission == LocationPermission.always ||
              permission == LocationPermission.whileInUse;
    });
  }

  void _share(Crop c) {
    final text =
        'محصول: ${c.name}\nالسعر: ${c.price}/${c.unit}\nالموقع: ${c.location.state ?? ''} ${c.location.locality ?? ''}';
    Share.share(text);
  }

  Future _openWhatsApp(Crop c) async {
    final raw = c.sellerPhone ?? '';
    // اترك أرقام فقط
    final phone = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('رقم البائع غير متوفر')));
      return;
    }

    final text = Uri.encodeComponent(
      'مرحبا ${c.sellerName ?? ''}، أنا مهتم بمحصول ${c.name}.',
    );

    final deepLink = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webLink = Uri.parse('https://wa.me/$phone?text=$text');

    try {
      if (await canLaunchUrl(deepLink)) {
        final ok = await launchUrl(
          deepLink,
          mode: LaunchMode.externalApplication,
        );
        if (ok) return;
      }
      if (await canLaunchUrl(webLink)) {
        final ok = await launchUrl(
          webLink,
          mode: LaunchMode.externalApplication,
        );
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

  /// Opens the native maps application at the provided coordinates. Falls back to web URL.
  Future<void> _openNativeMap(LocationData loc) async {
    final lat = loc.lat;
    final lng = loc.lng;
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng'); // Android
    final webUri = Uri.parse('https://www.google.com/maps/search/?api=1&query=$lat,$lng');
    try {
      if (await canLaunchUrl(geoUri)) {
        await launchUrl(geoUri, mode: LaunchMode.externalApplication);
        return;
      }
      if (await canLaunchUrl(webUri)) {
        await launchUrl(webUri, mode: LaunchMode.externalApplication);
        return;
      }
    } catch (_) {
      // ignore, show snackbar below
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحصول'),
        leading: BackButton(
          onPressed: () => context.canPop() ? context.pop() : context.go('/crops'),
        ),
      ),
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

          // Load rating summary once per seller
          if (_loadedSummaryForSeller != c.sellerId) {
            _loadedSummaryForSeller = c.sellerId;
            ref.read(ratingsControllerProvider.notifier).loadSummary(c.sellerId);
          }
          final ratingsState = ref.watch(ratingsControllerProvider);

          final gallery = c.images;
          final hasGallery = gallery.isNotEmpty;
          final fallbackUrl = c.imageUrl;

          Widget galleryWidget;
          if (hasGallery) {
            galleryWidget = SizedBox(
              height: 220,
              child: PageView(
                children: [
                  for (final url in gallery)
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        url,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) =>
                            Container(color: Colors.grey.shade200),
                      ),
                    ),
                ],
              ),
            );
          } else if (fallbackUrl != null) {
            galleryWidget = ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fallbackUrl,
                height: 220,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) =>
                    Container(height: 160, color: Colors.grey.shade200),
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
              galleryWidget,
              const SizedBox(height: 16),
              Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${c.price} / ${c.unit}',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 6),
              Text('النوع: ${c.type} • الكمية: ${c.qty} ${c.unit}'),
              const SizedBox(height: 12),
              if (c.notes != null && c.notes!.isNotEmpty) Text(c.notes!),
              const SizedBox(height: 16),

              // Seller card
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

              // === Ratings ===
              const SizedBox(height: 8),
              if (ratingsState.loading) const LinearProgressIndicator(),
              const SizedBox(height: 8),
              _RatingSummaryRow(
                avg: ratingsState.summary?.avg ?? 0,
                count: ratingsState.summary?.count ?? 0,
              ),
              const SizedBox(height: 12),
              _RateSellerBar(
                onRated: (stars) async {
                  final ok = await ref
                      .read(ratingsControllerProvider.notifier)
                      .rateSeller(
                    sellerId: c.sellerId,
                    stars: stars,
                    cropId: c.id, // per-crop anti-abuse
                  );
                  if (!mounted) return;
                  if (ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('شكراً على تقييمك!')),
                    );
                  } else {
                    final err = ref.read(ratingsControllerProvider).error ?? 'حدث خطأ';
                    ScaffoldMessenger.of(context)
                        .showSnackBar(SnackBar(content: Text(err)));
                  }
                },
              ),

              // Map preview
              const SizedBox(height: 12),
              SizedBox(
                height: 200,
                child: GestureDetector(
                  onTap: () => _openNativeMap(c.location),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: GoogleMap(
                      initialCameraPosition: CameraPosition(
                        target: LatLng(c.location.lat, c.location.lng),
                        zoom: 14,
                      ),
                      markers: {
                        Marker(
                          markerId: MarkerId('crop_${c.id}'),
                          position: LatLng(c.location.lat, c.location.lng),
                          infoWindow: InfoWindow(title: c.name),
                          onTap: () => _openNativeMap(c.location),
                        ),
                      },
                      myLocationEnabled: _locationGranted,
                      liteModeEnabled: true,
                      myLocationButtonEnabled: false,
                      zoomControlsEnabled: false,
                      tiltGesturesEnabled: false,
                      onTap: (LatLng _) => _openNativeMap(c.location),
                    ),
                  ),
                ),
              ),
              if (!_locationGranted)
                const Padding(
                  padding: EdgeInsets.only(top: 8.0),
                  child: Text(
                    'لم يتم منح إذن الموقع، لن يتم عرض موقعك على الخريطة',
                    style: TextStyle(fontSize: 12, color: Colors.red),
                  ),
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

/// Simple inline summary row (average + count)
class _RatingSummaryRow extends StatelessWidget {
  final double avg;
  final int count;
  const _RatingSummaryRow({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        RatingBarIndicator(
          rating: avg,
          itemBuilder: (context, _) => const Icon(Icons.star),
          itemSize: 22,
        ),
        const SizedBox(width: 8),
        Text('${avg.toStringAsFixed(1)} / 5'),
        const SizedBox(width: 8),
        Text('($count تقييم)'),
      ],
    );
  }
}

/// Inline star input + submit button
class _RateSellerBar extends StatefulWidget {
  final void Function(int stars) onRated;
  final bool disabled;
  const _RateSellerBar({required this.onRated, this.disabled = false});

  @override
  State<_RateSellerBar> createState() => _RateSellerBarState();
}

class _RateSellerBarState extends State<_RateSellerBar> {
  double _current = 0;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قيّم البائع', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: widget.disabled,
          child: RatingBar.builder(
            initialRating: _current,
            minRating: 1,
            maxRating: 5,
            allowHalfRating: false,
            itemBuilder: (context, _) => const Icon(Icons.star),
            itemSize: 32,
            onRatingUpdate: (val) => setState(() => _current = val),
            updateOnDrag: true,
          ),
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: widget.disabled || _current == 0
              ? null
              : () => widget.onRated(_current.toInt()),
          icon: const Icon(Icons.send),
          label: const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}
