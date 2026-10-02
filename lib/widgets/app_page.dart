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
    this.safeArea = true,
  });

  final Widget child;
  final String? title;
  final List<Widget>? actions;
  final Widget? leading;
  final Color? tint;
  final bool showDecorations;
  final Widget? bottomBar;
  final Widget? floatingActionButton;

  /// Set to false for full-bleed content such as maps.
  final bool constrainWidth;

  /// Set to false when the screen draws its own SafeArea (for example a map).
  final bool safeArea;

  bool get _hasAppBar {
    final bool hasTitle = title != null && title!.isNotEmpty;
    final bool hasActions = actions != null && actions!.isNotEmpty;
    return hasTitle || hasActions || leading != null;
  }

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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: _hasAppBar
            ? AppBar(
                title: title == null || title!.isEmpty ? null : Text(title!),
                actions: actions,
                leading: leading,
              )
            : null,
        body: SafeArea(
          top: safeArea && !_hasAppBar,
          bottom: safeArea,
          child: body,
        ),
        resizeToAvoidBottomInset: true,
        bottomNavigationBar: bottomBar,
        floatingActionButton: floatingActionButton,
      ),
    );
  }
}
