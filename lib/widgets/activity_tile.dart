import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import 'kid_card.dart';

class ActivityTile extends StatelessWidget {
  const ActivityTile({
    super.key,
    required this.activity,
    this.childName,
    this.onToggle,
    this.canComplete = false,
  });

  final ActivityModel activity;
  final String? childName;
  final ValueChanged<bool>? onToggle;
  final bool canComplete;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
        child: KidCard(
        onTap: () => _showDetails(context),
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: activity.type.tint,
              child: Icon(activity.type.icon, color: Colors.white),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(activity.title, style: theme.textTheme.titleSmall),
                  const SizedBox(height: 2),
                  Text(
                    [
                      activity.type.label,
                      '${activity.startTime}–${activity.endTime}',
                      ?childName,
                    ].join(' · '),
                    style: theme.textTheme.bodySmall,
                  ),
                  if (activity.description.isNotEmpty) ...<Widget>[
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      activity.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
            if (canComplete && onToggle != null)
              Checkbox(
                value: activity.completed,
                onChanged: (bool? value) => onToggle!(value ?? false),
              )
            else
              Icon(
                activity.completed
                    ? Icons.check_circle_rounded
                    : Icons.chevron_right_rounded,
                color: activity.completed
                    ? AppColors.tileGreen
                    : theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      builder: (BuildContext context) {
        return Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(activity.title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: AppSpacing.sm),
              Text(
                '${activity.type.label} · ${activity.startTime}–${activity.endTime}',
              ),
              if (activity.description.isNotEmpty) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(activity.description),
              ],
              const SizedBox(height: AppSpacing.md),
              Text(
                activity.completed
                    ? 'Completed'
                    : 'Not completed yet',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
          ),
        );
      },
    );
  }
}
