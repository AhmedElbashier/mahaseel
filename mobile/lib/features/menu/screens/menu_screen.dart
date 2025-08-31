import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';

import '../state/menu_providers.dart';
import '../data/menu_items.dart';
import '../widgets/menu_header.dart';
import '../widgets/menu_tile.dart';
import '../widgets/quick_cards.dart';

class MenuScreen extends ConsumerWidget {
  const MenuScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(userNameProvider);
    final verified = ref.watch(isVerifiedProvider);
    final joined = ref.watch(joinedTextProvider);

    final city = ref.watch(cityProvider);
    final language = ref.watch(languageProvider);

    // handlers for pickers (bottom sheets later)
    void onPickCity() {
      // TODO: show your city picker; demo change:
      ref.read(cityProvider.notifier).state = 'كل الإمارات';
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('اختر مدينة')));
    }

    void onPickLanguage() {
      // TODO: open language picker
      final notifier = ref.read(languageProvider.notifier);
      notifier.state = notifier.state == 'العربية' ? 'English' : 'العربية';
    }

    final sections = buildMenuSections(
      city: city,
      language: language,
      onCityTap: onPickCity,
      onLanguageTap: onPickLanguage,
    );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        body: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Column(
                children: [
                  MenuHeader(name: name, joinedText: joined, verified: verified),
                  const QuickCards(),
                ],
              ),
            ),
            // sections
            for (final section in sections) ...[
              const SliverToBoxAdapter(child: Divider(height: 8)),
              SliverList.separated(
                itemBuilder: (_, i) {
                  final item = section.items[i];
                  // inject live values for City/Language rows
                  final override = item.title == 'المدينة'
                      ? city
                      : (item.title == 'اللغة' ? language : null);
                  return MenuTile(item: item, overrideRightValue: override);
                },
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemCount: section.items.length,
              ),
            ],
            // footer: logout + version
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.only(bottom: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    ListTile(
                      leading: const Icon(Icons.logout, color: Colors.red),
                      title: const Text('تسجيل الخروج', style: TextStyle(color: Colors.red)),
                      onTap: () {
                        // wire to your auth logout + navigate to /login
                        context.push('/login');
                      },
                    ),
                    const SizedBox(height: 8),
                    FutureBuilder<PackageInfo>(
                      future: PackageInfo.fromPlatform(),
                      builder: (ctx, snap) {
                        final txt = snap.hasData
                            ? 'إصدار التطبيق • ${snap.data!.version} (${snap.data!.buildNumber})'
                            : 'إصدار التطبيق';
                        return Text(txt, style: const TextStyle(color: Colors.black45));
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
