import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// Pill-shaped primary action button with an optional trailing icon.
///
/// Wraps Material 3's [FilledButton]; the rounded look comes from the theme.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.expand = false,
    this.color,
    this.compact = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  /// Stretch to the full width of the parent — the usual choice on a phone.
  final bool expand;

  final Color? color;

  /// Slightly shorter pill, used where a full 56dp bar would dominate.
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final ButtonStyle style = FilledButton.styleFrom(
      backgroundColor: color,
      minimumSize: Size(0, compact ? 52 : 56),
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppSpacing.xl : AppSpacing.xxl,
      ),
    );

    final Widget button = icon == null
        ? FilledButton(
            onPressed: onPressed,
            style: style,
            child: Text(label, overflow: TextOverflow.ellipsis),
          )
        : FilledButton.icon(
            onPressed: onPressed,
            style: style,
            iconAlignment: IconAlignment.end,
            icon: Icon(icon, size: 18),
            label: Text(label, overflow: TextOverflow.ellipsis),
          );

    return expand ? SizedBox(width: double.infinity, child: button) : button;
  }
}

/// Quieter companion to [PrimaryButton], used for Back and Skip actions.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 20),
            const SizedBox(width: AppSpacing.sm),
          ],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis)),
        ],
      ),
    );
  }
}
