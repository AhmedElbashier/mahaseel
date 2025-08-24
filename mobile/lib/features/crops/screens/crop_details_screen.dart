// lib/features/crops/screens/crop_details_screen.dart
// NOTE: This file has been modified for Day 16 (Maps Integration).
// A Google Map preview is displayed on the crop details screen. Tapping
// the preview opens the native maps app at the crop location. We also
// request location permission to optionally show the user's current
// position on the map. If permission is denied, the map still works but
// does not display the user's location.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/services.dart';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../data/crop.dart';
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

  // Whether location permission has been granted. Used to enable myLocation on the map.
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
    _requestLocationPermission();
  }

  /// Requests location permission from the user. If permission is denied or
  /// permanently denied, [_locationGranted] will remain false. Otherwise it
  /// becomes true, enabling the 'my location' dot on the map.
  Future<void> _requestLocationPermission() async {
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
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

  /// Opens the native maps application at the provided coordinates. If no native
  /// maps app can be launched, falls back to a web URL. Shows a snackbar on
  /// failure.
  Future<void> _openNativeMap(LocationData loc) async {
    final lat = loc.lat;
    final lng = loc.lng;
    // geo: URI scheme attempts to open the default maps app on Android
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
    // Web fallback for iOS and other platforms
    final webUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
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
      // ignore errors and fall through to snackbar
    }
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل المحصول'),
        leading: BackButton(
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/crops'),
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
                errorBuilder: (_, _, _) =>
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
              // Begin map preview widget
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
                      // The google_maps_flutter plugin internally caches tiles.
                      // See: https://developers.google.com/maps/documentation/terms#section_10_4
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
