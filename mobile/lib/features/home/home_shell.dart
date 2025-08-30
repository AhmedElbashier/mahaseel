
// lib/features/home/home_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  // final String title;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final bool hideTopBar;

  const HomeShell({
    super.key,
    required this.child,
    // this.title = 'محاصيل',
    required this.currentIndex,
    required this.onTabSelected,
    this.hideTopBar = false,

  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    // final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Modern drawer positioning
        // drawer: isRtl ? null : const AppDrawer(),
        // endDrawer: isRtl ? const AppDrawer() : null,

        // Enhanced app bar with glassmorphism effect
        appBar: hideTopBar ? null : AppBar(
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          foregroundColor: Colors.black87,
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
              tooltip: 'الإشعارات',
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Enhanced body with safe area
          body: SafeArea(
            child: child,
          ),

        // Modern bottom navigation with Material 3 design
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
            destinations: [
              NavigationDestination(
                icon: Icon(Icons.home_outlined),
                selectedIcon: Icon(Icons.home_rounded),
                label: 'الرئيسية',
                tooltip: 'الرئيسية',
              ),
              NavigationDestination(
                icon: Icon(Icons.chat_outlined),
                selectedIcon: Icon(Icons.chat_rounded),
                label: 'المحادثات',
                tooltip: 'المحادثات',
              ),
              NavigationDestination(
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'إضافة محصول',
                tooltip: 'إضافة محصول جديد',
              ),
              NavigationDestination(
                icon: Icon(Icons.favorite_outline_outlined),
                selectedIcon: Icon(Icons.favorite_rounded),
                label: 'المفضلة',
                tooltip: 'المفضلة',
              ),
              NavigationDestination(
                icon: Icon(Icons.menu_outlined),
                selectedIcon: Icon(Icons.menu_rounded),
                label: 'القائمة',
                tooltip: 'القائمة',
              ),
            ],
          ),
        ),

        // Floating action button for quick actions
        // floatingActionButton: currentIndex == 0
        //     ? FloatingActionButton.extended(
        //   onPressed: () => onTabSelected(1),
        //   icon: Icon(Icons.add_rounded),
        //   label: Text('إضافة محصول'),
        //   backgroundColor: colorScheme.primaryContainer,
        //   foregroundColor: colorScheme.onPrimaryContainer,
        //   elevation: 6,
        // )
        //     : null,
        // floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
