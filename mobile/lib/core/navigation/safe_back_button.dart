import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'nav_extensions.dart';

class SafeBackButton extends StatelessWidget {
  final String fallbackPath; // e.g. '/home'
  final Color iconColor;
  final EdgeInsets padding;

  const SafeBackButton({
    super.key,
    required this.fallbackPath,
    this.iconColor = Colors.white,
    this.padding = const EdgeInsets.all(8),
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Container(
        padding: padding,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(Icons.arrow_back_ios, color: iconColor),
      ),
      onPressed: () => context.safePopOrGo(fallbackPath),
      tooltip: 'رجوع',
    );
  }
}
