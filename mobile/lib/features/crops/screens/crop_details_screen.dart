
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
import '../../ratings/state/providers.dart';
import '../models/crop.dart';
import '../data/location.dart';
import '../state/crops_controller.dart';

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
  final PageController _pageController = PageController();
  int _currentImageIndex = 0;

  @override
  void initState() {
    super.initState();
    _future = ref.read(cropsRepoProvider).getById(widget.id);
    _requestLocationPermission();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        final crop = await _future;
        if (!mounted) return;
        if (_loadedSummaryForSeller != crop.sellerId) {
          _loadedSummaryForSeller = crop.sellerId;
          unawaited(
            ref.read(ratingsControllerProvider.notifier).loadSummary(crop.sellerId),
          );
        }
      } catch (e) {
        // Handle error silently
      }
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
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
    final text = '''
🌾 محصول: ${c.name}
💰 السعر: ${c.price}/${c.unit}
📍 الموقع: ${c.location.state ?? ''} ${c.location.locality ?? ''}
👤 البائع: ${c.sellerName ?? 'غير محدد'}
${c.notes?.isNotEmpty == true ? '\n📝 ملاحظات: ${c.notes}' : ''}
    '''.trim();
    Share.share(text);
  }

  Future _openWhatsApp(Crop c) async {
    final raw = c.sellerPhone ?? '';
    final phone = raw.replaceAll(RegExp(r'[^\d]'), '');
    if (phone.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.error_outline, color: Colors.white),
              SizedBox(width: 8),
              Text('رقم البائع غير متوفر'),
            ],
          ),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
      return;
    }

    final text = Uri.encodeComponent('مرحبا ${c.sellerName ?? ''}، أنا مهتم بمحصول ${c.name}.');
    final deepLink = Uri.parse('whatsapp://send?phone=$phone&text=$text');
    final webLink = Uri.parse('https://wa.me/$phone?text=$text');

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
    final geoUri = Uri.parse('geo:$lat,$lng?q=$lat,$lng');
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('تعذّر فتح تطبيق الخرائط')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      body: FutureBuilder<Crop>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return _buildLoadingState();
          }
          if (snap.hasError || !snap.hasData) {
            return _buildErrorState(snap.error.toString());
          }

          final c = snap.data!;
          return _buildCropDetails(c, theme);
        },
      ),
    );
  }

  Widget _buildLoadingState() {
    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: Colors.grey.shade300,
          flexibleSpace: const FlexibleSpaceBar(
            background: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
        SliverFillRemaining(
          child: Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: List.generate(
                5,
                    (index) => Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorState(String error) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('خطأ'),
        backgroundColor: theme.colorScheme.error,
        foregroundColor: theme.colorScheme.onError,
      ),
      body: Center(
        child: Container(
          margin: const EdgeInsets.all(24),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: theme.shadowColor.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: theme.colorScheme.error,
              ),
              const SizedBox(height: 16),
              Text(
                'خطأ في التحميل',
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: theme.colorScheme.error,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: theme.textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.canPop() ? context.pop() : context.go('/crops'),
                icon: const Icon(Icons.arrow_back),
                label: const Text('العودة'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCropDetails(Crop c, ThemeData theme) {
    final ratingsState = ref.watch(ratingsControllerProvider);
    final List<String> gallery = c.images;
    final fallbackUrl = c.imageUrl;

    List<String> allImages = [];
    if (gallery.isNotEmpty) {
      allImages = gallery;
    } else if (fallbackUrl != null) {
      allImages = [fallbackUrl];
    }

    return CustomScrollView(
      slivers: [
        SliverAppBar(
          expandedHeight: 300,
          pinned: true,
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          flexibleSpace: FlexibleSpaceBar(
            background: _buildImageGallery(allImages, theme),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.share),
              onPressed: () => _share(c),
            ),
          ],
        ),
        SliverToBoxAdapter(
          child: Container(
            margin: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCropHeader(c, theme),
                const SizedBox(height: 24),
                _buildSellerCard(c, theme),
                const SizedBox(height: 24),
                _buildRatingSection(ratingsState, c, theme),
                const SizedBox(height: 24),
                _buildPurchaseSection(c, theme),
                const SizedBox(height: 24),
                _buildMapSection(c, theme),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildImageGallery(List<String> images, ThemeData theme) {
    if (images.isEmpty) {
      return Container(
        color: theme.colorScheme.surfaceVariant,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.image_not_supported,
                size: 64,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(height: 8),
              Text(
                'لا توجد صور',
                style: TextStyle(
                  color: theme.colorScheme.outline,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Stack(
      children: [
        PageView.builder(
          controller: _pageController,
          onPageChanged: (index) {
            setState(() {
              _currentImageIndex = index;
            });
          },
          itemCount: images.length,
          itemBuilder: (context, index) {
            return Image.network(
              images[index],
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  color: theme.colorScheme.surfaceVariant,
                  child: const Center(
                    child: CircularProgressIndicator(),
                  ),
                );
              },
              errorBuilder: (_, __, ___) => Container(
                color: theme.colorScheme.surfaceVariant,
                child: Icon(
                  Icons.broken_image,
                  size: 64,
                  color: theme.colorScheme.outline,
                ),
              ),
            );
          },
        ),
        if (images.length > 1) ...[
          Positioned(
            bottom: 16,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '${_currentImageIndex + 1} من ${images.length}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                images.length,
                    (index) => Container(
                  width: 8,
                  height: 8,
                  margin: const EdgeInsets.symmetric(horizontal: 2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: _currentImageIndex == index
                        ? Colors.white
                        : Colors.white.withOpacity(0.4),
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildCropHeader(Crop c, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primaryContainer,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        c.type,
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  children: [
                    Text(
                      '${c.price}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'جنيه/${c.unit}',
                      style: TextStyle(
                        color: theme.colorScheme.onPrimary.withOpacity(0.8),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.inventory,
                size: 16,
                color: theme.colorScheme.outline,
              ),
              const SizedBox(width: 8),
              Text(
                'الكمية المتاحة: ${c.qty} ${c.unit}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          if (c.notes != null && c.notes!.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.notes,
                        size: 16,
                        color: theme.colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'ملاحظات',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    c.notes!,
                    style: theme.textTheme.bodyMedium,
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSellerCard(Crop c, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'معلومات البائع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline,
                  color: theme.colorScheme.primary,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.sellerName ?? 'البائع',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (c.sellerPhone != null && c.sellerPhone!.isNotEmpty)
                      Text(
                        c.sellerPhone!,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              if (c.sellerPhone?.trim().isNotEmpty ?? false)
                FilledButton.icon(
                  onPressed: () => _openWhatsApp(c),
                  icon: const Icon(Icons.chat),
                  label: const Text('واتساب'),
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRatingSection(dynamic ratingsState, Crop c, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.star,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'تقييم البائع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (ratingsState.loading) const LinearProgressIndicator(),
          if (!ratingsState.loading && ratingsState.error?.isNotEmpty == true)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                ratingsState.error!,
                style: TextStyle(color: theme.colorScheme.error),
              ),
            ),
          const SizedBox(height: 16),
          _RatingSummaryRow(
            avg: ratingsState.summary?.avg ?? 0,
            count: ratingsState.summary?.count ?? 0,
          ),
          const SizedBox(height: 20),
          _RateSellerBar(
            initialStars: ref.watch(ratingsControllerProvider).myStars,
            disabled: ref.watch(ratingsControllerProvider).alreadyRated,
            onRated: (stars) async {
              final ok = await ref
                  .read(ratingsControllerProvider.notifier)
                  .rateSeller(sellerId: c.sellerId, stars: stars, cropId: c.id);

              if (!mounted) return;

              final notice = ref.read(ratingsControllerProvider).error;
              if (ok) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(notice?.isNotEmpty == true ? notice! : 'شكراً على تقييمك!'),
                      ],
                    ),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (notice != null && notice.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Row(
                      children: [
                        const Icon(Icons.error_outline, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(notice),
                      ],
                    ),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.white),
                        SizedBox(width: 8),
                        Text('تعذّر إرسال التقييم'),
                      ],
                    ),
                    backgroundColor: theme.colorScheme.error,
                  ),
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildPurchaseSection(Crop c, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.shopping_cart,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'طلب شراء',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () async {
                final qty = await showDialog<double?>(
                  context: context,
                  builder: (ctx) => _buildQuantityDialog(ctx, theme),
                );

                if (qty == null) return;

                try {
                  final repo = OrdersRepo();
                  final order = await repo.createOrder(c.id, qty);
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Row(
                        children: [
                          const Icon(Icons.check_circle, color: Colors.white),
                          const SizedBox(width: 8),
                          Text('تم إرسال طلب شراء #${order.id}'),
                        ],
                      ),
                      backgroundColor: Colors.green,
                    ),
                  );
                } catch (e) {
                  if (!mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.white),
                          SizedBox(width: 8),
                          Text('تعذّر إرسال الطلب'),
                        ],
                      ),
                      backgroundColor: theme.colorScheme.error,
                    ),
                  );
                }
              },
              icon: const Icon(Icons.shopping_cart),
              label: const Text('أرسل طلب شراء'),
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityDialog(BuildContext ctx, ThemeData theme) {
    final controller = TextEditingController(text: '1');

    return Directionality(
      textDirection: TextDirection.rtl,
      child: AlertDialog(
        title: const Text('أدخل الكمية المطلوبة'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: controller,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: 'مثال: 1.0',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.scale),
              ),
              textDirection: TextDirection.ltr,
              autofocus: true,
            ),
            const SizedBox(height: 8),
            Text(
              'الكمية المتاحة: ${ref.read(cropsControllerProvider).items.firstWhere((crop) => crop.id == widget.id).qty}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('إلغاء'),
          ),
          FilledButton(
            onPressed: () {
              final val = double.tryParse(controller.text.trim());
              Navigator.pop(ctx, val);
            },
            child: const Text('تأكيد'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  Widget _buildMapSection(Crop c, ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: theme.shadowColor.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.location_on,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'الموقع',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (c.location.state != null || c.location.locality != null) ...[
            Row(
              children: [
                Icon(
                  Icons.place,
                  size: 16,
                  color: theme.colorScheme.outline,
                ),
                const SizedBox(width: 8),
                Text(
                  '${c.location.state ?? ''} ${c.location.locality ?? ''}'.trim(),
                  style: theme.textTheme.bodyMedium,
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: SizedBox(
              height: 200,
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
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _openNativeMap(c.location),
              icon: const Icon(Icons.open_in_new),
              label: const Text('فتح في خرائط جوجل'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          if (!_locationGranted)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Text(
                'لم يتم منح إذن الموقع، لن يتم عرض موقعك على الخريطة',
                style: TextStyle(
                  fontSize: 12,
                  color: theme.colorScheme.error,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RatingSummaryRow extends StatelessWidget {
  final double avg;
  final int count;
  const _RatingSummaryRow({required this.avg, required this.count});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    if (count == 0) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              Icons.star_border,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(width: 8),
            Text(
              'لا يوجد تقييمات بعد',
              style: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          RatingBarIndicator(
            rating: avg,
            itemBuilder: (context, _) => Icon(
              Icons.star,
              color: theme.colorScheme.primary,
            ),
            itemSize: 24,
          ),
          const SizedBox(width: 12),
          Text(
            '${avg.toStringAsFixed(1)} من 5',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
          const Spacer(),
          Text(
            '($count تقييم)',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _RateSellerBar extends StatefulWidget {
  final void Function(int stars) onRated;
  final bool disabled;
  final int? initialStars;

  const _RateSellerBar({
    required this.onRated,
    this.disabled = false,
    this.initialStars,
  });

  @override
  State<_RateSellerBar> createState() => _RateSellerBarState();
}

class _RateSellerBarState extends State<_RateSellerBar> {
  double _current = 0;

  @override
  void initState() {
    super.initState();
    _current = widget.initialStars?.toDouble() ?? 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final disabled = widget.disabled;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'قيّم هذا البائع',
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 12),
        IgnorePointer(
          ignoring: disabled,
          child: Opacity(
            opacity: disabled ? 0.4 : 1,
            child: RatingBar.builder(
              initialRating: _current,
              minRating: 1,
              maxRating: 5,
              allowHalfRating: false,
              itemBuilder: (context, _) => Icon(
                Icons.star,
                color: theme.colorScheme.primary,
              ),
              itemSize: 32,
              onRatingUpdate: (val) => setState(() => _current = val),
              updateOnDrag: true,
              glowColor: theme.colorScheme.primary.withOpacity(0.2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: FilledButton.icon(
            onPressed: disabled || _current == 0
                ? null
                : () => widget.onRated(_current.toInt()),
            icon: const Icon(Icons.send),
            label: Text(disabled ? 'تم التقييم' : 'إرسال التقييم'),
            style: FilledButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
