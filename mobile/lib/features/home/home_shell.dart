// lib/features/home/home_shell.dart
import 'package:flutter/material.dart';
import 'package:mahaseel/features/home/app_drawer.dart';

class HomeShell extends StatelessWidget {
  final Widget child;
  final String title;
  final VoidCallback? onAdd; // optional FAB action

  const HomeShell({
    super.key,
    required this.child,
    this.title = 'محاصيل',
    this.onAdd,
  });

  @override
  Widget build(BuildContext context) {
    // 1) Detect current text direction
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // 2) Return a Scaffold that picks drawer side based on RTL/LTR
    return Directionality( // keep Arabic RTL when app Locale is 'ar'
      textDirection: TextDirection.rtl,
      child: Scaffold(
        // If RTL → use endDrawer (right). If LTR → use drawer (left).
        drawer: isRtl ? null : const AppDrawer(),
        endDrawer: isRtl ? const AppDrawer() : null,

        appBar: AppBar(
          title: Text(title),),
        body: SafeArea(child: child),
        floatingActionButton: onAdd == null
            ? null
            : FloatingActionButton(
          onPressed: onAdd,
          tooltip: 'إضافة محصول',
          child: const Icon(Icons.add),
        ),
      ),
    );
  }
}
