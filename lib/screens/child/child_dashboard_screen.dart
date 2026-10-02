import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/game_progress_model.dart';
import '../../models/location_model.dart';
import '../../models/points_model.dart';
import '../../models/screen_time_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../services/game_service.dart';
import '../../services/location_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/family_tools.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/role_shell.dart';
import '../../widgets/status_views.dart';

class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.child.tint,
      actions: const <Widget>[],
      builder: (BuildContext context, FamilyScope scope) {
        final String childId = scope.user.uid;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
          children: <Widget>[
            ProfileHeader(
              name: scope.user.name,
              caption: 'Ready for a good day?',
            ),
            StreamBuilder<PointsModel>(
              stream: GameService.instance.watchPoints(
                familyId: scope.familyId,
                childId: childId,
              ),
              builder: (BuildContext context, AsyncSnapshot<PointsModel> pts) {
                return StreamBuilder<ScreenTimeModel?>(
                  stream: ScreenTimeService.instance.watchToday(
                    familyId: scope.familyId,
                    childId: childId,
                  ),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<ScreenTimeModel?> time,
                      ) {
                    final PointsModel points =
                        pts.data ?? PointsModel.empty(childId);
                    final ScreenTimeModel? usage = time.data;
                    return InsightCard(
                      tiles: <InsightTile>[
                        InsightTile(
                          icon: Icons.star_rounded,
                          value: '${points.points}',
                          label: 'Level ${points.level}',
                          color: AppColors.tileOrange,
                        ),
                        InsightTile(
                          icon: Icons.timelapse_rounded,
                          value: usage == null
                              ? '—'
                              : formatHoursMinutes(usage.totalMinutes),
                          label: 'screen time',
                          color: AppColors.tileBlue,
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: <Widget>[
                CircleAction(
                  icon: Icons.checklist_outlined,
                  label: 'Plan',
                  color: AppColors.childAccent,
                  onTap: () => ShellTabs.maybeOf(context)?.onSelect(1),
                ),
                CircleAction(
                  icon: Icons.timelapse_outlined,
                  label: 'Screen',
                  color: AppColors.childAccent,
                  onTap: () => ShellTabs.maybeOf(context)?.onSelect(2),
                ),
                CircleAction(
                  icon: Icons.person_outline_rounded,
                  label: 'Profile',
                  color: AppColors.childAccent,
                  onTap: () => ShellTabs.maybeOf(context)?.onSelect(4),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Features'),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<LocationModel?>(
              stream: LocationService.instance.watchLatestForChild(
                familyId: scope.familyId,
                childId: childId,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<LocationModel?> loc) {
                final bool sharing =
                    loc.data?.sharingEnabled ??
                    scope.user.locationSharingEnabled;
                return GridView.count(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  childAspectRatio: 1.08,
                  children: <Widget>[
                    FeatureTile(
                      color: AppColors.tileBlue,
                      icon: Icons.checklist_rounded,
                      title: 'Activities',
                      subtitle: 'Today’s plan',
                      onTap: () => ShellTabs.maybeOf(context)?.onSelect(1),
                    ),
                    FeatureTile(
                      color: AppColors.tileOrange,
                      icon: Icons.timelapse_rounded,
                      title: 'Screen Time',
                      subtitle: 'Today’s usage',
                      onTap: () => ShellTabs.maybeOf(context)?.onSelect(2),
                    ),
                    FeatureTile(
                      color: AppColors.tilePurple,
                      icon: Icons.extension_rounded,
                      title: 'Games',
                      subtitle: 'Play & earn',
                      onTap: () => ShellTabs.maybeOf(context)?.onSelect(3),
                    ),
                    FeatureTile(
                      color: AppColors.tileGreen,
                      icon: Icons.gps_fixed_rounded,
                      title: 'GPS',
                      subtitle: sharing ? 'Sharing on' : 'Sharing off',
                      onTap: () => ShellTabs.maybeOf(context)?.onSelect(4),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            const FamilyToolsCard(),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(title: 'Today’s activities'),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<List<ActivityModel>>(
              stream: ActivityService.instance.watchChildActivities(
                familyId: scope.familyId,
                childId: childId,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<List<ActivityModel>> snap) {
                if (snap.hasError) {
                  return const Text('Unable to load your activities.');
                }
                if (!snap.hasData) return const LoadingView();
                final List<ActivityModel> today = snap.data!
                    .where((ActivityModel item) => item.isToday)
                    .toList();
                if (today.isEmpty) {
                  return const KidCard(
                    child: Text('No activities scheduled yet.'),
                  );
                }
                final int done =
                    today.where((ActivityModel item) => item.completed).length;
                return Column(
                  children: <Widget>[
                    Text(
                      '$done of ${today.length} done',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    for (final ActivityModel activity in today.take(3))
                      ActivityTile(
                        activity: activity,
                        canComplete: true,
                        onToggle: (bool value) {
                          ActivityService.instance.setCompleted(
                            familyId: scope.familyId,
                            activity: activity,
                            completed: value,
                          );
                        },
                      ),
                    TextButton(
                      onPressed: () => ShellTabs.maybeOf(context)?.onSelect(1),
                      child: const Text('See all activities'),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<List<GameProgressModel>>(
              stream: GameService.instance.watchChildProgress(
                familyId: scope.familyId,
                childId: childId,
              ),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<GameProgressModel>> snap,
                  ) {
                final List<GameProgressModel> games =
                    snap.data ?? <GameProgressModel>[];
                final int done = games
                    .where((GameProgressModel item) => item.completed)
                    .length;
                return KidCard(
                  onTap: () =>
                      Navigator.of(context).pushNamed(AppRoutes.achievements),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: const Text('Achievements'),
                    subtitle: Text(
                      games.isEmpty
                          ? 'Play your first game to start building your progress.'
                          : '$done games completed',
                    ),
                    trailing: const Icon(Icons.chevron_right_rounded),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }
}
