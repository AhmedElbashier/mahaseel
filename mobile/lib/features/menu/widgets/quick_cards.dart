import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class QuickCards extends StatelessWidget {
  const QuickCards({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Row(
        children: const [
          Expanded(child: _QuickCard(title: 'إعلاناتي', icon: Icons.grid_view_outlined, route: '/my-ads')),
          SizedBox(width: 10),
          Expanded(child: _QuickCard(title: 'عمليات البحث', icon: Icons.search_outlined, route: '/my-searches')),
        ],
      ),
    );
  }
}

class _QuickCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String route;
  const _QuickCard({required this.title, required this.icon, required this.route});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => context.push(route),
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [BoxShadow(blurRadius: 10, spreadRadius: -10, offset: Offset(0, 10))],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 28),
            const SizedBox(height: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}
