import 'package:flutter/material.dart';

import '../models/screen_time_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/firestore_codec.dart';
import 'kid_card.dart';
import 'usage_rows.dart';

class ScreenTimeSummary extends StatelessWidget {
  const ScreenTimeSummary({
    super.key,
    required this.used,
    required this.limit,
    required this.hasRecord,
    this.updatedAt,
    this.friendly = false,
    this.demo = false,
  });

  final int used;
  final int limit;
  final bool hasRecord;
  final DateTime? updatedAt;
  final bool friendly;
  final bool demo;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final int remaining = (limit - used).clamp(0, limit);
    final double raw = limit == 0 ? 0 : used / limit;
    final ScreenTimeLevel level = !hasRecord
        ? ScreenTimeLevel.empty
        : raw > 1
        ? ScreenTimeLevel.exceeded
        : raw >= 0.75
        ? ScreenTimeLevel.warning
        : ScreenTimeLevel.normal;
    final Color barColor = switch (level) {
      ScreenTimeLevel.exceeded => AppColors.danger,
      ScreenTimeLevel.warning => AppColors.warning,
      ScreenTimeLevel.normal => AppColors.primary,
      ScreenTimeLevel.empty => AppColors.primary,
    };
    final String status = switch (level) {
      ScreenTimeLevel.empty => friendly
          ? 'Ask a grown-up to help turn on Screen Time.'
          : 'Waiting for today’s usage',
      ScreenTimeLevel.exceeded => friendly
          ? 'That’s more than today’s limit.'
          : 'Daily limit exceeded',
      ScreenTimeLevel.warning => friendly
          ? 'Almost at today’s limit.'
          : 'Approaching today’s limit',
      ScreenTimeLevel.normal => friendly
          ? '${formatHoursMinutes(remaining)} left to play'
          : '${formatHoursMinutes(remaining)} remaining',
    };

    return KidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Today’s Screen Time',
            style: theme.textTheme.titleSmall,
          ),
          if (demo) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text('Demo usage', style: theme.textTheme.bodySmall),
          ],
          const SizedBox(height: AppSpacing.sm),
          Text(
            hasRecord ? formatHoursMinutes(used) : '—',
            style: theme.textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          _Fact(label: 'Daily limit', value: formatHoursMinutes(limit)),
          _Fact(
            label: 'Remaining',
            value: hasRecord ? formatHoursMinutes(remaining) : '—',
          ),
          const SizedBox(height: AppSpacing.md),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppRadius.pill),
            child: LinearProgressIndicator(
              value: hasRecord ? raw.clamp(0, 1) : 0,
              minHeight: 10,
              color: barColor,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(status, style: theme.textTheme.bodySmall),
          if (updatedAt != null) ...<Widget>[
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Updated ${formatRelative(updatedAt!)}',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(label, style: Theme.of(context).textTheme.bodySmall),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class ScreenTimeAppList extends StatelessWidget {
  const ScreenTimeAppList({
    super.key,
    required this.apps,
    this.emptyLabel = 'No app breakdown yet for today.',
  });

  final List<AppUsageModel> apps;
  final String emptyLabel;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('App Usage', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          if (apps.isEmpty)
            Text(emptyLabel, style: Theme.of(context).textTheme.bodySmall)
          else
            for (final AppUsageModel item in apps)
              AppUsageRow(item: item),
        ],
      ),
    );
  }
}

class UsageAccessCard extends StatelessWidget {
  const UsageAccessCard({
    super.key,
    required this.onEnable,
    this.friendly = false,
  });

  final VoidCallback onEnable;
  final bool friendly;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: <Widget>[
          Text(
            'Screen Time Access',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            friendly
                ? 'KidZone needs Usage Access permission to calculate today’s screen time. A grown-up can turn this on in Android settings.'
                : 'Screen-time access is not enabled. KidZone needs Usage Access permission to calculate today’s screen time.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          FilledButton(
            onPressed: onEnable,
            child: const Text('Enable Screen Time'),
          ),
        ],
      ),
    );
  }
}
