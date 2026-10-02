import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/child_model.dart';
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
import '../../utils/firestore_codec.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/feature_tile.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';

class ChildOverviewScreen extends StatelessWidget {
  const ChildOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String? childId = args is String ? args : null;

    return FamilyGate(
      title: '',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        ChildModel? child;
        for (final ChildModel item in scope.children) {
          if (item.uid == (childId ?? scope.selectedChild?.uid)) {
            child = item;
            break;
          }
        }
        child ??= scope.selectedChild;
        if (child == null) {
          return const MessageView('We couldn’t find that child.');
        }
        final ChildModel selected = child;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
          children: <Widget>[
            AppTopBar(title: selected.name, subtitle: selected.email),
            const SizedBox(height: AppSpacing.sm),
            StreamBuilder<PointsModel>(
              stream: GameService.instance.watchPoints(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder: (BuildContext context, AsyncSnapshot<PointsModel> pts) {
                return StreamBuilder<ScreenTimeModel?>(
                  stream: ScreenTimeService.instance.watchToday(
                    familyId: scope.familyId,
                    childId: selected.uid,
                  ),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<ScreenTimeModel?> time,
                      ) {
                    return StreamBuilder<LocationModel?>(
                      stream: LocationService.instance.watchLatestForChild(
                        familyId: scope.familyId,
                        childId: selected.uid,
                      ),
                      builder:
                          (
                            BuildContext context,
                            AsyncSnapshot<LocationModel?> loc,
                          ) {
                        final PointsModel points =
                            pts.data ?? PointsModel.empty(selected.uid);
                        final ScreenTimeModel? usage = time.data;
                        final bool sharing = loc.data?.sharingEnabled == true;
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
                              icon: Icons.star_rounded,
                              title: 'Points',
                              subtitle:
                                  '${points.points} pts · Lv ${points.level}',
                            ),
                            FeatureTile(
                              color: AppColors.tileOrange,
                              icon: Icons.timelapse_rounded,
                              title: 'Screen Time',
                              subtitle: usage == null
                                  ? 'No update yet'
                                  : formatHoursMinutes(usage.totalMinutes),
                            ),
                            FeatureTile(
                              color: AppColors.tilePurple,
                              icon: Icons.shield_moon_rounded,
                              title: 'Learning',
                              subtitle: 'Quizzes & badges',
                            ),
                            FeatureTile(
                              color: AppColors.tileGreen,
                              icon: Icons.gps_fixed_rounded,
                              title: 'GPS',
                              subtitle: sharing
                                  ? loc.data != null && loc.data!.hasFix
                                        ? 'Live pin'
                                        : 'Sharing on'
                                  : 'Sharing off',
                            ),
                          ],
                        );
                      },
                    );
                  },
                );
              },
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Today', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<List<ActivityModel>>(
              stream: ActivityService.instance.watchChildActivities(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<List<ActivityModel>> snap) {
                if (snap.hasError) {
                  return const KidCard(child: Text('Unable to load activities.'));
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
                return Column(
                  children: <Widget>[
                    for (final ActivityModel activity in today)
                      ActivityTile(activity: activity),
                  ],
                );
              },
            ),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<List<GameProgressModel>>(
              stream: GameService.instance.watchChildProgress(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder:
                  (
                    BuildContext context,
                    AsyncSnapshot<List<GameProgressModel>> games,
                  ) {
                final List<GameProgressModel> items =
                    games.data ?? <GameProgressModel>[];
                if (items.isEmpty) {
                  return const KidCard(
                    child: Text(
                      'Play your first game to start building your progress.',
                    ),
                  );
                }
                return Column(
                  children: <Widget>[
                    for (final GameProgressModel item in items)
                      Padding(
                        padding: const EdgeInsets.only(bottom: AppSpacing.md),
                        child: KidCard(
                          child: Text(
                            '${GameService.instance.gameById(item.gameId)?.title ?? item.gameId} · ${item.score} latest · ${item.bestScore} best',
                          ),
                        ),
                      ),
                  ],
                );
              },
            ),
          ],
        );
      },
    );
  }
}
