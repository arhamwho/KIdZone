import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../models/screen_time_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'kid_card.dart';

class AppGlyph extends StatelessWidget {
  const AppGlyph({super.key, required this.name, this.size = 40});

  final String name;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: size,
      width: size,
      decoration: BoxDecoration(
        color: tintFor(name),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconFor(name), color: Colors.white, size: size * 0.5),
    );
  }

  static Color tintFor(String name) {
    final String key = name.toLowerCase();
    if (key.contains('youtube')) return const Color(0xFFFF3B30);
    if (key.contains('instagram')) return const Color(0xFFE1306C);
    if (key.contains('farm') || key.contains('game')) {
      return const Color(0xFFFF8A00);
    }
    if (key.contains('tiktok')) return const Color(0xFF111111);
    if (key.contains('chrome') || key.contains('safari')) {
      return AppColors.tileBlue;
    }
    return AppColors.avatarColor(name);
  }

  static IconData iconFor(String name) {
    final String key = name.toLowerCase();
    if (key.contains('youtube')) return Icons.play_arrow_rounded;
    if (key.contains('instagram')) return Icons.camera_alt_rounded;
    if (key.contains('farm') || key.contains('game')) {
      return Icons.sports_esports_rounded;
    }
    if (key.contains('chrome') || key.contains('safari')) {
      return Icons.language_rounded;
    }
    return Icons.apps_rounded;
  }
}

class AppUsageRow extends StatelessWidget {
  const AppUsageRow({super.key, required this.item});

  final AppUsageItem item;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: <Widget>[
          AppGlyph(name: item.name),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(item.name, style: theme.textTheme.titleSmall),
                Text(
                  '${item.minutes} min',
                  style: theme.textTheme.bodySmall,
                ),
              ],
            ),
          ),
          Text(
            '${item.minutes} min',
            style: theme.textTheme.labelMedium?.copyWith(
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class RecentActivityCard extends StatelessWidget {
  const RecentActivityCard({
    super.key,
    this.usage,
    this.activities = const <ActivityModel>[],
    this.onViewAll,
  });

  final ScreenTimeModel? usage;
  final List<ActivityModel> activities;
  final VoidCallback? onViewAll;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final List<AppUsageItem> apps = usage?.appUsage ?? const <AppUsageItem>[];
    final List<ActivityModel> today = activities
        .where((ActivityModel item) => item.isToday)
        .toList();

    return KidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Expanded(
                child: Text(
                  'Recent Activity',
                  style: theme.textTheme.titleMedium,
                ),
              ),
              if (onViewAll != null)
                IconButton(
                  onPressed: onViewAll,
                  icon: const Icon(Icons.chevron_right_rounded),
                ),
            ],
          ),
          if (apps.isNotEmpty)
            ...apps.take(4).map((AppUsageItem item) {
              return AppUsageRow(item: item);
            })
          else if (today.isNotEmpty)
            ...today.take(4).map((ActivityModel item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    AppGlyph(name: item.title),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(item.title, style: theme.textTheme.titleSmall),
                          Text(
                            '${item.startTime} · ${item.type.label}',
                            style: theme.textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Icon(
                      Icons.chevron_right_rounded,
                      color: theme.colorScheme.outline,
                    ),
                  ],
                ),
              );
            })
          else
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Text(
                'No recent activity yet.',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ),
    );
  }
}
