import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

/// White, deeply rounded surface with a soft drop shadow.
class KidCard extends StatelessWidget {
  const KidCard({
    super.key,
    required this.child,
    this.onTap,
    this.background,
    this.borderColor,
    this.padding = const EdgeInsets.all(AppSpacing.lg),
    this.radius = AppRadius.lg,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Color? background;
  final Color? borderColor;
  final EdgeInsetsGeometry padding;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final BorderRadius shape = BorderRadius.circular(radius);

    final Widget content = Padding(padding: padding, child: child);

    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: Color(0x14082A4D),
            blurRadius: 24,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: background ?? theme.colorScheme.surface,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: shape,
            border: borderColor == null ? null : Border.all(color: borderColor!),
          ),
          child: onTap == null
              ? content
              : InkWell(onTap: onTap, child: content),
        ),
      ),
    );
  }
}

class InsightTile {
  const InsightTile({
    required this.icon,
    required this.value,
    required this.label,
    this.color,
  });

  final IconData icon;
  final String value;
  final String label;
  final Color? color;
}

/// Compact stats used on dashboards instead of a second portrait.
class InsightCard extends StatelessWidget {
  const InsightCard({super.key, required this.tiles});

  final List<InsightTile> tiles;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      child: Row(
        children: <Widget>[
          for (int i = 0; i < tiles.length; i++) ...<Widget>[
            if (i > 0)
              Container(
                width: 1,
                height: 44,
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
            Expanded(child: _InsightCell(tile: tiles[i])),
          ],
        ],
      ),
    );
  }
}

class _InsightCell extends StatelessWidget {
  const _InsightCell({required this.tile});

  final InsightTile tile;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color color = tile.color ?? theme.colorScheme.primary;
    return Column(
      children: <Widget>[
        Icon(tile.icon, color: color),
        const SizedBox(height: AppSpacing.xs),
        Text(
          tile.value,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium,
        ),
        Text(
          tile.label,
          textAlign: TextAlign.center,
          style: theme.textTheme.bodySmall,
        ),
      ],
    );
  }
}

class SoftBadge extends StatelessWidget {
  const SoftBadge({
    super.key,
    required this.label,
    required this.background,
    required this.foreground,
    this.icon,
  });

  final String label;
  final Color background;
  final Color foreground;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppRadius.pill),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          if (icon != null) ...<Widget>[
            Icon(icon, size: 16, color: foreground),
            const SizedBox(width: AppSpacing.xs + 2),
          ],
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelMedium?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.action,
  });

  final String title;
  final String? subtitle;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(title, style: theme.textTheme.titleMedium),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: AppSpacing.xs),
                Text(subtitle!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        ?action,
      ],
    );
  }
}
