// lib/features/favourite/screens/favourites_home_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/brand_chip.dart';
import '../state/favourites_controller.dart';
import '../widgets/manage_lists_bottom_sheet.dart';
import 'favourites_list_screen.dart';
import '../../../core/ui/empty_state.dart';

class FavouritesHomeScreen extends ConsumerStatefulWidget {
  const FavouritesHomeScreen({super.key});

  @override
  ConsumerState<FavouritesHomeScreen> createState() => _FavouritesHomeScreenState();
}

class _FavouritesHomeScreenState extends ConsumerState<FavouritesHomeScreen> {
  @override
  void initState() {
    super.initState();
    // bootstrap on open
    Future.microtask(() => ref.read(favouritesControllerProvider.notifier).bootstrap());
  }

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(favouritesControllerProvider);
    final ctrl = ref.read(favouritesControllerProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Favourites'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: () => showManageListsSheet(context, ref),
            tooltip: 'Manage lists',
          )
        ],
      ),
      body: st.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
        children: [
          // chips
          SizedBox(
            height: 56,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              scrollDirection: Axis.horizontal,
              itemBuilder: (_, i) {
                final l = st.lists[i];
                final selected = l.id == st.selectedListId;
                return GestureDetector(
                  onTap: () => ctrl.selectList(l.id),
                  child: FilterPill(
                    label: l.count > 0 ? '${l.name} (${l.count})' : l.name,
                    selected: selected,
                  ),
                );
              },
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemCount: st.lists.length,
            ),
          ),

          const Divider(height: 1),

          Expanded(
            child: (st.selectedListId == null)
                ? const EmptyState(
                    icon: Icons.favorite_border,
                    title: 'No list selected',
                    message: 'Create or select a list',
                  )
                : FavouritesListScreen(listId: st.selectedListId!),
          ),
        ],
      ),
    );
  }
}
