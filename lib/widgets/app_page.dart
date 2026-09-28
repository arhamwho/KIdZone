import 'package:flutter/material.dart';

import '../utils/responsive.dart';
import 'soft_background.dart';

/// Standard page frame for KidZone.
///
/// Wraps a transparent [Scaffold] in the pastel [SoftBackground] so the
/// decoration also shows through the app bar, then applies [SafeArea] and the
/// shared content width. Screens only supply their content.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.child,
    this.title,
    this.actions,
    this.leading,
    this.tint,
    this.showDecorations = false,
    this.bottomBar,
    this.floatingActionButton,
    this.constrainWidth = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? tint;
  final bool showDecorations;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  /// Set to false for full-bleed content such as horizontal carousels.
  final bool constrainWidth;

  @override
  Widget build(BuildContext context) {
    final Widget body = constrainWidth
        ? ResponsiveContainer(child: child)
        : child;

    return SoftBackground(
      tint: tint,
      showDecorations: showDecorations,
      quiet: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: title == null
            ? null
            : AppBar(title: Text(title!), actions: actions, leading: leading),
        // The app bar already handles the status bar inset.
        body: SafeArea(top: title == null ? true : false, child: body),
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
