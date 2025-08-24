// Details + Gallery + WhatsApp + Share + Ratings + Map (no inner Scaffold)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';

import '../../orders/data/orders_repo.dart';
import '../../ratings/state/ratings_controller.dart';
import '../../ratings/state/providers.dart';   // ratings providers (uses ApiClient().dio under the hood)
import '../models/crop.dart';
import '../data/location.dart';
import '../state/providers.dart';             // cropsRepoProvider

class CropDetailsScreen extends ConsumerStatefulWidget {
  final int id;
  const CropDetailsScreen({super.key, required this.id});

  @override
  ConsumerState createState() => _CropDetailsScreenState();
}

class _CropDetailsScreenState extends ConsumerState<CropDetailsScreen> {
  late Future<Crop> _future;
  int? _loadedSummaryForSeller;
  bool _locationGranted = false;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
    _requestLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // بعد أول فريم، حمّل ملخص تقييم البائع مرة واحدة (لنفس البائع)
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final crop = await _future;
        if (!mounted) return;
        if (_loadedSummaryForSeller != crop.sellerId) {
          _loadedSummaryForSeller = crop.sellerId;
          debugPrint('🔔 post-frame: loadSummary(${crop.sellerId})');
          unawaited(
            ref.read(ratingsControllerProvider.notifier).loadSummary(crop.sellerId),
          );
        }
      } catch (e) {
        // ignore: we’ll show the FutureBuilder error
      }
    });
  }

  Future<void> _requestLocationPermission() async {
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (!mounted) return;
    setState(() {
      _locationGranted = permission == LocationPermission.always ||
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
    final phone = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('رقم البائع غير متوفر')));
      return;
    }

    final text = Uri.encodeComponent('مرحبا ${c.sellerName ?? ''}، أنا مهتم بمحصول ${c.name}.');
    final deepLink = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webLink  = Uri.parse('https://wa.me/$phone?text=$text');

    try {
      if (await canLaunchUrl(deepLink) &&
          await launchUrl(deepLink, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (await canLaunchUrl(webLink) &&
          await launchUrl(webLink, mode: LaunchMode.externalApplication)) {
        return;
      }
      if (await launchUrl(webLink, mode: LaunchMode.inAppWebView)) return;

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

  Future<void> _openNativeMap(LocationData loc) async {
    final lat = loc.lat, lng = loc.lng;
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
    } catch (_) {}
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط')));
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Crop>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState != ConnectionState.done) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snap.hasError || !snap.hasData) {
          return Center(child: Text('خطأ في التحميل: ${snap.error}'));
        }

        final c = snap.data!;
        final ratingsState = ref.watch(ratingsControllerProvider);

        // ---------- Gallery ----------
        final List<String> gallery = c.images;
        final fallbackUrl = c.imageUrl;
        Widget galleryWidget;
        if (gallery.isNotEmpty) {
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
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text('لا توجد صور'),
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back),
                  onPressed: () => context.canPop() ? context.pop() : context.go('/crops'),
                ),
                const SizedBox(width: 8),
                Text('تفاصيل المحصول', style: Theme.of(context).textTheme.titleLarge),
              ],
            ),
            const SizedBox(height: 8),

            galleryWidget,
            const SizedBox(height: 16),

            Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text('${c.price} / ${c.unit}', style: Theme.of(context).textTheme.titleMedium),
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

            // ---------- Ratings ----------
            const SizedBox(height: 8),
            if (ratingsState.loading) const LinearProgressIndicator(),
            if (!ratingsState.loading && ratingsState.error?.isNotEmpty == true)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(ratingsState.error!, style: const TextStyle(color: Colors.red)),
              ),
            const SizedBox(height: 8),
            _RatingSummaryRow(
              avg: ratingsState.summary?.avg ?? 0,
              count: ratingsState.summary?.count ?? 0,
            ),
            const SizedBox(height: 12),

            _RateSellerBar(
              initialStars: ref.watch(ratingsControllerProvider).myStars,        // NEW
              disabled: ref.watch(ratingsControllerProvider).alreadyRated,       // NEW
              onRated: (stars) async {
                final ok = await ref
                    .read(ratingsControllerProvider.notifier)
                    .rateSeller(sellerId: c.sellerId, stars: stars, cropId: c.id);

                if (!mounted) return;

                final notice = ref.read(ratingsControllerProvider).error; // we used `error` as notice
                if (ok) {
                  // Show specific message depending on what controller set
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(notice?.isNotEmpty == true ? notice! : 'شكراً على تقييمك!')),
                  );
                } else if (notice != null && notice.isNotEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(notice)));
                } else {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('تعذّر إرسال التقييم')));
                }
              },
            ),


            const SizedBox(height: 8),

            // Intent to buy
            ElevatedButton.icon(
              onPressed: () async {
                final qty = await showDialog<double?>(
                  context: context,
                  builder: (ctx) {
                    final controller = TextEditingController(text: '1');
                    return AlertDialog(
                      title: const Text('أدخل الكمية'),
                      content: TextField(
                        controller: controller,
                        keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                        decoration: const InputDecoration(hintText: 'مثال: 1.0'),
                        textDirection: TextDirection.ltr,
                      ),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, null), child: const Text('إلغاء')),
                        FilledButton(
                          onPressed: () {
                            final val = double.tryParse(controller.text.trim());
                            Navigator.pop(ctx, val);
                          },
                          child: const Text('تأكيد'),
                        ),
                      ],
                    );
                  },
                );

                if (qty == null) return;

                try {
                  final repo = OrdersRepo();
                  final order = await repo.createOrder(c.id, qty);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text('تم إرسال طلب شراء #${order.id}')));
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context)
                      .showSnackBar(const SnackBar(content: Text('تعذّر إرسال الطلب')));
                }
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('أرسل طلب شراء'),
            ),

            const SizedBox(height: 12),

            // Map preview
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
    );
  }
}

class _RatingSummaryRow extends StatelessWidget {
  final double avg;
  final int count;
  const _RatingSummaryRow({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    if (count == 0) {
      return Row(
        children: const [
          Icon(Icons.star_border),
          SizedBox(width: 8),
          Text('لا يوجد تقييمات بعد'),
        ],
      );
    }

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

class _RateSellerBar extends StatefulWidget {
  final void Function(int stars) onRated;
  final bool disabled;
  const _RateSellerBar({required this.onRated, this.disabled = false, int? initialStars,});

  @override
  State<_RateSellerBar> createState() => _RateSellerBarState();
}

class _RateSellerBarState extends State<_RateSellerBar> {
  double _current = 0;

  @override
  Widget build(BuildContext context) {
    final disabled = widget.disabled;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('قيّم البائع', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
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
        ),
        const SizedBox(height: 8),
        ElevatedButton.icon(
          onPressed: disabled || _current == 0
              ? null
              : () => widget.onRated(_current.toInt()),
          icon: const Icon(Icons.send),
          label: const Text('إرسال التقييم'),
        ),
      ],
    );
  }
}
