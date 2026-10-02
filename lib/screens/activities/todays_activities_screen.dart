import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';

class TodaysActivitiesScreen extends StatelessWidget {
  const TodaysActivitiesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        return StreamBuilder<List<ActivityModel>>(
          stream: ActivityService.instance.watchChildActivities(
            familyId: scope.familyId,
            childId: scope.user.uid,
          ),
          builder:
              (BuildContext context, AsyncSnapshot<List<ActivityModel>> snap) {
            if (snap.hasError) {
              return const Column(
                children: <Widget>[
                  AppTopBar(title: 'Activities'),
                  Expanded(
                    child: MessageView('Unable to load your activities.'),
                  ),
                ],
              );
            }
            if (!snap.hasData) {
              return const Column(
                children: <Widget>[
                  AppTopBar(title: 'Activities'),
                  Expanded(child: LoadingView()),
                ],
              );
            }
            final List<ActivityModel> items = snap.data!;
            final List<ActivityModel> today = items
                .where((ActivityModel item) => item.isToday)
                .toList();
            final List<ActivityModel> upcoming = items
                .where(
                  (ActivityModel item) =>
                      item.scheduledDate.isAfter(dateOnly(DateTime.now())),
                )
                .toList();

            if (items.isEmpty) {
              return const Column(
                children: <Widget>[
                  AppTopBar(title: 'Activities'),
                  Expanded(
                    child: MessageView(
                      'No activities scheduled yet.',
                      icon: Icons.checklist_outlined,
                    ),
                  ),
                ],
              );
            }

            return Column(
              children: <Widget>[
                const AppTopBar(title: 'Activities'),
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.navClearance,
                    ),
                    children: <Widget>[
                      Text(
                        'Today',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (today.isEmpty)
                        const KidCard(
                          child: Text('Nothing planned for today.'),
                        )
                      else
                        ...today.map(
                          (ActivityModel activity) => ActivityTile(
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
                        ),
                      const SizedBox(height: AppSpacing.xl),
                      Text(
                        'Upcoming',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: AppSpacing.md),
                      if (upcoming.isEmpty)
                        const KidCard(child: Text('No upcoming activities.'))
                      else
                        ...upcoming.map(
                          (ActivityModel activity) =>
                              ActivityTile(activity: activity),
                        ),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }
}
