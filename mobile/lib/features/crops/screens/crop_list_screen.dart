// lib/features/crops/ui/crop_list_screen.dart (your current file combined in the message)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/crops_controller.dart';
import '../../../widgets/crop_card.dart';
import '../../../widgets/crop_skeleton.dart';
import '../data/crops_repo.dart' show SortOption;
import '../data/crop_filters.dart';

// ⬇️ ADD: sort enum to match repo (if not globally available)
extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.newest:
        return 'الأحدث';
      case SortOption.priceAsc:
        return 'السعر ↑';
      case SortOption.priceDesc:
        return 'السعر ↓';
    }
  }
}

// ⬇️ ADD: simple filter holder (type/state/min/max/sort)
class _Filters {
  final String? type;
  final String? state;
  final double? minPrice;
  final double? maxPrice;
  final SortOption sort;
  const _Filters({
    this.type,
    this.state,
    this.minPrice,
    this.maxPrice,
    this.sort = SortOption.newest,
  });

  _Filters copyWith({
    String? type,
    String? state,
    double? minPrice,
    double? maxPrice,
    SortOption? sort,
  }) {
    return _Filters(
      type: type ?? this.type,
      state: state ?? this.state,
      minPrice: minPrice ?? this.minPrice,
      maxPrice: maxPrice ?? this.maxPrice,
      sort: sort ?? this.sort,
    );
  }
}

class _PriceRange {
  final String label;
  final double min;
  final double max;
  const _PriceRange(this.label, this.min, this.max);
}

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

  // ⬇️ ADD: keep current filters in memory (you can persist later)
  _Filters _filters = const _Filters();

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_maybeLoadMore);
    Future.microtask(() async {
      final saved = await CropFilters.load();
      setState(() {
        _filters = _Filters(
          type: saved.type,
          state: saved.state,
          minPrice: saved.minPrice,
          maxPrice: saved.maxPrice,
          sort: saved.sort,
        );
      });
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        state: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    });
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

  Future<void> _openFilters() async {
    final result = await showModalBottomSheet<_Filters>(
      context: context,
      isScrollControlled: true,
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null) {
      setState(() => _filters = result);
      // tell controller then refresh
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        state: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    }
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
        // title: const Text('المحاصيل'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            tooltip: 'الفرز والتصفية',
            onPressed: _openFilters,
          ),
          // IconButton(
          //   onPressed: () => context.push('/crops/add'),
          //   icon: const Icon(Icons.add),
          //   tooltip: 'إضافة محصول',
          // ),
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
                itemBuilder: (_, __) => const CropSkeleton(),
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

// ⬇️ Filter sheet widget (inline)
class _FilterSheet extends StatefulWidget {
  final _Filters initial;
  const _FilterSheet({required this.initial});

  @override
  State<_FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends State<_FilterSheet> {
  late String? _type = widget.initial.type;
  late String? _state = widget.initial.state;
  late double _min = widget.initial.minPrice ?? 0;
  late double _max = widget.initial.maxPrice ?? 1000;
  late SortOption _sort = widget.initial.sort;

  final _types = const ['grain', 'vegetable', 'fruit'];
  final _states = const ['Khartoum', 'Gezira', 'Sennar', 'Kassala'];
  final _priceRanges = const [
    _PriceRange('أي سعر', 0, 1000),
    _PriceRange('0 - 100', 0, 100),
    _PriceRange('100 - 500', 100, 500),
    _PriceRange('500 - 1000', 500, 1000),
    _PriceRange('أكثر من 1000', 1000, 10000),
  ];
  late int _priceIndex;

  @override
  void initState() {
    super.initState();
    _priceIndex =
        _priceRanges.indexWhere((r) => r.min == _min && r.max == _max);
    if (_priceIndex == -1) _priceIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(
          left: 16, right: 16, top: 16,
          bottom: mq.viewInsets.bottom + 16,
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('التصفية والفرز',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _type,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'النوع', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('أي نوع')),
                ..._types.map((t) => DropdownMenuItem(value: t, child: Text(t))),
              ],
              onChanged: (v) => setState(() => _type = v),
            ),
            const SizedBox(height: 12),

            DropdownButtonFormField<String>(
              value: _state,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'الولاية', border: OutlineInputBorder()),
              items: [
                const DropdownMenuItem(value: null, child: Text('أي ولاية')),
                ..._states.map((s) => DropdownMenuItem(value: s, child: Text(s))),
              ],
              onChanged: (v) => setState(() => _state = v),
            ),
            const SizedBox(height: 12),

            const Text('نطاق السعر'),
            Wrap(
              spacing: 8,
              children: List.generate(_priceRanges.length, (i) {
                final r = _priceRanges[i];
                return ChoiceChip(
                  label: Text(r.label),
                  selected: _priceIndex == i,
                  onSelected: (_) => setState(() {
                    _priceIndex = i;
                    _min = r.min;
                    _max = r.max;
                  }),
                );
              }),
            ),
            const SizedBox(height: 12),

            const Text('الفرز حسب'),
            ...SortOption.values.map((s) => RadioListTile<SortOption>(
              title: Text(s.label),
              value: s,
              groupValue: _sort,
              onChanged: (v) => setState(() => _sort = v!),
            )),

            const SizedBox(height: 12),
            Row(
              children: [
                OutlinedButton.icon(
                  icon: const Icon(Icons.refresh),
                  label: const Text('إعادة الضبط'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Theme.of(context).colorScheme.secondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _type = null;
                      _state = null;
                      _priceIndex = 0;
                      _min = _priceRanges[0].min;
                      _max = _priceRanges[0].max;
                      _sort = SortOption.newest;
                    });
                  },
                ),
                const Spacer(),
                FilledButton.icon(
                  icon: const Icon(Icons.check),
                  label: const Text('تطبيق'),
                  onPressed: () {
                    Navigator.of(context).pop(
                      _Filters(
                        type: _type,
                        state: _state,
                        minPrice: _min,
                        maxPrice: _max,
                        sort: _sort,
                      ),
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    ),);
  }
}
