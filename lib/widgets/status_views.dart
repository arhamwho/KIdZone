import 'package:flutter/material.dart';

import '../theme/app_spacing.dart';

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(child: CircularProgressIndicator());
  }
}

class MessageView extends StatelessWidget {
  const MessageView(this.text, {super.key, this.icon, this.onRetry});

  final String text;
  final IconData? icon;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            if (icon != null) ...<Widget>[
              Icon(icon, size: 36, color: theme.colorScheme.onSurfaceVariant),
              const SizedBox(height: AppSpacing.md),
            ],
            Text(text, textAlign: TextAlign.center, style: theme.textTheme.bodyMedium),
            if (onRetry != null) ...<Widget>[
              const SizedBox(height: AppSpacing.md),
              TextButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
