import 'package:flutter/material.dart';

/// Quiet sky wash so white cards float like the reference screens.
class SoftBackground extends StatelessWidget {
  const SoftBackground({
    super.key,
    required this.child,
    this.tint,
    this.showDecorations = true,
    this.quiet = false,
  });

  final Widget child;
  final Color? tint;
  final bool showDecorations;
  final bool quiet;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color base = theme.scaffoldBackgroundColor;
    final Color wash = tint == null
        ? base
        : Color.alphaBlend(tint!.withValues(alpha: 0.18), base);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: base,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: <Color>[
            showDecorations || quiet ? wash : base,
            base,
            base,
          ],
        ),
      ),
      child: child,
    );
  }
}
