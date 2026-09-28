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
import '../../theme/app_spacing.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/status_views.dart';

class ChildOverviewScreen extends StatelessWidget {
  const ChildOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final Object? args = ModalRoute.of(context)?.settings.arguments;
    final String? childId = args is String ? args : null;

    return FamilyGate(
      title: 'Child Overview',
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
          children: <Widget>[
            KidCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(selected.name),
                subtitle: Text(selected.email),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            StreamBuilder<PointsModel>(
              stream: GameService.instance.watchPoints(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder: (BuildContext context, AsyncSnapshot<PointsModel> pts) {
                final PointsModel points =
                    pts.data ?? PointsModel.empty(selected.uid);
                return KidCard(
                  child: Text(
                    '${points.points} points · Level ${points.level}',
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<ScreenTimeModel?>(
              stream: ScreenTimeService.instance.watchToday(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<ScreenTimeModel?> time) {
                return KidCard(
                  child: Text(
                    time.data == null
                        ? 'No screen-time update yet'
                        : 'Screen time today: ${time.data!.totalMinutes} min',
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
            StreamBuilder<LocationModel?>(
              stream: LocationService.instance.watchLatestForChild(
                familyId: scope.familyId,
                childId: selected.uid,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<LocationModel?> loc) {
                return KidCard(
                  child: Text(
                    loc.data == null
                        ? 'No live location yet'
                        : 'Last location ${loc.data!.latitude.toStringAsFixed(4)}, ${loc.data!.longitude.toStringAsFixed(4)}',
                  ),
                );
              },
            ),
            const SizedBox(height: AppSpacing.md),
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
                final int done = (games.data ?? <GameProgressModel>[])
                    .where((GameProgressModel item) => item.completed)
                    .length;
                return KidCard(child: Text('Games completed: $done'));
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
                final List<ActivityModel> today = (snap.data ?? <ActivityModel>[])
                    .where((ActivityModel item) => item.isToday)
                    .toList();
                if (today.isEmpty) {
                  return const KidCard(child: Text('No activities today.'));
                }
                return Column(
                  children: <Widget>[
                    for (final ActivityModel activity in today)
                      ActivityTile(activity: activity),
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
