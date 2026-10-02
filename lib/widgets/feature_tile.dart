import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'kid_face.dart';

/// Saturated rounded tile used for the Features grid.
class FeatureTile extends StatelessWidget {
  const FeatureTile({
    super.key,
    required this.color,
    required this.icon,
    required this.title,
    this.subtitle,
    this.onTap,
  });

  final Color color;
  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return KidFeatureSurface(
      color: color,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: Colors.white, size: 28),
          const Spacer(),
          Text(
            title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              color: Colors.white,
            ),
          ),
          if (subtitle != null) ...<Widget>[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Colors.white.withValues(alpha: 0.85),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class KidFeatureSurface extends StatelessWidget {
  const KidFeatureSurface({
    super.key,
    required this.color,
    required this.child,
    this.onTap,
  });

  final Color color;
  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final BorderRadius shape = BorderRadius.circular(AppRadius.lg);
    return Container(
      decoration: BoxDecoration(
        borderRadius: shape,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: color.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: color,
        borderRadius: shape,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: child,
          ),
        ),
      ),
    );
  }
}

/// Round shortcut under a child profile (Plan / Location / Screen).
class CircleAction extends StatelessWidget {
  const CircleAction({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = AppColors.primary,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.md),
      child: SizedBox(
        width: 84,
        child: Column(
          children: <Widget>[
            Container(
              height: 48,
              width: 48,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: const <BoxShadow>[
                  BoxShadow(
                    color: Color(0x14082A4D),
                    blurRadius: 16,
                    offset: Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(icon, color: color),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Named circular avatar used in headers and map pins.
class PersonAvatar extends StatelessWidget {
  const PersonAvatar({
    super.key,
    required this.name,
    this.size = header,
    this.selected = false,
  });

  static const double header = 40;
  static const double hero = 72;
  static const double chip = 44;
  static const double pin = 36;

  final String name;
  final double size;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: EdgeInsets.all(selected ? 3 : 0),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: selected
            ? Border.all(color: AppColors.primary, width: 3)
            : null,
        color: Colors.white,
      ),
      child: ClipOval(
        child: CustomPaint(
          size: Size.square(size),
          painter: KidFacePainter(name.hashCode),
        ),
      ),
    );
  }
}
