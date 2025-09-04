
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../models/crop.dart';
import '../state/crops_controller.dart';
import '../../../widgets/crop_skeleton.dart';
import '../data/crops_repo.dart' show SortOption;
import '../data/crop_filters.dart';

import '../../favorites/state/favourites_controller.dart';
import '../../../widgets/brand_chip.dart';
import '../../../widgets/search_bar_small.dart';
import '../../../core/ui/toast.dart';
import '../../../l10n/app_localizations.dart';
import '../../../core/ui/empty_state.dart';
import '../../favorites/widgets/add_to_list_sheet.dart';
import '../../auth/state/auth_controller.dart'; // adjust path if different


extension SortOptionX on SortOption {
  String get label {
    switch (this) {
      case SortOption.newest:
        return 'الأحدث';
      case SortOption.priceAsc:
        return 'السعر (من الأقل للأعلى)';
      case SortOption.priceDesc:
        return 'السعر (من الأعلى للأقل)';
    }
  }

  IconData get icon {
    switch (this) {
      case SortOption.newest:
        return Icons.schedule;
      case SortOption.priceAsc:
        return Icons.trending_up;
      case SortOption.priceDesc:
        return Icons.trending_down;
    }
  }
}

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

  bool get hasActiveFilters =>
      type != null ||
          state != null ||
          minPrice != null ||
          maxPrice != null ||
          sort != SortOption.newest;

  int get activeFilterCount {
    int count = 0;
    if (type != null) count++;
    if (state != null) count++;
    if (minPrice != null || maxPrice != null) count++;
    if (sort != SortOption.newest) count++;
    return count;
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
  _Filters _filters = const _Filters();
  // final Set<dynamic> _favorites = {};
  //
  // void _toggleFav(dynamic id) {
  //   setState(() {
  //     if (_favorites.contains(id)) {
  //       _favorites.remove(id);
  //     } else {
  //       _favorites.add(id);
  //     }
  //   });
  // }
    @override
  bool get wantKeepAlive => true;
  Future<void> _openStatePicker() async {
    // TODO: Ideally fetch from API. For now, reuse your static list.
    const states = [
      {'value': null, 'label': 'جميع الولايات'},
      {'value': 'Khartoum', 'label': 'الخرطوم'},
      {'value': 'Gezira', 'label': 'الجزيرة'},
      {'value': 'Sennar', 'label': 'سنار'},
      {'value': 'Kassala', 'label': 'كسلا'},
    ];

    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SimpleListSheet<String?>(
        title: 'اختر الولاية',
        options: states.map((s) => _Option(label: s['label']!, value: s['value'])).toList(),
        selected: _filters.state,
      ),
    );

    if (chosen != null && chosen != _filters.state) {
      setState(() => _filters = _filters.copyWith(state: chosen));
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        stateFilter: chosen,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );

    }

  }

  Future<void> _openTypePicker() async {
    const types = [
      {'value': null, 'label': 'جميع الأنواع'},
      {'value': 'grain', 'label': 'حبوب'},
      {'value': 'vegetable', 'label': 'خضروات'},
      {'value': 'fruit', 'label': 'فواكه'},
    ];

    final chosen = await showModalBottomSheet<String?>(
      context: context,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _SimpleListSheet<String?>(
        title: 'اختر النوع',
        options: types.map((t) => _Option(label: t['label']!, value: t['value'])).toList(),
        selected: _filters.type,
      ),
    );

    if (chosen != null && chosen != _filters.type) {
      setState(() => _filters = _filters.copyWith(type: chosen));
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: chosen,
        stateFilter: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    }
  }

  Future<void> _openPriceSheet() async {
    final result = await showModalBottomSheet<_PriceRange?>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _PriceRangeSheet(
        initialMin: _filters.minPrice ?? 0,
        initialMax: _filters.maxPrice ?? 1000,
      ),
    );

    if (result != null &&
        (result.min != _filters.minPrice || result.max != _filters.maxPrice)) {
      setState(() => _filters = _filters.copyWith(minPrice: result.min, maxPrice: result.max));
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        stateFilter: _filters.state,
        minPrice: result.min,
        maxPrice: result.max,
        sort: _filters.sort,
      );
    }
  }

