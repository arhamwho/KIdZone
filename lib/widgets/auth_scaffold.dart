import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';
import '../utils/responsive.dart';
import 'kidzone_mark.dart';
import 'soft_background.dart';

/// Shared chrome for login and register so both screens sit in the same
/// onboarding-style cream canvas.
class AuthScaffold extends StatelessWidget {
  const AuthScaffold({
    super.key,
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

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
                  padding: const EdgeInsets.symmetric(
                    vertical: AppSpacing.xl,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight - AppSpacing.xl * 2,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: <Widget>[
                        const Center(
                          child: KidZoneMark(size: 96, showWordmark: false),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        Text(
                          title,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        child,
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
}
