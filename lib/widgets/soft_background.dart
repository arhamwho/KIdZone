import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The warm pastel canvas every KidZone screen sits on.
///
/// It paints a few very low-opacity blobs and scatters small decorative
/// shapes (stars, clouds, sparkles). Everything is drawn from the widget's own
/// size, so it adapts to any phone width without hard-coded offsets.
class SoftBackground extends StatelessWidget {
  const SoftBackground({
    super.key,
    required this.child,
    this.tint,
    this.showDecorations = true,
    this.quiet = false,
  });

  final Widget child;

  /// Optional colour for the largest blob, used to give each section of the
  /// app a slightly different mood.
  final Color? tint;

  final bool showDecorations;

  /// Softer, corner-only blobs so the centre of the screen stays clear for
  /// copy and actions. Used by onboarding; other screens keep the richer look.
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isLight = theme.brightness == Brightness.light;
    final Color blobTint = tint ?? AppColors.peach;

    return DecoratedBox(
      decoration: BoxDecoration(color: theme.scaffoldBackgroundColor),
      child: Stack(
        children: <Widget>[
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _BlobPainter(
                  tint: blobTint,
                  opacity: isLight ? 1.0 : 0.35,
                  quiet: quiet,
                ),
              ),
            ),
          ),
          if (showDecorations)
            const Positioned.fill(child: IgnorePointer(child: _Decorations())),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

/// Three soft shapes that give the background depth without gradients.
class _BlobPainter extends CustomPainter {
  const _BlobPainter({
    required this.tint,
    required this.opacity,
    required this.quiet,
  });

  final Color tint;
  final double opacity;
  final bool quiet;

  @override
  void paint(Canvas canvas, Size size) {
    void blob(Color color, double alpha, Offset center, double radius) {
      canvas.drawCircle(
        center,
        radius,
        Paint()..color = color.withValues(alpha: alpha * opacity),
      );
    }

    if (quiet) {
      // Stay in the corners, well away from the heading, copy and CTA.
      blob(
        tint,
        0.16,
        Offset(size.width * 1.12, -size.height * 0.14),
        size.width * 0.36,
      );
      blob(
        AppColors.sunshine,
        0.09,
        Offset(-size.width * 0.22, size.height * 0.04),
        size.width * 0.24,
      );
      return;
    }

    blob(
      tint,
      0.38,
      Offset(size.width * 1.02, -size.height * 0.02),
      size.width * 0.62,
    );
    blob(
      AppColors.sunshine,
      0.20,
      Offset(-size.width * 0.12, size.height * 0.16),
      size.width * 0.40,
    );
    blob(
      AppColors.blush,
      0.16,
      Offset(size.width * 0.10, size.height * 1.04),
      size.width * 0.52,
    );
  }

  @override
  bool shouldRepaint(_BlobPainter oldDelegate) =>
      oldDelegate.tint != tint ||
      oldDelegate.opacity != opacity ||
      oldDelegate.quiet != quiet;
}

/// Small playful objects dotted around the edges of the screen.
class _Decorations extends StatelessWidget {
  const _Decorations();

  static const List<(Alignment, IconData, Color, double)> _shapes =
      <(Alignment, IconData, Color, double)>[
        (Alignment(-0.88, -0.78), Icons.star_rounded, AppColors.sunshine, 18),
        (Alignment(0.78, -0.62), Icons.cloud_rounded, AppColors.sky, 24),
        (Alignment(0.92, 0.34), Icons.auto_awesome, AppColors.lavender, 16),
        (Alignment(-0.82, 0.58), Icons.circle, AppColors.mint, 12),
        (Alignment(0.10, 0.94), Icons.star_rounded, AppColors.blush, 14),
      ];

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: <Widget>[
        for (final (Alignment a, IconData i, Color c, double s) shape in _shapes)
          Align(
            alignment: shape.$1,
            child: Icon(
              shape.$2,
              size: shape.$4,
              color: shape.$3.withValues(alpha: 0.55),
            ),
          ),
      ],
    );
  }
}