// Quick toggle: newest -> priceAsc -> priceDesc -> newest...
  Future<void> _quickSortToggle() async {
    // define the cycle order
    const order = [SortOption.newest, SortOption.priceAsc, SortOption.priceDesc];
    final currentIndex = order.indexOf(_filters.sort);
    final next = order[(currentIndex + 1) % order.length];

    setState(() => _filters = _filters.copyWith(sort: next));

    await ref.read(cropsControllerProvider.notifier).applyFilters(
      type: _filters.type,
      stateFilter: _filters.state,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      sort: next,
    );

    // (optional) toast
    if (!mounted) return;
    final msg = {
      SortOption.newest: 'تم الترتيب: الأحدث',
      SortOption.priceAsc: 'تم الترتيب: السعر من الأقل للأعلى',
      SortOption.priceDesc: 'تم الترتيب: السعر من الأعلى للأقل',
    }[next]!;
    // localized override
    final t = AppLocalizations.of(context);
    final msg2 = {
      SortOption.newest: 'Sorted: newest',
      SortOption.priceAsc: (t?.sortPriceAsc ?? 'Sorted: price low to high'),
      SortOption.priceDesc: (t?.sortPriceDesc ?? 'Sorted: price high to low'),
    }[next]!;
    showToast(context, msg2);
  }

  Future<void> _setSortNewest() async {
    if (_filters.sort == SortOption.newest) return;
    setState(() => _filters = _filters.copyWith(sort: SortOption.newest));
    await ref.read(cropsControllerProvider.notifier).applyFilters(
      type: _filters.type,
      stateFilter: _filters.state,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      sort: SortOption.newest,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم الترتيب: الأحدث')));
  }

// Toggle price only: Asc <-> Desc
  Future<void> _togglePriceSort() async {
    final next = (_filters.sort == SortOption.priceAsc)
        ? SortOption.priceDesc
        : SortOption.priceAsc;


    setState(() => _filters = _filters.copyWith(sort: next));
    await ref.read(cropsControllerProvider.notifier).applyFilters(
      type: _filters.type,
      stateFilter: _filters.state,
      minPrice: _filters.minPrice,
      maxPrice: _filters.maxPrice,
      sort: next,
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(next == SortOption.priceAsc
          ? 'تم الترتيب: السعر من الأقل للأعلى'
          : 'تم الترتيب: السعر من الأعلى للأقل'),
    ));
  }

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
      await ref.read(favouritesControllerProvider.notifier).bootstrap();
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        stateFilter: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    });
  }
  Future<void> _saveSearch() async {
    // TODO: persist current _filters to local storage or backend
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('تم حفظ البحث الحالي')));
  }
  Future<void> _openSortSheet() async {
    final theme = Theme.of(context);
    final chosen = await showModalBottomSheet<SortOption>(
      context: context,
      backgroundColor: theme.colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('الترتيب', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...SortOption.values.map((s) => RadioListTile<SortOption>(
                title: Row(children: [Icon(s.icon, size: 20), const SizedBox(width: 8), Text(s.label)]),
                value: s,
                groupValue: _filters.sort,
                onChanged: (v) => Navigator.of(context).pop(v),
                contentPadding: EdgeInsets.zero,
              )),
            ]),
          ),
        );
      },
    );

    if (chosen != null && chosen != _filters.sort) {
      setState(() => _filters = _filters.copyWith(sort: chosen));
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        stateFilter: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    }
  }

  void _maybeLoadMore() {
    final state = ref.read(cropsControllerProvider);
    if (_isFetching || state.loadingMore) return;

    final pos = _controller.position;
    if (pos.pixels >= pos.maxScrollExtent - 200) {
      final now = DateTime.now();
      if (now.difference(_lastFetch).inMilliseconds < 200) return;
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
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => _FilterSheet(initial: _filters),
    );
    if (result != null) {
      setState(() => _filters = result);
      await ref.read(cropsControllerProvider.notifier).applyFilters(
        type: _filters.type,
        stateFilter: _filters.state,
        minPrice: _filters.minPrice,
        maxPrice: _filters.maxPrice,
        sort: _filters.sort,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final items = ref.watch(cropsControllerProvider.select((s) => s.items));
    final loading = ref.watch(cropsControllerProvider.select((s) => s.loading));
    final loadingMore = ref.watch(cropsControllerProvider.select((s) => s.loadingMore));
    final error = ref.watch(cropsControllerProvider.select((s) => s.error));
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: theme.colorScheme.surfaceVariant.withOpacity(0.3),
      body: Stack(
        children: [
          // Pull-to-refresh applies to the WHOLE scroll view
          RefreshIndicator(
            onRefresh: () => ref.read(cropsControllerProvider.notifier).refresh(),
            child: CustomScrollView(
              controller: _controller,
              slivers: [
                SliverAppBar(
                  pinned: true,
                  floating: true,
                  snap: true,
                  toolbarHeight: 56,
                  collapsedHeight: 56,
                  expandedHeight: 56,
                  backgroundColor: theme.colorScheme.surface.withOpacity(0.98),
                  foregroundColor: theme.colorScheme.onSurface,
                  elevation: 1,
                  surfaceTintColor: theme.colorScheme.surfaceTint,
                  systemOverlayStyle: theme.brightness == Brightness.dark
                      ? SystemUiOverlayStyle.light
                      : SystemUiOverlayStyle.dark,
                  title: SearchBarSmall(
                    initialText: ref.watch(cropsControllerProvider).query ?? '',
                    onSubmitted: (q) => ref.read(cropsControllerProvider.notifier).search(q.trim()),
                    onTapFilters: _openFilters,
                  ),
                  actions: [
                    IconButton(
                      onPressed: () => context.push('/notifications'),
                      icon: const Icon(Icons.notifications_outlined),
                      tooltip: 'Notifications',
                    ),
                  ],
                  bottom: PreferredSize(
                    preferredSize: const Size.fromHeight(46),
                    child: _QuickChipsBar(
                      filters: _filters,
                      onClearAll: () async {
                        setState(() => _filters = const _Filters());
                        await ref.read(cropsControllerProvider.notifier)
                            .applyFilters(query: ''); // ← force clear search
                      },
                      onTapState: _openStatePicker,
                      onTapType: _openTypePicker,
                      onTapPrice: _openPriceSheet,
                      onTapSort: _quickSortToggle,
                    ),
                  ),
                ),


                if (_filters.hasActiveFilters)
                  SliverToBoxAdapter(child: _AppliedFiltersBanner(filters: _filters, onClearAll: () async {
                    setState(() => _filters = const _Filters());
                    await ref.read(cropsControllerProvider.notifier).applyFilters();
                  })),

                // list content
                ..._buildSliverContent(context, loading, items, error, loadingMore),
              ],
            ),
          ),

          _FloatingBar(
            onSort: _openSortSheet,
            onSaveSearch: _saveSearch,
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSliverContent(BuildContext context, bool loading, List items, String? error, bool loadingMore) {
    // final theme = Theme.of(context);

    if (loading && items.isEmpty) {
      return [
        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList.separated(
            itemBuilder: (_, __) => const CropSkeleton(),
            separatorBuilder: (_, __) => const SizedBox(height: 16),
            itemCount: 6,
          ),
        ),
      ];
    }

    if (error != null && items.isEmpty) {
      return [
        SliverToBoxAdapter(
          child: _ErrorCard(error: error, onRetry: () => ref.read(cropsControllerProvider.notifier).refresh()),
        ),
      ];
    }

    if (items.isEmpty) {
      return [
        const SliverToBoxAdapter(
          child: EmptyState(
            icon: Icons.agriculture_outlined,
            title: 'No results',
            message: 'Try adjusting filters or search terms',
          ),
        ),
      ];
    }

    return [
      SliverPadding(
        padding: const EdgeInsets.all(16),
        sliver: SliverList.separated(
          itemCount: items.length,
          itemBuilder: (ctx, i) {
            final crop = items[i];
            return _CropCardStyle(
              crop: crop,
              onTap: () => context.push('/crops/${crop.id}'),
            );
          },
          separatorBuilder: (_, __) => const SizedBox(height: 16),
        ),
      ),
      if (loadingMore)
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
    ];
  }
}

class _Badge extends StatelessWidget {
  final String text;
  const _Badge({required this.text});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
      decoration: BoxDecoration(
        color: theme.colorScheme.error,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(text, style: TextStyle(
          color: theme.colorScheme.onError, fontSize: 10, fontWeight: FontWeight.bold)),
    );
  }
}

class _QuickChipsBar extends StatelessWidget {
  final _Filters filters;
  final VoidCallback onClearAll;
  final VoidCallback onTapState;
  final VoidCallback onTapType;
  final VoidCallback onTapPrice;
  final VoidCallback onTapSort;

  const _QuickChipsBar({
    required this.filters,
    required this.onClearAll,
    required this.onTapState,
    required this.onTapType,
    required this.onTapPrice,
    required this.onTapSort,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface.withOpacity(.1),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          _ChipButton(icon: Icons.location_on, label: filters.state ?? 'كل الولايات', onTap: onTapState),
          const SizedBox(width: 8),
          _ChipButton(icon: Icons.category, label: filters.type ?? 'كل الأنواع', onTap: onTapType),
          const SizedBox(width: 8),
          _ChipButton(icon: Icons.monetization_on, label: _priceLabel(filters), onTap: onTapPrice),
          const SizedBox(width: 8),
          _ChipButton(icon: filters.sort.icon, label: filters.sort.label, onTap: onTapSort),
          if (filters.hasActiveFilters) ...[
            const SizedBox(width: 8),
            ActionChip(
              avatar: const Icon(Icons.clear, size: 18),
              label: const Text('مسح الكل'),
              onPressed: onClearAll,
            ),
          ],
        ]),
      ),
    );
  }

  static String _priceLabel(_Filters f) {
    if (f.minPrice == null && f.maxPrice == null) return 'أي سعر';
    final min = f.minPrice?.toInt() ?? 0;
    final max = f.maxPrice?.toInt();
    return max == null ? 'من $min+' : '$min - $max';
  }
}
class _ErrorCard extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorCard({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: theme.shadowColor.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline, size: 56, color: theme.colorScheme.error),
          const SizedBox(height: 12),
          Text('حدث خطأ في جلب البيانات', style: theme.textTheme.titleMedium?.copyWith(
              color: theme.colorScheme.error, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(error, textAlign: TextAlign.center),
          const SizedBox(height: 16),
          FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh), label: const Text('إعادة المحاولة')),
        ],
      ),
    );
  }
}

