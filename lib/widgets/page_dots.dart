import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Minimal onboarding indicator: a short dash for the active page and a
/// quiet dot for the rest.
class PageDots extends StatelessWidget {
  const PageDots({
    super.key,
    required this.count,
    required this.activeIndex,
    this.activeColor,
  });

  final int count;
  final int activeIndex;
  final Color? activeColor;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color active = activeColor ?? theme.colorScheme.primary;
    final Color inactive = theme.colorScheme.onSurface.withValues(alpha: 0.18);

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: <Widget>[
        for (int i = 0; i < count; i++)
          AnimatedContainer(
            duration: const Duration(milliseconds: 240),
            curve: Curves.easeOut,
            margin: const EdgeInsets.symmetric(horizontal: AppSpacing.xs),
            height: 6,
            width: i == activeIndex ? 20 : 6,
            decoration: BoxDecoration(
              color: i == activeIndex ? active : inactive,
              borderRadius: BorderRadius.circular(AppRadius.pill),
            ),
          ),
      ],
    );
  }
}
