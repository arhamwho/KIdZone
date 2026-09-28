import 'package:flutter/material.dart';

import '../models/activity_model.dart';
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
        background: activity.type.tint.withValues(alpha: 0.22),
        borderColor: Colors.transparent,
        child: Row(
          children: <Widget>[
            CircleAvatar(
              backgroundColor: theme.colorScheme.surface,
              child: Icon(activity.type.icon, color: activity.type.ink),
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
                    : Icons.schedule_rounded,
                color: activity.completed
                    ? activity.type.ink
                    : theme.colorScheme.onSurfaceVariant,
              ),
          ],
        ),
      ),
    );
  }
}
