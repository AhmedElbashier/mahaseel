// lib/features/favourite/widgets/manage_lists_bottom_sheet.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/favourites_controller.dart';

Future<void> showManageListsSheet(BuildContext context, WidgetRef ref) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: Theme.of(context).cardColor,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
    ),
    builder: (_) => const _ManageListsBody(),
  );
}

class _ManageListsBody extends ConsumerWidget {
  const _ManageListsBody({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
            Text('Manage lists', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),

            Flexible(
              child: ListView.separated(
                shrinkWrap: true,
                itemCount: st.lists.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (_, i) {
                  final l = st.lists[i];
                  final canEdit = !l.isDefault;
                  return ListTile(
                    title: Text(l.name),
                    subtitle: Text(l.isDefault ? 'Default list' : 'Items: ${l.count}'),
                    trailing: canEdit ? PopupMenuButton<String>(
                      onSelected: (v) async {
                        if (v == 'rename') {
                          final newName = await _prompt(context, 'Rename list', l.name);
                          if (newName != null && newName.trim().isNotEmpty) {
                            await ref.read(favouritesControllerProvider.notifier)
                                .renameList(context, l.id, newName.trim());
                          }
                        } else if (v == 'delete') {
                          final ok = await _confirm(context, 'Delete "${l.name}"?');
                          if (ok) {
                            await ref.read(favouritesControllerProvider.notifier)
                                .deleteList(context, l.id);
                          }
                        }
                      },
                      itemBuilder: (_) => const [
                        PopupMenuItem(value: 'rename', child: Text('Rename')),
                        PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ) : const SizedBox(width: 24),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<String?> _prompt(BuildContext context, String title, String initial) async {
    final ctrl = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(title),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'List name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, ctrl.text), child: const Text('Save')),
        ],
      ),
    );
  }

  Future<bool> _confirm(BuildContext context, String msg) async {
    final res = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        content: Text(msg),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Yes')),
        ],
      ),
    );
    return res ?? false;
  }
}
