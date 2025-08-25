
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../state/crops_controller.dart';
import '../../../widgets/crop_card.dart';
import '../../../widgets/crop_skeleton.dart';
import '../data/crops_repo.dart' show SortOption;
import '../data/crop_filters.dart';

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
        state: _filters.state,
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
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            backgroundColor: theme.colorScheme.primary,
            foregroundColor: theme.colorScheme.onPrimary,
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'المحاصيل',
                style: TextStyle(
                  color: theme.colorScheme.onPrimary,
                  fontWeight: FontWeight.bold,
                ),
              ),
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.primaryContainer,
                    ],
                  ),
                ),
              ),
            ),
            actions: [
              Stack(
                children: [
                  IconButton(
                    icon: const Icon(Icons.tune_rounded),
                    tooltip: 'الفرز والتصفية',
                    onPressed: _openFilters,
                  ),
                  if (_filters.hasActiveFilters)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(2),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 16,
                          minHeight: 16,
                        ),
                        child: Text(
                          '${_filters.activeFilterCount}',
                          style: TextStyle(
                            color: theme.colorScheme.onError,
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
            ],
          ),
          if (_filters.hasActiveFilters)
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: theme.colorScheme.primary.withOpacity(0.3),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.filter_alt,
                      size: 16,
                      color: theme.colorScheme.primary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'تم تطبيق ${_filters.activeFilterCount} فلتر',
                        style: TextStyle(
                          color: theme.colorScheme.primary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () async {
                        setState(() => _filters = const _Filters());
                        await ref.read(cropsControllerProvider.notifier).applyFilters();
                      },
                      icon: const Icon(Icons.clear, size: 16),
                      label: const Text('إزالة الكل'),
                      style: TextButton.styleFrom(
                        foregroundColor: theme.colorScheme.primary,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          SliverToBoxAdapter(
            child: RefreshIndicator(
              onRefresh: () => ref.read(cropsControllerProvider.notifier).refresh(),
              child: _buildContent(context, loading, items, error, loadingMore),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContent(BuildContext context, bool loading, List items, String? error, bool loadingMore) {
    final theme = Theme.of(context);

    if (loading && items.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: List.generate(
            6,
                (index) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: const CropSkeleton(),
            ),
          ),
        ),
      );
    }

    if (error != null && items.isEmpty) {
      return Container(
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
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(
              'حدث خطأ في جلب البيانات',
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.error,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              error,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => ref.read(cropsControllerProvider.notifier).refresh(),
              icon: const Icon(Icons.refresh),
              label: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      );
    }

    if (items.isEmpty) {
      return Container(
        margin: const EdgeInsets.all(24),
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(
              Icons.agriculture_outlined,
              size: 80,
              color: theme.colorScheme.outline,
            ),
            const SizedBox(height: 16),
            Text(
              'لا توجد محاصيل',
              style: theme.textTheme.headlineSmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'لم يتم العثور على أي محاصيل تطابق معايير البحث',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.outline,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          ...items.asMap().entries.map((entry) {
            final index = entry.key;
            final crop = entry.value;
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == items.length - 1 ? 0 : 16,
              ),
              child: CropCard(
                crop: crop,
                onTap: () => context.push('/crops/${crop.id}'),
              ),
            );
          }),
          if (loadingMore)
            Padding(
              padding: const EdgeInsets.all(16),
              child: CircularProgressIndicator(
                color: theme.colorScheme.primary,
              ),
            ),
        ],
      ),
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
