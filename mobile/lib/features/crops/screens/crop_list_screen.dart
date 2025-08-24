import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/crops_controller.dart';
import '../../../widgets/crop_card.dart';
import '../../../widgets/crop_skeleton.dart';

class CropListScreen extends ConsumerStatefulWidget {
  const CropListScreen({super.key});

  @override
  ConsumerState<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends ConsumerState<CropListScreen>
    with AutomaticKeepAliveClientMixin {
  final _controller = ScrollController();
  bool _isFetching = false;
  DateTime _lastFetch = DateTime.fromMillisecondsSinceEpoch(0);

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
  }

  void _maybeLoadMore() {
    final state = ref.read(cropsControllerProvider);
    if (_isFetching || state.loadingMore) return;

    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final now = DateTime.now();
      if (now.difference(_lastFetch).inMilliseconds < 200) return; // debounce
      _lastFetch = now;
      _isFetching = true;
      ref.read(cropsControllerProvider.notifier).loadNextPage().whenComplete(() {
        _isFetching = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context); // keep-alive

    final items       = ref.watch(cropsControllerProvider.select((s) => s.items));
    final loading     = ref.watch(cropsControllerProvider.select((s) => s.loading));
    final loadingMore = ref.watch(cropsControllerProvider.select((s) => s.loadingMore));
    final error       = ref.watch(cropsControllerProvider.select((s) => s.error));

    return Scaffold(
      appBar: AppBar(
        title: const Text('المحاصيل'),
        actions: [
          IconButton(
            onPressed: () => context.push('/crops/add'),
            icon: const Icon(Icons.add),
            tooltip: 'إضافة محصول',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cropsControllerProvider.notifier).refresh(),
          child: Builder(
          builder: (context) {
            if (loading && items.isEmpty) {
              return ListView.builder(
                key: const PageStorageKey('crops-list'),
                padding: const EdgeInsets.all(12),
                itemCount: 6,
                itemExtent: 120, // match CropCard fixed height
                itemBuilder: (_, __) => const CropSkeleton(), // make skeleton 120px tall
              );
            }

            if (error != null && items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  Center(
                    child: Text(
                      'حدث خطأ في جلب البيانات.\n$error',
                      textAlign: TextAlign.center,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: FilledButton(
                      onPressed: () =>
                          ref.read(cropsControllerProvider.notifier).refresh(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ),
                ],
              );
            }

            if (items.isEmpty) {
              return ListView(
                padding: const EdgeInsets.all(24),
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.inbox, size: 64),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد محاصيل حالياً')),
                ],
              );
            }

            return ListView.builder(
              key: const PageStorageKey('crops-list'),
              controller: _controller,
              padding: const EdgeInsets.all(12),
              itemCount: items.length + (loadingMore ? 1 : 0),
              itemExtent: 120,   // BIG perf win with fixed-height CropCard
              cacheExtent: 800,  // prefetch ~1–2 screens
              itemBuilder: (ctx, i) {
                if (i >= items.length) {
                  // footer loader (single return)
                  return const Center(child: CircularProgressIndicator());
                }
                final crop = items[i];
                return CropCard(
                  crop: crop,
                  onTap: () => context.push('/crops/${crop.id}'),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
