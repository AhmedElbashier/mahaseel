import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../state/crops_controller.dart';
import '../../../widgets/crop_card.dart';
import '../../../widgets/crop_skeleton.dart';

class CropListScreen extends ConsumerStatefulWidget {
  const CropListScreen({super.key});

  @override
  ConsumerState<CropListScreen> createState() => _CropListScreenState();
}

class _CropListScreenState extends ConsumerState<CropListScreen> {
  final _controller = ScrollController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      if (_controller.position.pixels >= _controller.position.maxScrollExtent - 200) {
        ref.read(cropsControllerProvider.notifier).loadNextPage();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(cropsControllerProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('المحاصيل')),
      body: RefreshIndicator(
        onRefresh: () => ref.read(cropsControllerProvider.notifier).refresh(),
        child: Builder(
          builder: (context) {
            if (state.loading) {
              return ListView.separated(
                padding: const EdgeInsets.all(12),
                itemCount: 6,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (_, __) => const CropSkeleton(),
              );
            }

            if (state.error != null && state.items.isEmpty) {
              return ListView(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Center(child: Text('حدث خطأ في جلب البيانات.\n${state.error!}',
                        textAlign: TextAlign.center)),
                  ),
                  Center(
                    child: FilledButton(
                      onPressed: () => ref.read(cropsControllerProvider.notifier).refresh(),
                      child: const Text('إعادة المحاولة'),
                    ),
                  ),
                ],
              );
            }

            if (state.items.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 60),
                  Icon(Icons.inbox, size: 64),
                  SizedBox(height: 12),
                  Center(child: Text('لا توجد محاصيل حالياً')),
                ],
              );
            }

            return ListView.separated(
              controller: _controller,
              padding: const EdgeInsets.all(12),
              itemCount: state.items.length + (state.loadingMore ? 1 : 0),
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (ctx, i) {
                if (i >= state.items.length) {
                  // footer loader
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16.0),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                final crop = state.items[i];
                return CropCard(
                  crop: crop,
                  onTap: () {
                    // TODO: navigate to details screen (Day 15)
                    // context.go('/crop/${crop.id}');
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}
