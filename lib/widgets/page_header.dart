import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'feature_tile.dart';
import 'logout_button.dart';

/// One top bar for every signed-in screen: title on the left, logout
/// always on the right in the same 40×40 circle.
class AppTopBar extends StatelessWidget {
  const AppTopBar({
    super.key,
    required this.title,
    this.subtitle,
    this.avatarName,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final String? avatarName;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool canPop = Navigator.of(context).canPop();

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.lg),
      child: Row(
        children: <Widget>[
            if (canPop) ...<Widget>[
              const BackCircleButton(),
              const SizedBox(width: AppSpacing.md),
            ] else if (avatarName != null) ...<Widget>[
              PersonAvatar(name: avatarName!, size: PersonAvatar.header),
              const SizedBox(width: AppSpacing.md),
            ],
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: AppColors.inkSoft,
                      ),
                    ),
                ],
              ),
            ),
            ?trailing,
            const LogoutButton(),
          ],
        ),
    );
  }
}

/// Greeting-style heading used on dashboards.
class PageHeader extends StatelessWidget {
  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showLogout = true,
    this.trailing,
  });

  final String title;
  final String? subtitle;
  final bool showLogout;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      title: title,
      subtitle: subtitle,
      trailing: trailing,
    );
  }
}

/// Reference-style top bar: avatar, name, caption, logout.
class ProfileHeader extends StatelessWidget {
  const ProfileHeader({
    super.key,
    required this.name,
    this.caption,
    this.showLogout = true,
    this.trailing,
  });

  final String name;
  final String? caption;
  final bool showLogout;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return AppTopBar(
      title: name,
      subtitle: caption,
      avatarName: name,
      trailing: trailing,
    );
  }
}

/// Compact centred identity under the top bar.
class HeroIdentity extends StatelessWidget {
  const HeroIdentity({
    super.key,
    required this.name,
    this.caption,
    this.onTap,
  });

  final String name;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        children: <Widget>[
          PersonAvatar(name: name, size: PersonAvatar.hero),
          const SizedBox(height: AppSpacing.sm),
          Text(name, style: theme.textTheme.titleMedium),
          if (caption != null)
            Text(caption!, style: theme.textTheme.bodySmall),
        ],
      ),
    );
  }
}
