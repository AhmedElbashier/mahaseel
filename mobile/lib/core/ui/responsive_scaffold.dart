import 'package:flutter/material.dart';

/// A drop-in Scaffold that prevents "overflowed by XX pixels" on small screens
/// and when the keyboard opens. Use it instead of a plain Scaffold.
class ResponsiveScaffold extends StatelessWidget {
  final PreferredSizeWidget? appBar;
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final Decoration? decoration;
  final bool extendBodyBehindAppBar;
  final Color? backgroundColor;
  final bool safeTop;

  const ResponsiveScaffold({
    super.key,
    required this.child,
    this.appBar,
    this.padding,
    this.decoration,
    this.extendBodyBehindAppBar = false,
    this.backgroundColor,
    this.safeTop = false
  });

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets; // keyboard

    return Scaffold(
      appBar: appBar,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
      backgroundColor: backgroundColor ?? Colors.transparent,
      body: Container(
        decoration: decoration,
        child: SafeArea(
          top: safeTop,
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
                padding: (padding ?? const EdgeInsets.all(32))
                // add space so the keyboard never covers the content
                    .add(EdgeInsets.only(bottom: insets.bottom)),
                child: ConstrainedBox(
                  // fill the height when there is room, otherwise become scrollable
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(child: child),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
