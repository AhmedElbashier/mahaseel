import 'package:flutter/material.dart';

class FilterPill extends StatelessWidget {
  final IconData? icon;
  final String label;
  final VoidCallback? onTap;
  final VoidCallback? onClear;
  final bool selected;
  const FilterPill({super.key, this.icon, required this.label, this.onTap, this.onClear, this.selected = false});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = selected ? cs.primary.withOpacity(0.14) : cs.surface;
    final border = selected ? cs.primary : cs.outlineVariant;
    final textColor = selected ? cs.primary : cs.onSurface;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: border, width: 1),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: textColor),
            const SizedBox(width: 6),
          ],
          Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(color: textColor, fontWeight: FontWeight.w600)),
          if (onClear != null) ...[
            const SizedBox(width: 6),
            InkResponse(
              onTap: onClear,
              radius: 16,
              child: Icon(Icons.close_rounded, size: 16, color: textColor),
            )
          ]
        ]),
      ),
    );
  }
}

