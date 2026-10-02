import 'package:flutter/material.dart';

import '../models/activity_model.dart';
import '../models/child_model.dart';
import '../models/location_model.dart';
import '../models/screen_time_model.dart';
import '../models/user_model.dart';
import '../services/activity_service.dart';
import '../services/family_session.dart';
import '../services/firestore_service.dart';
import '../services/location_service.dart';
import '../services/screen_time_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../utils/app_routes.dart';
import '../utils/firestore_codec.dart';

class ChildStatusCard extends StatelessWidget {
  const ChildStatusCard({
    super.key,
    required this.familyId,
    required this.child,
    required this.selected,
    this.showDivider = false,
  });

  final String familyId;
  final ChildModel child;
  final bool selected;
  final bool showDivider;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: <Widget>[
        InkWell(
          onTap: () {
            FamilySession.instance.selectChild(child.uid);
            Navigator.of(context).pushNamed(
              AppRoutes.childOverview,
              arguments: child.uid,
            );
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.lg,
              AppSpacing.md,
              AppSpacing.sm,
              AppSpacing.md,
            ),
            child: StreamBuilder<UserModel?>(
              stream: FirestoreService.instance.watchUserProfile(child.uid),
              builder:
                  (BuildContext context, AsyncSnapshot<UserModel?> profile) {
                return StreamBuilder<LocationModel?>(
                  stream: LocationService.instance.watchLatestForChild(
                    familyId: familyId,
                    childId: child.uid,
                  ),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<LocationModel?> loc,
                      ) {
                    return StreamBuilder<List<ActivityModel>>(
                      stream: ActivityService.instance.watchChildActivities(
                        familyId: familyId,
                        childId: child.uid,
                      ),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<List<ActivityModel>> acts,
                          ) {
                        return StreamBuilder<ScreenTimeModel?>(
                          stream: ScreenTimeService.instance.watchToday(
                            familyId: familyId,
                            childId: child.uid,
                          ),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<ScreenTimeModel?> time,
                              ) {
                            return _Body(
                              child: child,
                              selected: selected,
                              profile: profile.data,
                              location: loc.data,
                              activities:
                                  acts.data ?? const <ActivityModel>[],
                              screenTime: time.data,
                            );
                          },
                        );
                      },
                    );
                  },
                );
              },
            ),
          ),
        ),
        if (showDivider)
          const Divider(height: 1, indent: AppSpacing.lg, endIndent: AppSpacing.lg),
      ],
    );
  }
}

class _Body extends StatelessWidget {
  const _Body({
    required this.child,
    required this.selected,
    required this.profile,
    required this.location,
    required this.activities,
    required this.screenTime,
  });

  final ChildModel child;
  final bool selected;
  final UserModel? profile;
  final LocationModel? location;
  final List<ActivityModel> activities;
  final ScreenTimeModel? screenTime;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    final bool online = profile?.isOnline ?? false;
    final bool sharing = location?.sharingEnabled ?? false;
    final List<ActivityModel> today = activities
        .where((ActivityModel item) => item.isToday)
        .toList();
    final int done = today.where((ActivityModel item) => item.completed).length;
    final int used = screenTime?.totalMinutes ?? 0;
    final int limit = profile?.dailyScreenLimitMinutes ?? 120;

    return Row(
      children: <Widget>[
        CircleAvatar(
          backgroundColor: AppColors.sky.withValues(alpha: 0.22),
          child: Icon(
            Icons.child_care_outlined,
            color: AppColors.parentAccent,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(child.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: 2),
              Text(
                '${online ? 'Online' : 'Offline'}  ·  ${sharing ? 'Sharing on' : 'Sharing off'}',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: _Stat(
                      icon: Icons.task_alt_rounded,
                      label: today.isEmpty
                          ? 'No plan'
                          : '$done / ${today.length}',
                    ),
                  ),
                  Expanded(
                    child: _Stat(
                      icon: Icons.timelapse_outlined,
                      label: screenTime == null
                          ? 'No usage'
                          : '${formatMinutes(used)} / ${formatMinutes(limit)}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        Icon(
          selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
          color: selected
              ? AppColors.parentAccent
              : theme.colorScheme.outline,
        ),
      ],
    );
  }
}

class _Stat extends StatelessWidget {
  const _Stat({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 14, color: AppColors.parentAccent),
        const SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.labelMedium,
          ),
        ),
      ],
    );
  }
}
