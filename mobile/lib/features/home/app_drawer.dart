
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../auth/state/auth_controller.dart';

class AppDrawer extends ConsumerWidget {
  const AppDrawer({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final authState = ref.watch(authControllerProvider);

    return Drawer(
      backgroundColor: colorScheme.surface,
      surfaceTintColor: colorScheme.surfaceTint,
      child: SafeArea(
        child: Column(
          children: [
            // Modern header with gradient
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    colorScheme.primaryContainer,
                    colorScheme.primaryContainer.withOpacity(0.8),
                  ],
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar with modern styling
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colorScheme.primary.withOpacity(0.3),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.person_rounded,
                      size: 32,
                      color: colorScheme.onPrimary,
                    ),
                  ),
                  const SizedBox(height: 16),

                  // User info
                  Text(
                    'مرحباً بك',
                    style: theme.textTheme.titleLarge?.copyWith(
                      color: colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (authState.phone != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      authState.phone!,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onPrimaryContainer.withOpacity(0.8),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            // Navigation items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.home_rounded,
                    title: 'الرئيسية',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/home');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.agriculture_rounded,
                    title: 'محاصيلي',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/crops');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.add_circle_rounded,
                    title: 'إضافة محصول جديد',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/crops/add');
                    },
                  ),

                  const Divider(height: 32),

                  _buildDrawerItem(
                    context,
                    icon: Icons.analytics_rounded,
                    title: 'إحصائياتي',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement analytics page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('الإحصائيات قريباً'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.star_rounded,
                    title: 'التقييمات',
                    onTap: () {
                      Navigator.pop(context);
                      // TODO: Implement ratings page
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('التقييمات قريباً'),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.support_agent_rounded,
                    title: 'الدعم الفني',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/support');
                    },
                  ),
                  _buildDrawerItem(
                    context,
                    icon: Icons.settings_rounded,
                    title: 'الإعدادات',
                    onTap: () {
                      Navigator.pop(context);
                      context.go('/settings');
                    },
                  ),
                ],
              ),
            ),

            // Bottom section with logout
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: colorScheme.outline.withOpacity(0.2),
                  ),
                ),
              ),
              child: Column(
                children: [
                  _buildDrawerItem(
                    context,
                    icon: Icons.info_outline_rounded,
                    title: 'حول التطبيق',
                    onTap: () {
                      Navigator.pop(context);
                      _showAboutDialog(context);
                    },
                  ),
                  const SizedBox(height: 8),
                  _buildDrawerItem(
                    context,
                    icon: Icons.logout_rounded,
                    title: 'تسجيل الخروج',
                    textColor: colorScheme.error,
                    onTap: () async {
                      Navigator.pop(context);
                      await ref.read(authControllerProvider.notifier).logout();
                      if (context.mounted) {
                        context.go('/');
                      }
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawerItem(
      BuildContext context, {
        required IconData icon,
        required String title,
        required VoidCallback onTap,
        Color? textColor,
      }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final effectiveTextColor = textColor ?? colorScheme.onSurface;

    return ListTile(
      leading: Icon(
        icon,
        color: effectiveTextColor,
        size: 24,
      ),
      title: Text(
        title,
        style: theme.textTheme.bodyLarge?.copyWith(
          color: effectiveTextColor,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 4,
      ),
      horizontalTitleGap: 16,
    );
  }

  void _showAboutDialog(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'محاصيل',
      applicationVersion: '1.0.0',
      applicationIcon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.primary,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          Icons.agriculture_rounded,
          color: Theme.of(context).colorScheme.onPrimary,
          size: 32,
        ),
      ),
      children: [
        Text(
          'منصة تربط المزارعين السودانيين مباشرة مع المشترين لبيع المحاصيل الزراعية.',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
      ],
    );
  }
}
