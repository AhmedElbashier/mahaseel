// lib/features/auth/phone_formatter.dart
import 'package:flutter/services.dart';

/// Normalize any Sudan phone input to E.164: +2499XXXXXXXX
/// - Strips spaces, dashes, parentheses
/// - Handles inputs like: 0XXXXXXXXX, 9XXXXXXXX, +2499XXXXXXX, 002499XXXXXXX
/// - Returns "+249..." or throws [FormatException] if unfixable
String formatPhone(String input) {
  // Keep digits only
  var digits = input.replaceAll(RegExp(r'\D'), '');

  // Handle international prefixes like 00...
  if (digits.startsWith('00')) {
    digits = digits.substring(2);
  }

  // Now digits may start with: 249..., 0..., or 9...
  if (digits.startsWith('249')) {
    // Already has country code; expect next to start with 9 for mobile (common case)
    final local = digits.substring(3);
    if (local.isEmpty) throw const FormatException('Invalid phone number');
    return '+249$local';
  }

  if (digits.startsWith('0')) {
    // Local format like 0 9xx xxx xxx -> drop leading 0, prepend +249
    final local = digits.substring(1);
    if (local.isEmpty) throw const FormatException('Invalid phone number');
    return '+249$local';
  }

  // If it starts with 9 (common when user types mobile without leading 0)
  if (digits.startsWith('9')) {
    return '+249$digits';
  }

  // Fallback: if length looks like local without leading 0, still force +249
  if (digits.length >= 8 && digits.length <= 12) {
    return '+249$digits';
  }

  throw const FormatException('Cannot normalize phone number');
}

/// UI typing helper: formats as "+249 9xx xxx xxx" while user types
class PhoneNumberFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
      TextEditingValue oldValue,
      TextEditingValue newValue,
      ) {
    final raw = newValue.text;
    final digits = raw.replaceAll(RegExp(r'\D'), '');

    // Build pretty display, but do NOT use this for API calls.
    String display = '+249';
    String local;

    if (digits.startsWith('249')) {
      local = digits.substring(3);
    } else if (digits.startsWith('0')) {
      local = digits.substring(1);
    } else {
      local = digits;
    }

    if (local.isNotEmpty) {
      // group as: 9xx xxx xxx (best-effort)
      if (local.length <= 3) {
        display = '+249 $local';
      } else if (local.length <= 6) {
        display = '+249 ${local.substring(0, 3)} ${local.substring(3)}';
      } else {
        final part1 = local.substring(0, 3);
        final part2 = local.substring(3, 6);
        final part3 = local.substring(6);
        display = '+249 $part1 $part2 $part3';
      }
    } else {
      display = '+249 ';
    }

    // Keep cursor at end safely
    final selection = TextSelection.collapsed(offset: display.length);
    return TextEditingValue(text: display, selection: selection);
  }
}
