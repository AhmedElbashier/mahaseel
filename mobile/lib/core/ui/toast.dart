import 'package:flutter/material.dart';

void showToast(BuildContext context, String message) {
  final theme = Theme.of(context);
  final snack = SnackBar(
    content: Text(message, textAlign: TextAlign.center),
    behavior: SnackBarBehavior.floating,
    backgroundColor: theme.colorScheme.inverseSurface,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    margin: const EdgeInsets.all(16),
    duration: const Duration(seconds: 3),
  );
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(snack);
}

