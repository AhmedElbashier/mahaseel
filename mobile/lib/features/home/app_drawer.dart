import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer({super.key});

  bool _isSelected(BuildContext context, String routePrefix) {
    final loc = GoRouterState.of(context).uri.toString();
    return loc == routePrefix || loc.startsWith(routePrefix);
  }


  @override
  Widget build(BuildContext context) {
    final items = <_NavItem>[
      _NavItem(
        icon: Icons.home_outlined,
        label: 'الرئيسية',
        route: '/home', // crops list
        selectedChecker: (ctx) => _isSelected(ctx, '/home'),
      ),
      _NavItem(
        icon: Icons.add_circle_outline,
        label: 'إضافة محصول',
        route: '/crops/add',
        selectedChecker: (ctx) => _isSelected(ctx, '/crops/add'),
      ),
      _NavItem(
        icon: Icons.support_agent_outlined,
        label: 'الدعم',
        route: '/support',
        selectedChecker: (ctx) => _isSelected(ctx, '/support'),
      ),
      _NavItem(
        icon: Icons.settings_outlined,
        label: 'الإعدادات',
        route: '/settings',
        selectedChecker: (ctx) => _isSelected(ctx, '/settings'),
      ),
    ];

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Drawer(
        child: SafeArea(
          child: Column(
            children: [
              // Optional header
              ListTile(
                leading: const CircleAvatar(child: Icon(Icons.agriculture)),
                title: const Text('تطبيق محاصيل'),
                subtitle: const Text('سوق المزارعين'),
              ),
              const Divider(),
              // Menu items
              Expanded(
                child: ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (ctx, i) {
                    final it = items[i];
                    final selected = it.selectedChecker(ctx);
                    return ListTile(
                      selected: selected,
                      leading: Icon(it.icon),
                      title: Text(it.label),
                      onTap: () {
                        Navigator.of(ctx).pop(); // close the drawer
                        context.go(it.route);
                      },
                    );
                  },
                ),
              ),
              const Divider(),
              // Logout or About section
              ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('تسجيل الخروج'),
                onTap: () {
                  // TODO: implement logout (clear secure storage, etc.)
                  Navigator.of(context).pop();
                  // Show a simple snackbar for now
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('تم تسجيل الخروج (تجريبي)')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final String route;
  final bool Function(BuildContext) selectedChecker;

  _NavItem({
    required this.icon,
    required this.label,
    required this.route,
    required this.selectedChecker,
  });
}
