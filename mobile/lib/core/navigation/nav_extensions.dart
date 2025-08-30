import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

extension NavSafety on BuildContext {
  /// Pop if we can, otherwise go to a fallback route.
  void safePopOrGo(String fallbackPath) {
    if (canPop()) {
      pop();
    } else {
      go(fallbackPath);
    }
  }

  /// Convenience for top-level screens that shouldn't have a back button.
  bool get isRoot => !canPop();
}
