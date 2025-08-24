
// lib/features/home/home_shell.dart
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:mahaseel/features/home/app_drawer.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  final String title;
  final int currentIndex;
  final ValueChanged<int> onTabSelected;

  const HomeShell({
    super.key,
    required this.child,
    this.title = 'محاصيل',
    required this.currentIndex,
    required this.onTabSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // Modern drawer positioning
        drawer: isRtl ? null : const AppDrawer(),
        endDrawer: isRtl ? const AppDrawer() : null,

        // Enhanced app bar with glassmorphism effect
        appBar: AppBar(
          title: Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: colorScheme.onSurface,
            ),
          ),
          centerTitle: true,
          elevation: 0,
          scrolledUnderElevation: 4,
          backgroundColor: colorScheme.surface.withOpacity(0.95),
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
          iconTheme: IconThemeData(
            color: colorScheme.onSurface,
            size: 24,
          ),
          actions: [
            // Modern notification bell
            IconButton(
              onPressed: () {
                context.go("notifications");
              },
              icon: Badge(
                smallSize: 8,
                backgroundColor: Colors.red.shade400,
                child: Icon(Icons.notifications_outlined),
              ),
              tooltip: 'الإشعارات',
            ),
            const SizedBox(width: 8),
          ],
        ),

        // Enhanced body with safe area
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  colorScheme.surface,
                  colorScheme.surfaceVariant.withOpacity(0.3),
                ],
              ),
            ),
            child: child,
          ),
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
                icon: Icon(Icons.add_circle_outline),
                selectedIcon: Icon(Icons.add_circle_rounded),
                label: 'إضافة محصول',
                tooltip: 'إضافة محصول جديد',
              ),
              NavigationDestination(
                icon: Icon(Icons.support_agent_outlined),
                selectedIcon: Icon(Icons.support_agent_rounded),
                label: 'الدعم',
                tooltip: 'الدعم الفني',
              ),
              NavigationDestination(
                icon: Icon(Icons.settings_outlined),
                selectedIcon: Icon(Icons.settings_rounded),
                label: 'الإعدادات',
                tooltip: 'إعدادات التطبيق',
              ),
            ],
          ),
        ),

        // Floating action button for quick actions
        floatingActionButton: currentIndex == 0
            ? FloatingActionButton.extended(
          onPressed: () => onTabSelected(1),
          icon: Icon(Icons.add_rounded),
          label: Text('إضافة محصول'),
          backgroundColor: colorScheme.primaryContainer,
          foregroundColor: colorScheme.onPrimaryContainer,
          elevation: 6,
        )
            : null,
        floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      ),
    );
  }
}
