import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../utils/responsive.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/kidzone_mark.dart';
import '../../widgets/soft_background.dart';

/// Role picker shown after onboarding. Choosing here decides which dashboard
/// and navigation tree the user lands in.
class RoleSelectionScreen extends StatelessWidget {
  const RoleSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool isWide = !Responsive.isMobile(context);

    return SoftBackground(
      showDecorations: false,
      quiet: true,
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: SafeArea(
          child: ResponsiveContainer(
            child: LayoutBuilder(
              builder: (BuildContext context, BoxConstraints constraints) {
                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.xl),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.xl * 2,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Center(
                          child: KidZoneMark(size: 96, showWordmark: false),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          'Welcome to KidZone',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Who is using the app today?',
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xxl),
                        if (isWide)
                          IntrinsicHeight(
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: <Widget>[
                                Expanded(
                                  child: _roleCard(context, UserRole.parent),
                                ),
                                const SizedBox(width: AppSpacing.lg),
                                Expanded(
                                  child: _roleCard(context, UserRole.child),
                                ),
                              ],
                            ),
                          )
                        else
                          Column(
                            children: <Widget>[
                              _roleCard(context, UserRole.parent),
                              const SizedBox(height: AppSpacing.lg),
                              _roleCard(context, UserRole.child),
                            ],
                          ),
                        const SizedBox(height: AppSpacing.xxl),
                        Center(
                          child: TextButton.icon(
                            onPressed: () =>
                                Navigator.of(context)
                                    .pushNamed(AppRoutes.login),
                            icon: const Icon(
                              Icons.lock_outline_rounded,
                              size: 18,
                            ),
                            label: const Text('Sign in to a family account'),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _roleCard(BuildContext context, UserRole role) {
    return _RoleCard(
      role: role,
      onTap: () => Navigator.of(context).pushNamed(
        role == UserRole.parent ? AppRoutes.parentHome : AppRoutes.childHome,
      ),
    );
  }
}

class _RoleCard extends StatelessWidget {
  const _RoleCard({required this.role, required this.onTap});

  final UserRole role;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final Color tint = role == UserRole.parent
        ? AppColors.sky.withValues(alpha: 0.22)
        : AppColors.peach.withValues(alpha: 0.38);

    // Compact horizontal card so both roles fit on a small phone screen.
    return KidCard(
      onTap: onTap,
      background: tint,
      borderColor: Colors.transparent,
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Row(
        children: <Widget>[
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              shape: BoxShape.circle,
            ),
            child: Icon(role.icon, color: role.accent, size: 30),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  'I am a ${role.label}',
                  style: theme.textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  role.description,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(Icons.chevron_right_rounded, color: role.accent),
        ],
      ),
    );
  }
}
