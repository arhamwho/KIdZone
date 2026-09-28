import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small decorative object orbiting an [IllustrationScene].
class IllustrationAccent {
  const IllustrationAccent({
    required this.icon,
    required this.color,
    required this.alignment,
  });

  final IconData icon;
  final Color color;
  final Alignment alignment;
}

/// KidZone's original illustration style: a soft pastel medallion with a
/// central subject and a few playful objects floating around it.
///
/// It is composed entirely from shapes and icons, so there are no image assets
/// to ship and it scales cleanly to any phone width.
class IllustrationScene extends StatelessWidget {
  const IllustrationScene({
    super.key,
    required this.icon,
    required this.color,
    this.accents = const <IllustrationAccent>[],
    this.iconColor,
    this.size = 240,
    this.accentScale = 0.21,
    this.animate = false,
  });

  final IconData icon;

  /// Pastel colour of the medallion rings.
  final Color color;

  /// Colour of the central subject. Defaults to the brand terracotta.
  final Color? iconColor;
  final List<IllustrationAccent> accents;
  final double size;

  /// Diameter of each orbiting bubble, as a fraction of [size].
  final double accentScale;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        // Never draw wider than the space we were given.
        final double s = math.min(
          size,
          constraints.maxWidth.isFinite ? constraints.maxWidth : size,
        );

        final Widget scene = SizedBox(
          width: s,
          height: s,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              _circle(s * 0.92, color.withValues(alpha: 0.30)),
              _circle(s * 0.72, color.withValues(alpha: 0.45)),
              _circle(s * 0.54, theme.colorScheme.surface),
              Icon(
                icon,
                size: s * 0.26,
                color: iconColor ?? AppColors.primary,
              ),
              for (final IllustrationAccent accent in accents)
                Align(
                  alignment: accent.alignment,
                  child: _AccentBubble(accent: accent, size: s * accentScale),
                ),
            ],
          ),
        );

        if (!animate) return scene;

        return TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0, end: 1),
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeOut,
          builder: (BuildContext context, double t, Widget? child) {
            return Opacity(opacity: t.clamp(0, 1), child: child);
          },
          child: scene,
        );
      },
    );
  }

  Widget _circle(double diameter, Color color) {
    return Container(
      width: diameter,
      height: diameter,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _AccentBubble extends StatelessWidget {
  const _AccentBubble({required this.accent, required this.size});

  final IllustrationAccent accent;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        shape: BoxShape.circle,
        border: Border.all(color: accent.color.withValues(alpha: 0.45), width: 2),
      ),
      child: Icon(accent.icon, size: size * 0.52, color: accent.color),
    );
  }
}
