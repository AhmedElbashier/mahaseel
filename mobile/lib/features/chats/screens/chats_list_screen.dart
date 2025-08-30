import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mahaseel/features/auth/state/auth_controller.dart';
import '../../../services/api_client.dart';
import '../data/chat_repo.dart';
import '../models/chats.dart';
import './chats_thread_screen.dart';

final scopeProvider = StateProvider<String>((_) => 'all'); // all | buying | selling

final conversationsProvider = FutureProvider.autoDispose<List<Conversation>>((ref) async {
  final scope = ref.watch(scopeProvider);
  final auth = ref.watch(authControllerProvider);

  // Wait for bootstrap to finish
  if (!auth.bootstrapped) {
    // small wait to avoid tight loop
    await Future.delayed(const Duration(milliseconds: 50));
    throw const AsyncError<Object>('bootstrapping', StackTrace.empty);
  }

  // If not authed, show empty list (or throw to show an error message)
  if (!auth.isAuthenticated) {
    return <Conversation>[];
  }

  // Make the API call
  final repo = ref.read(chatRepoProvider); // read (not watch) to avoid extra rebuilds
  return repo.listConversations(scope);
});

final chatRepoProvider = Provider<ChatRepo>((ref) {
  // ApiClient is your singleton that already manages baseUrl + token
  final dio = ApiClient().dio;
  return ChatRepo(dio);
});

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scope = ref.watch(scopeProvider);
    final convs = ref.watch(conversationsProvider);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: AppBar(title: const Text('المحادثات')),
        body: Column(
          children: [
            const SizedBox(height: 8),
            // === Top badges (three filters) ===
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _Badge(label: 'الكل', selected: scope == 'all', onTap: () => ref.read(scopeProvider.notifier).state = 'all'),
                  _Badge(label: 'بيع', selected: scope == 'selling', onTap: () => ref.read(scopeProvider.notifier).state = 'selling'),
                  _Badge(label: 'شراء', selected: scope == 'buying', onTap: () => ref.read(scopeProvider.notifier).state = 'buying'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Expanded(
              child: convs.when(
                data: (items) => ListView.separated(
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const Divider(height: 1),
                  itemBuilder: (ctx, i) {
                    final c = items[i];
                    final last = c.lastMessage;
                    return ListTile(
                      leading: CircleAvatar(child: Text(c.id.toString())),
                      title: Text(last?.body ?? '—'),
                      subtitle: Text(last != null ? timeOfDay(last.createdAt) : ''),
                      trailing: c.unreadCount > 0
                          ? CircleAvatar(radius: 12, child: Text(c.unreadCount.toString()))
                          : null,
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(
                        builder: (_) => ChatThreadScreen(conversationId: c.id),
                      )),
                    );
                  },
                ),
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, st) {
                    final msg = e.toString();
                    if (msg.contains('bootstrapping')) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return Center(child: Text('Error: $e'));
                  },
              ),
            )
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const _Badge({required this.label, required this.selected, required this.onTap});
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? Theme.of(context).colorScheme.primary : Colors.grey.shade400),
          color: selected ? Theme.of(context).colorScheme.primary.withOpacity(0.12) : null,
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.w600)),
      ),
    );
  }
}

String timeOfDay(DateTime dt) {
  final h = dt.hour.toString().padLeft(2, '0');
  final m = dt.minute.toString().padLeft(2, '0');
  return '$h:$m';
}
