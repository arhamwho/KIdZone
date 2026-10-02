import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/child_model.dart';
import '../../models/family_model.dart';
import '../../models/screen_time_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/family_tools.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/role_shell.dart';
import '../../widgets/usage_rows.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.parent.tint,
      actions: const <Widget>[],
      builder: (BuildContext context, FamilyScope scope) {
        return StreamBuilder<FamilyModel?>(
          stream: FirestoreService.instance.watchFamily(scope.familyId),
          builder: (BuildContext context, AsyncSnapshot<FamilyModel?> family) {
            final String familyName =
                family.data?.familyName ?? "${scope.user.name}'s family";
            final ChildModel? child = scope.selectedChild;

            if (child == null) {
              return ListView(
                padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
                children: <Widget>[
                  ProfileHeader(
                    name: scope.user.name,
                    caption: familyName,
                  ),
                  KidCard(
                    child: Text(
                      'Add a child to see their plan, location and screen time here.',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xl),
                  PrimaryButton(
                    label: 'Add child',
                    onPressed: () =>
                        Navigator.of(context).pushNamed(AppRoutes.addChild),
                  ),
                ],
              );
            }

            return StreamBuilder<ScreenTimeModel?>(
              stream: ScreenTimeService.instance.watchToday(
                familyId: scope.familyId,
                childId: child.uid,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<ScreenTimeModel?> time) {
                return StreamBuilder<List<ActivityModel>>(
                  stream: ActivityService.instance.watchChildActivities(
                    familyId: scope.familyId,
                    childId: child.uid,
                  ),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<List<ActivityModel>> acts,
                      ) {
                    final ScreenTimeModel? usage = time.data;
                    final List<ActivityModel> activities =
                        acts.data ?? const <ActivityModel>[];
                    final int todayCount = activities
                        .where((ActivityModel item) => item.isToday)
                        .length;
                    final int used = usage?.totalMinutes ?? 0;

                    return ListView(
                      padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
                      children: <Widget>[
                        ProfileHeader(
                          name: scope.user.name,
                          caption: familyName,
                        ),
                        if (scope.children.length > 1) ...<Widget>[
                          ChildPicker(
                            children: scope.children,
                            selectedId: child.uid,
                            onSelected: FamilySession.instance.selectChild,
                          ),
                          const SizedBox(height: AppSpacing.lg),
                        ],
                        KidCard(
                          onTap: () {
                            FamilySession.instance.selectChild(child.uid);
                            Navigator.of(context).pushNamed(
                              AppRoutes.childOverview,
                              arguments: child.uid,
                            );
                          },
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: PersonAvatar(
                              name: child.name,
                              size: PersonAvatar.header,
                            ),
                            title: Text(child.name),
                            subtitle: Text(
                              usage == null
                                  ? 'No screen time yet today'
                                  : formatHoursMinutes(used),
                            ),
                            trailing: const Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        InsightCard(
                          tiles: <InsightTile>[
                            InsightTile(
                              icon: Icons.event_available_rounded,
                              value: todayCount == 0 ? '—' : '$todayCount',
                              label: 'today’s plan',
                              color: AppColors.tileBlue,
                            ),
                            InsightTile(
                              icon: Icons.timelapse_rounded,
                              value: usage == null
                                  ? '—'
                                  : formatHoursMinutes(used),
                              label: 'screen time',
                              color: AppColors.tileOrange,
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: <Widget>[
                            CircleAction(
                              icon: Icons.event_note_outlined,
                              label: 'Plan',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(1),
                            ),
                            CircleAction(
                              icon: Icons.location_on_outlined,
                              label: 'Location',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(2),
                            ),
                            CircleAction(
                              icon: Icons.timelapse_outlined,
                              label: 'Screen',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(3),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        const SectionHeader(title: 'Features'),
                        const SizedBox(height: AppSpacing.md),
                        GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: 2,
                          mainAxisSpacing: AppSpacing.md,
                          crossAxisSpacing: AppSpacing.md,
                          childAspectRatio: 1.08,
                          children: <Widget>[
                            FeatureTile(
                              color: AppColors.tileBlue,
                              icon: Icons.event_available_rounded,
                              title: 'Activities',
                              subtitle: todayCount == 0
                                  ? 'No plan today'
                                  : '$todayCount today',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(1),
                            ),
                            FeatureTile(
                              color: AppColors.tileOrange,
                              icon: Icons.apps_rounded,
                              title: 'Screen Time',
                              subtitle: usage == null
                                  ? 'Waiting for usage'
                                  : formatHoursMinutes(used),
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(3),
                            ),
                            FeatureTile(
                              color: AppColors.tilePurple,
                              icon: Icons.shield_moon_rounded,
                              title: 'Learning',
                              subtitle: 'Quizzes & points',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(4),
                            ),
                            FeatureTile(
                              color: AppColors.tileGreen,
                              icon: Icons.gps_fixed_rounded,
                              title: 'GPS',
                              subtitle: 'Live location',
                              onTap: () =>
                                  ShellTabs.maybeOf(context)?.onSelect(2),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        const FamilyToolsCard(),
                        const SizedBox(height: AppSpacing.lg),
                        KidCard(
                          onTap: () =>
                              Navigator.of(context).pushNamed(AppRoutes.addChild),
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.lg,
                            vertical: AppSpacing.md,
                          ),
                          child: const ListTile(
                            contentPadding: EdgeInsets.zero,
                            leading: Icon(
                              Icons.add_rounded,
                              color: AppColors.parentAccent,
                            ),
                            title: Text('Add child'),
                            trailing: Icon(Icons.chevron_right_rounded),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.lg),
                        RecentActivityCard(
                          usage: usage,
                          activities: activities,
                          onViewAll: () =>
                              ShellTabs.maybeOf(context)?.onSelect(3),
                        ),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }
}
