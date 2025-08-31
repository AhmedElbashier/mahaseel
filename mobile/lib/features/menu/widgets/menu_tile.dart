import 'package:flutter/material.dart';
import '../models/menu_item.dart';
import 'package:go_router/go_router.dart';

class MenuTile extends StatelessWidget {
  final MenuItemModel item;
  final String? overrideRightValue; // lets us inject city/lang current value

  const MenuTile({super.key, required this.item, this.overrideRightValue});

  @override
  Widget build(BuildContext context) {
    final rightText = overrideRightValue ?? item.rightValue;

    return ListTile(
      leading: Icon(item.icon),
      title: Text(item.title),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (rightText != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Text(rightText, style: const TextStyle(color: Colors.black54)),
            ),
          const Icon(Icons.chevron_right),
        ],
      ),
      onTap: item.onTap ??
              () {
            if (item.route != null) context.push(item.route!);
          },
    );
  }
}