class _EmptyCard extends StatelessWidget {
  const _EmptyCard();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(24),
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(Icons.agriculture_outlined, size: 72, color: theme.colorScheme.outline),
          const SizedBox(height: 12),
          Text('لا توجد محاصيل', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text('لم يتم العثور على أي محاصيل تطابق معايير البحث', textAlign: TextAlign.center),
        ],
      ),
    );
  }
}

class _ChipButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipButton({required this.icon, required this.label, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return FilterPill(icon: icon, label: label, onTap: onTap);
  }
}

class _AppliedFiltersBanner extends StatelessWidget {
  final _Filters filters;
  final VoidCallback onClearAll;
  const _AppliedFiltersBanner({required this.filters, required this.onClearAll});
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.all(12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: theme.colorScheme.primaryContainer.withOpacity(.4),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(children: [
        Icon(Icons.filter_alt, color: theme.colorScheme.primary, size: 18),
        const SizedBox(width: 8),
        Expanded(child: Text('تم تطبيق ${filters.activeFilterCount} فلتر',
            style: TextStyle(color: theme.colorScheme.primary))),
        TextButton.icon(onPressed: onClearAll, icon: const Icon(Icons.clear), label: const Text('إزالة الكل')),
      ]),
    );
  }
}
class _SearchBarSmall extends StatefulWidget {
  final String? initialText;
  final ValueChanged<String> onSubmitted;
  final VoidCallback onTapFilters;
  const _SearchBarSmall({
    this.initialText,
    required this.onSubmitted,
    required this.onTapFilters,
  });

