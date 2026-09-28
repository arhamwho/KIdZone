import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/game_progress_model.dart';
import '../../models/points_model.dart';
import '../../models/screen_time_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../services/game_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/role_shell.dart';

class ChildDashboardScreen extends StatelessWidget {
  const ChildDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'My Dashboard',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        final String childId = scope.user.uid;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            KidCard(
              background: AppColors.peach.withValues(alpha: 0.28),
              borderColor: Colors.transparent,
              child: Text(
                'Hello, ${scope.user.name}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
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
                    final int used = time.data?.totalMinutes ?? 0;
                    final int limit = scope.user.dailyScreenLimitMinutes;
                    return Row(
                      children: <Widget>[
                        Expanded(
                          child: KidCard(
                            child: ProgressRing(
                              value: (points.points % 50) / 50,
                              label: '${points.points}',
                              caption: 'Level ${points.level}',
                              color: UserRole.child.accent,
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(
                          child: KidCard(
                            child: ProgressRing(
                              value: limit == 0 ? 0 : used / limit,
                              label: '$used m',
                              caption: 'screen time',
                              color: AppColors.parentAccent,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Today’s activities',
              subtitle: 'Tick them off as you go.',
            ),
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
                final List<ActivityModel> today = (snap.data ?? <ActivityModel>[])
                    .where((ActivityModel item) => item.isToday)
                    .toList();
                if (today.isEmpty) {
                  return const KidCard(
                    child: Text('No activities planned for today. Enjoy some play time!'),
                  );
                }
                return Column(
                  children: <Widget>[
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
            KidCard(
              onTap: () => ShellTabs.maybeOf(context)?.onSelect(2),
              child: const ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(Icons.extension_outlined),
                title: Text('Play a learning game'),
                trailing: Icon(Icons.chevron_right_rounded),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
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
                final int done = (snap.data ?? <GameProgressModel>[])
                    .where((GameProgressModel item) => item.completed)
                    .length;
                return KidCard(
                  onTap: () => ShellTabs.maybeOf(context)?.onSelect(3),
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: const Text('Achievements'),
                    subtitle: Text('$done games completed'),
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
