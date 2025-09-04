import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  const PrimaryButton({super.key, required this.label, this.onPressed, this.icon, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

class OutlineButtonBrand extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool expanded;
  const OutlineButtonBrand({super.key, required this.label, this.onPressed, this.icon, this.expanded = false});

  @override
  Widget build(BuildContext context) {
    final btn = OutlinedButton.icon(
      onPressed: onPressed,
      icon: icon != null ? Icon(icon, size: 18) : const SizedBox.shrink(),
      label: Text(label),
    );
    return expanded ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}

