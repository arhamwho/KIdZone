import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'app_page.dart';
import 'illustration_scene.dart';
import 'kid_card.dart';

/// Temporary page used by features that are not implemented yet.
///
/// It already uses the real design language — pastel canvas, medallion
/// illustration, rounded type — so each feature can be filled in without
/// changing how it looks.
class PlaceholderScreen extends StatelessWidget {
  const PlaceholderScreen({
    super.key,
    required this.title,
    required this.icon,
    required this.description,
    this.tint,
    this.iconColor,
    this.actions,
  });

  final String title;
  final IconData icon;
  final String description;

  /// Pastel colour for the background blob and the illustration medallion.
  final Color? tint;

  /// Stronger colour for the central icon.
  final Color? iconColor;
  final List<Widget>? actions;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color medallion = tint ?? AppColors.peach;

    return AppPage(
      title: title,
      tint: medallion,
      actions: actions,
      child: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          final double artSize = math.min(constraints.maxWidth * 0.60, 200.0);

          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  IllustrationScene(
                    icon: icon,
                    color: medallion,
                    iconColor: iconColor,
                    size: artSize,
                    accents: const <IllustrationAccent>[],
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.headlineSmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text(
                    description,
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  const SoftBadge(
                    label: 'Coming soon',
                    icon: Icons.auto_awesome,
                    background: AppColors.sand,
                    foreground: AppColors.primary,
                  ),
                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
