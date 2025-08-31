import 'package:flutter/material.dart';

class MenuItemModel {
  final IconData icon;
  final String title;
  final String? rightValue;   // e.g. "All UAE", "English"
  final String? route;        // GoRouter path
  final VoidCallback? onTap;  // optional custom action

  const MenuItemModel({
    required this.icon,
    required this.title,
    this.rightValue,
    this.route,
    this.onTap,
  });
}

class MenuSection {
  final List<MenuItemModel> items;
  const MenuSection(this.items);
}
