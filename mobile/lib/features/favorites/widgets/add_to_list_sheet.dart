// lib/features/favourite/widgets/add_to_list_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/favourites_controller.dart';

Future<void> showAddToListSheet(BuildContext context, WidgetRef ref, {required int cropId}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => _AddToListBody(cropId: cropId),
  );
}

class _AddToListBody extends ConsumerStatefulWidget {
  final int cropId;
  const _AddToListBody({required this.cropId});

  @override
  ConsumerState<_AddToListBody> createState() => _AddToListBodyState();
}

class _AddToListBodyState extends ConsumerState<_AddToListBody> {
  final _nameCtrl = TextEditingController();
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final st = ref.watch(favouritesControllerProvider);

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 36, height: 4, decoration: BoxDecoration(
              color: Theme.of(context).dividerColor, borderRadius: BorderRadius.circular(2),
            )),

            const SizedBox(height: 12),
            Text('Save to list', style: Theme.of(context).textTheme.titleMedium),

            const SizedBox(height: 12),
            // existing lists
            if (st.lists.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 12),
                child: Text('No lists yet. Create one below.'),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: st.lists.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (_, i) {
                    final l = st.lists[i];
                    return ListTile(
                      title: Text(l.name),
                      subtitle: l.isDefault ? const Text('Default list') : null,
                      trailing: const Icon(Icons.chevron_right),
                      onTap: () async {
                        await ref.read(favouritesControllerProvider.notifier)
                            .toggleHeart(context: context, cropId: widget.cropId, listId: l.id);
                        if (mounted) Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),

            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _nameCtrl,
                    decoration: const InputDecoration(
                      hintText: 'New list name',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: _creating ? null : () async {
                    final name = _nameCtrl.text.trim();
                    if (name.isEmpty) return;
                    setState(() => _creating = true);
                    await ref.read(favouritesControllerProvider.notifier).createList(context, name);
                    setState(() => _creating = false);
                    _nameCtrl.clear();
                  },
                  child: _creating ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Create'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