  @override
  State<_SearchBarSmall> createState() => _SearchBarSmallState();
}

class _SearchBarSmallState extends State<_SearchBarSmall> {
  late final TextEditingController _c = TextEditingController(text: widget.initialText ?? '');
  Timer? _deb;

  @override
  void dispose() {
    _deb?.cancel();
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 36,
            child: TextField(
              controller: _c,
              textInputAction: TextInputAction.search,
              onSubmitted: widget.onSubmitted,
              onChanged: (txt) {
                setState(() {}); // toggles clear icon
                _deb?.cancel();
                _deb = Timer(const Duration(milliseconds: 350), () {
                  widget.onSubmitted(txt.trim());
                });
              },
              decoration: InputDecoration(
                hintText: 'ابحث عن المحاصيل…', // (optional) Arabic hint
                prefixIcon: const Icon(Icons.search, size: 18),
                suffixIcon: (_c.text.isNotEmpty)
                    ? IconButton(
                  icon: const Icon(Icons.clear, size: 18),
                  onPressed: () {
                    _deb?.cancel();
                    _c.clear();
                    widget.onSubmitted(''); // clears search
                    setState(() {});
                  },
                )
                    : null,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          tooltip: 'Filters',
          icon: const Icon(Icons.tune_rounded),
          onPressed: widget.onTapFilters,
        ),
      ],
    );
  }
}

