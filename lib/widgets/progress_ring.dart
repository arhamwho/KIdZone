import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Circular progress dial with a value in the middle.
///
/// The ring animates up from zero the first time it is shown, which gives the
/// dashboards a little life without any looping animation.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    this.label,
    this.caption,
    this.size = 104,
    this.strokeWidth = 11,
    this.color,
  });

  /// Completion between 0 and 1.
  final double value;

  /// Big text in the centre. Defaults to the value as a percentage.
  final String? label;

  final String? caption;
  final double size;
  final double strokeWidth;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color ringColor = color ?? theme.colorScheme.primary;
    final double target = value.clamp(0.0, 1.0);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: target),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (BuildContext context, double animated, Widget? child) {
        return SizedBox(
          width: size,
          height: size,
          child: Stack(
            alignment: Alignment.center,
            children: <Widget>[
              SizedBox.expand(
                child: CircularProgressIndicator(
                  value: animated,
                  strokeWidth: strokeWidth,
                  strokeCap: StrokeCap.round,
                  color: ringColor,
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  Text(
                    label ?? '${(animated * 100).round()}%',
                    style: theme.textTheme.titleMedium,
                  ),
                  if (caption != null) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs / 2),
                    Text(
                      caption!,
                      style: theme.textTheme.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}
