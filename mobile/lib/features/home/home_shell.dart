// lib/features/home/home_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mahaseel/services/connectivity_provider.dart';

class HomeShell extends ConsumerWidget {
  final Widget child;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool hideTopBar;

  const HomeShell({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.onTabSelected,
    this.hideTopBar = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final online = ref.watch(connectivityStreamProvider).maybeWhen(
          data: (v) => v,
          orElse: () => true,
        );

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        appBar: hideTopBar
            ? null
            : AppBar(
                centerTitle: true,
                elevation: 0,
                scrolledUnderElevation: 4,
                backgroundColor: colorScheme.surface.withOpacity(0.98),
                surfaceTintColor: colorScheme.surfaceTint,
                foregroundColor: colorScheme.onSurface,
                systemOverlayStyle: theme.brightness == Brightness.light
                    ? const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.dark,
                      )
                    : const SystemUiOverlayStyle(
                        statusBarColor: Colors.transparent,
                        statusBarIconBrightness: Brightness.light,
                      ),
                actions: [
                  IconButton(
                    onPressed: () => context.push('/notifications'),
                    icon: Badge(
                      smallSize: 8,
                      backgroundColor: Colors.red.shade400,
                      child: const Icon(Icons.notifications_outlined),
                    ),
                    tooltip: 'Notifications',
                  ),
                  const SizedBox(width: 8),
                ],
              ),

        body: SafeArea(
          child: Column(
            children: [
              if (!online)
                Container(
                  width: double.infinity,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  color: Colors.amber.shade700,
                  child: const Text(
                    "You're offline. Trying to reconnect…",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.black, fontWeight: FontWeight.w600),
                  ),
                ),
              Expanded(child: child),
            ],
          ),
        ),

        bottomNavigationBar: Container(
          decoration: BoxDecoration(
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 20,
                offset: const Offset(0, -5),
              ),
            ],
          ),
          child: NavigationBar(
            selectedIndex: currentIndex,
            onDestinationSelected: onTabSelected,
            elevation: 0,
            backgroundColor: colorScheme.surface,
            surfaceTintColor: colorScheme.surfaceTint,
            animationDuration: const Duration(milliseconds: 300),
            labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
            destinations: const [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'Home',
                tooltip: 'Home',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat_rounded),
                label: 'Chats',
                tooltip: 'Chats',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'Add',
                tooltip: 'Add listing',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline_outlined),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'Favorites',
                tooltip: 'Favorites',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_outlined),
                selectedIcon: Icon(Icons.menu_rounded),
                label: 'Menu',
                tooltip: 'Menu',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