class _FloatingBar extends StatelessWidget {
  final VoidCallback onSort;
  final VoidCallback onSaveSearch;
  const _FloatingBar({required this.onSort, required this.onSaveSearch});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0, right: 0, bottom: 12,
      child: SafeArea(
        child: Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.10),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.sort, size: 20),
                  tooltip: "ترتيب",
                  onPressed: onSort,
                ),
                const SizedBox(width: 4),
                Text("ترتيب", style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(width: 12),
                IconButton(
                  icon: const Icon(Icons.bookmark_add_outlined, size: 20),
                  tooltip: "حفظ البحث",
                  onPressed: onSaveSearch,
                ),
                const SizedBox(width: 4),
                Text("حفظ", style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
class _CropCardStyle extends ConsumerWidget {
  final Crop crop;
  final VoidCallback onTap;
  const _CropCardStyle({required this.crop, required this.onTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Get current user id (adjust to your auth state)
    final String? meId = ref.watch(currentUserProvider.select((u) => u?.id));
    final bool isOwner = (meId != null && meId == crop.sellerId.toString()); // <- use sellerId

    // Real favorites state
    final favState = ref.watch(favouritesControllerProvider);
    final bool isFav = favState.favoritedCropIdsDefault.contains(crop.id);

    final String? imageUrl = crop.imageUrl;
    final String title = crop.name.isNotEmpty ? crop.name : 'بدون عنوان';
    final String priceText = crop.price > 0 ? '${crop.price.toStringAsFixed(0)} جنيه' : '—';
    final String qtyText = (crop.qty > 0 ? crop.qty.toStringAsFixed(crop.qty % 1 == 0 ? 0 : 2) : '—') +
        (crop.unit.isNotEmpty ? ' ${crop.unit}' : '');
    final String stateText = crop.location.state ?? 'غير محدد';
    final bool isNew = crop.isNew;

    Future<void> _toggle() async {
      if (isOwner) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('لا يمكنك حفظ إعلانك ضمن المفضلة')),
        );
        return;
      }
      await ref.read(favouritesControllerProvider.notifier)
          .toggleHeart(context: context, cropId: crop.id); // default list
    }

    return GestureDetector(
      onTap: onTap,
      child: Material(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        elevation: 1,
        child: ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: imageUrl == null
                          ? Container(
                        color: theme.colorScheme.surfaceVariant,
                        child: const Icon(Icons.image, size: 48),
                      )
                          : Image.network(imageUrl, fit: BoxFit.cover),
                    ),
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(.45), Colors.transparent],
                          ),
                        ),
                      ),
                    ),

                    // ❤️ Heart (block if owner)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: isOwner
                          ? _CircleIcon(
                        icon: Icons.lock_outline,
                        filled: false,
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('هذا إعلانك — لا يمكن حفظه')),
                          );
                        },
                      )
                          : InkWell(
                        customBorder: const CircleBorder(),
                        onLongPress: () => showAddToListSheet(context, ref, cropId: crop.id),
                        child: _CircleIcon(
                          icon: isFav ? Icons.favorite : Icons.favorite_border,
                          filled: isFav,
                          onTap: _toggle,
                        ),
                      ),
                    ),

                    // Share
                    Positioned(
                      top: 8,
                      left: 8,
                      child: _CircleIcon(
                        icon: Icons.share_outlined,
                        onTap: () async {
                          await Share.share('$title - $priceText');
                        },
                      ),
                    ),

                    // Badges
                    Positioned(
                      left: 8,
                      bottom: 8,
                      child: Wrap(
                        spacing: 6,
                        children: [
                          _MiniBadge(text: qtyText),
                          if (isNew) _MiniBadge(text: 'جديد'),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // text area
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Text(
                          priceText,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.location_on, size: 16),
                        const SizedBox(width: 2),
                        Text(stateText, style: theme.textTheme.bodySmall),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Option<T> {
  final String label;
  final T value;
  const _Option({required this.label, required this.value});
}

class _SimpleListSheet<T> extends StatelessWidget {
  final String title;
  final List<_Option<T>> options;
  final T? selected;
  const _SimpleListSheet({required this.title, required this.options, this.selected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.outlineVariant,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(title, style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              ...options.map((o) {
                final isSel = o.value == selected;
                return ListTile(
                  title: Text(o.label),
                  trailing: isSel ? Icon(Icons.check, color: theme.colorScheme.primary) : null,
                  onTap: () => Navigator.of(context).pop(o.value),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}

class _PriceRangeSheet extends StatefulWidget {
  final double initialMin;
  final double initialMax;
  const _PriceRangeSheet({required this.initialMin, required this.initialMax});

  @override
  State<_PriceRangeSheet> createState() => _PriceRangeSheetState();
}

class _PriceRangeSheetState extends State<_PriceRangeSheet> {
  late final TextEditingController _minC =
  TextEditingController(text: widget.initialMin.toStringAsFixed(0));
  late final TextEditingController _maxC =
  TextEditingController(text: widget.initialMax.toStringAsFixed(0));

  @override
  void dispose() { _minC.dispose(); _maxC.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Padding(
        padding: EdgeInsets.only(left:16, right:16, top:16, bottom: mq.viewInsets.bottom + 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 40, height: 4,
                decoration: BoxDecoration(color: theme.colorScheme.outlineVariant, borderRadius: BorderRadius.circular(2))),
            const SizedBox(height: 12),
            Text('نطاق السعر', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: TextField(
                  controller: _minC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'من',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  controller: _maxC,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'إلى',
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ]),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                icon: const Icon(Icons.check),
                label: const Text('تطبيق'),
                onPressed: () {
                  final min = double.tryParse(_minC.text.trim());
                  final max = double.tryParse(_maxC.text.trim());
                  if (min == null && max == null) {
                    Navigator.of(context).pop(const _PriceRange('أي سعر', 0, 1000)); // default
                    return;
                  }
                  final resolvedMin = min ?? 0;
                  final resolvedMax = (max != null && max >= resolvedMin) ? max : null;
                  Navigator.of(context).pop(_PriceRange('custom', resolvedMin, resolvedMax ?? 1000000));
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CircleIcon extends StatelessWidget {
  final IconData icon;
  final bool filled;
  final VoidCallback onTap;
  const _CircleIcon({required this.icon, this.filled = false, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? Colors.red : Colors.white,
      shape: const CircleBorder(),
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 20, color: filled ? Colors.white : Colors.black87),
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  final String text;
  const _MiniBadge({required this.text});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(.9),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
    );
  }
}

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

  final _types = const [
    {'value': 'grain', 'label': 'حبوب'},
    {'value': 'vegetable', 'label': 'خضروات'},
    {'value': 'fruit', 'label': 'فواكه'},
  ];

  final _states = const [
    {'value': 'Khartoum', 'label': 'الخرطوم'},
    {'value': 'Gezira', 'label': 'الجزيرة'},
    {'value': 'Sennar', 'label': 'سنار'},
    {'value': 'Kassala', 'label': 'كسلا'},
  ];

  final _priceRanges = const [
    _PriceRange('أي سعر', 0, 1000),
    _PriceRange('0 - 100 جنيه', 0, 100),
    _PriceRange('100 - 500 جنيه', 100, 500),
    _PriceRange('500 - 1000 جنيه', 500, 1000),
    _PriceRange('أكثر من 1000 جنيه', 1000, 10000),
  ];

  late int _priceIndex;

  @override
  void initState() {
    super.initState();
    _priceIndex = _priceRanges.indexWhere((r) => r.min == _min && r.max == _max);
    if (_priceIndex == -1) _priceIndex = 0;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mq = MediaQuery.of(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Container(
        constraints: BoxConstraints(
          maxHeight: mq.size.height * 0.8,
        ),
        child: Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: mq.viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: theme.colorScheme.outline,
                  borderRadius: BorderRadius.circular(2),
                ),
                alignment: Alignment.center,
              ),
              Row(
                children: [
                  Icon(
                    Icons.tune_rounded,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'التصفية والفرز',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _FilterSection(
                        title: 'نوع المحصول',
                        icon: Icons.agriculture,
                        child: DropdownButtonFormField<String>(
                          value: _type,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('جميع الأنواع')),
                            ..._types.map((t) => DropdownMenuItem(
                              value: t['value'],
                              child: Text(t['label']!),
                            )),
                          ],
                          onChanged: (v) => setState(() => _type = v),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _FilterSection(
                        title: 'الولاية',
                        icon: Icons.location_on,
                        child: DropdownButtonFormField<String>(
                          value: _state,
                          isExpanded: true,
                          decoration: InputDecoration(
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          items: [
                            const DropdownMenuItem(value: null, child: Text('جميع الولايات')),
                            ..._states.map((s) => DropdownMenuItem(
                              value: s['value'],
                              child: Text(s['label']!),
                            )),
                          ],
                          onChanged: (v) => setState(() => _state = v),
                        ),
                      ),
                      const SizedBox(height: 20),

                      _FilterSection(
                        title: 'نطاق السعر',
                        icon: Icons.monetization_on,
                        child: Column(
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: List.generate(_priceRanges.length, (i) {
                                final r = _priceRanges[i];
                                return FilterChip(
                                  label: Text(r.label),
                                  selected: _priceIndex == i,
                                  onSelected: (_) => setState(() {
                                    _priceIndex = i;
                                    _min = r.min;
                                    _max = r.max;
                                  }),
                                  selectedColor: theme.colorScheme.primaryContainer,
                                  checkmarkColor: theme.colorScheme.primary,
                                );
                              }),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      _FilterSection(
                        title: 'ترتيب النتائج',
                        icon: Icons.sort,
                        child: Column(
                          children: SortOption.values.map((s) => RadioListTile<SortOption>(
                            title: Row(
                              children: [
                                Icon(s.icon, size: 20),
                                const SizedBox(width: 8),
                                Text(s.label),
                              ],
                            ),
                            value: s,
                            groupValue: _sort,
                            onChanged: (v) => setState(() => _sort = v!),
                            contentPadding: EdgeInsets.zero,
                          )).toList(),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.refresh),
                      label: const Text('إعادة الضبط'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
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
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check),
                      label: const Text('تطبيق الفلاتر'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
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
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final Widget child;

  const _FilterSection({
    required this.title,
    required this.icon,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        child,
      ],
    );
  }
}
