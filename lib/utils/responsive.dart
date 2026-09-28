import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Screen size buckets used for responsive layouts.
enum ScreenSize { mobile, tablet, desktop }

/// Small helper around [MediaQuery] so screens can adapt without repeating
/// magic width numbers everywhere.
class Responsive {
  const Responsive._();

  static const double mobileMaxWidth = 600;
  static const double tabletMaxWidth = 1024;

  static ScreenSize of(BuildContext context) {
    final double width = MediaQuery.sizeOf(context).width;
    if (width < mobileMaxWidth) return ScreenSize.mobile;
    if (width < tabletMaxWidth) return ScreenSize.tablet;
    return ScreenSize.desktop;
  }

  static bool isMobile(BuildContext context) =>
      of(context) == ScreenSize.mobile;

  static bool isTablet(BuildContext context) =>
      of(context) == ScreenSize.tablet;

  static bool isDesktop(BuildContext context) =>
      of(context) == ScreenSize.desktop;

  /// Picks one of three values based on the current screen size.
  static T value<T>(
    BuildContext context, {
    required T mobile,
    T? tablet,
    T? desktop,
  }) {
    return switch (of(context)) {
      ScreenSize.mobile => mobile,
      ScreenSize.tablet => tablet ?? mobile,
      ScreenSize.desktop => desktop ?? tablet ?? mobile,
    };
  }

  /// Number of grid columns that comfortably fit the current width.
  static int gridColumns(BuildContext context) =>
      value<int>(context, mobile: 1, tablet: 2, desktop: 3);
}

/// Constrains page content to a readable width and centres it on large
/// screens, while keeping normal edge padding on phones.
class ResponsiveContainer extends StatelessWidget {
  const ResponsiveContainer({
    super.key,
    required this.child,
    this.maxWidth = AppSpacing.maxContentWidth,
    this.padding = const EdgeInsets.symmetric(
      horizontal: AppSpacing.pageHorizontal,
    ),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
