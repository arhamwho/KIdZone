import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/child_model.dart';
import '../../models/location_model.dart';
import '../../models/points_model.dart';
import '../../models/screen_time_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../services/family_session.dart';
import '../../services/game_service.dart';
import '../../services/location_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/role_shell.dart';

class ParentDashboardScreen extends StatelessWidget {
  const ParentDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'Parent Dashboard',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
          children: <Widget>[
            KidCard(
              background: AppColors.sky.withValues(alpha: 0.18),
              borderColor: Colors.transparent,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Hello, ${scope.user.name}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  SoftBadge(
                    label: '${scope.children.length} ${scope.children.length == 1 ? 'child' : 'children'} in your family',
                    background: AppColors.surface,
                    foreground: AppColors.parentAccent,
                    icon: Icons.home_outlined,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            const SectionHeader(
              title: 'Children',
              subtitle: 'Choose a child to see today’s snapshot.',
            ),
            const SizedBox(height: AppSpacing.md),
            if (scope.children.isEmpty)
              KidCard(
                child: Text(
                  'No children in this family yet.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              )
            else
              ...scope.children.map((ChildModel child) {
                final bool selected = child.uid == scope.selectedChild?.uid;
                return Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.md),
                  child: KidCard(
                    background: selected
                        ? AppColors.peach.withValues(alpha: 0.28)
                        : null,
                    onTap: () {
                      FamilySession.instance.selectChild(child.uid);
                      Navigator.of(context).pushNamed(
                        AppRoutes.childOverview,
                        arguments: child.uid,
                      );
                    },
                    child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      leading: CircleAvatar(
                        backgroundColor: AppColors.peach.withValues(alpha: 0.5),
                        child: Icon(
                          Icons.child_care_outlined,
                          color: UserRole.child.accent,
                        ),
                      ),
                      title: Text(child.name),
                      subtitle: Text(selected ? 'Selected · ${child.email}' : child.email),
                      trailing: IconButton(
                        tooltip: 'Select',
                        onPressed: () =>
                            FamilySession.instance.selectChild(child.uid),
                        icon: Icon(
                          selected
                              ? Icons.check_circle_rounded
                              : Icons.radio_button_off,
                          color: selected
                              ? AppColors.parentAccent
                              : Theme.of(context).colorScheme.outline,
                        ),
                      ),
                    ),
                  ),
                );
              }),
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: 'Add Child',
              icon: Icons.add_rounded,
              expand: true,
              compact: true,
              onPressed: () =>
                  Navigator.of(context).pushNamed(AppRoutes.addChild),
            ),
            if (scope.selectedChild != null) ...<Widget>[
              const SizedBox(height: AppSpacing.xxl),
              SectionHeader(
                title: '${scope.selectedChild!.name} today',
                subtitle: 'Live from your family space.',
              ),
              const SizedBox(height: AppSpacing.lg),
              _ChildSnapshot(
                familyId: scope.familyId,
                child: scope.selectedChild!,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
            const SectionHeader(
              title: 'Family tools',
              subtitle: 'Jump into today’s care and learning.',
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ToolGrid(),
          ],
        );
      },
    );
  }
}

class _ChildSnapshot extends StatelessWidget {
  const _ChildSnapshot({required this.familyId, required this.child});

  final String familyId;
  final ChildModel child;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ActivityModel>>(
      stream: ActivityService.instance.watchChildActivities(
        familyId: familyId,
        childId: child.uid,
      ),
      builder: (BuildContext context, AsyncSnapshot<List<ActivityModel>> acts) {
        return StreamBuilder<ScreenTimeModel?>(
          stream: ScreenTimeService.instance.watchToday(
            familyId: familyId,
            childId: child.uid,
          ),
          builder: (BuildContext context, AsyncSnapshot<ScreenTimeModel?> time) {
            return StreamBuilder<LocationModel?>(
              stream: LocationService.instance.watchLatestForChild(
                familyId: familyId,
                childId: child.uid,
              ),
              builder:
                  (BuildContext context, AsyncSnapshot<LocationModel?> loc) {
                return StreamBuilder<PointsModel>(
                  stream: GameService.instance.watchPoints(
                    familyId: familyId,
                    childId: child.uid,
                  ),
                  builder:
                      (BuildContext context, AsyncSnapshot<PointsModel> points) {
                    final List<ActivityModel> today = (acts.data ?? <ActivityModel>[])
                        .where((ActivityModel item) => item.isToday)
                        .toList();
                    final int done = today
                        .where((ActivityModel item) => item.completed)
                        .length;
                    final ScreenTimeModel? usage = time.data;
                    final PointsModel pts =
                        points.data ?? PointsModel.empty(child.uid);
                    return Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _StatCard(
                                label: 'Activities',
                                value: today.isEmpty ? 'None yet' : '$done / ${today.length}',
                                icon: Icons.event_note_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                label: 'Points',
                                value: '${pts.points}',
                                icon: Icons.stars_rounded,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: _StatCard(
                                label: 'Screen time',
                                value: usage == null
                                    ? 'Waiting'
                                    : '${usage.totalMinutes} min',
                                icon: Icons.timelapse_outlined,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: _StatCard(
                                label: 'Location',
                                value: loc.data == null ? 'No pin yet' : 'Updated',
                                icon: Icons.location_on_outlined,
                              ),
                            ),
                          ],
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

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
  });

  final String label;
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return KidCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, color: AppColors.parentAccent),
          const SizedBox(height: AppSpacing.sm),
          Text(label, style: Theme.of(context).textTheme.bodySmall),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _ToolGrid extends StatelessWidget {
  const _ToolGrid();

  @override
  Widget build(BuildContext context) {
    const List<(IconData, String, int)> tools = <(IconData, String, int)>[
      (Icons.event_note_outlined, 'Activities', 1),
      (Icons.location_on_outlined, 'Location', 2),
      (Icons.timelapse_outlined, 'Screen Time', 3),
      (Icons.extension_outlined, 'Learning Games', 4),
    ];

    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: AppSpacing.md,
      crossAxisSpacing: AppSpacing.md,
      childAspectRatio: 1.35,
      children: <Widget>[
        for (final (IconData icon, String label, int tab) in tools)
          KidCard(
            onTap: () => ShellTabs.maybeOf(context)?.onSelect(tab),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Icon(icon, color: AppColors.parentAccent),
                const SizedBox(height: AppSpacing.sm),
                Text(label, textAlign: TextAlign.center),
              ],
            ),
          ),
      ],
    );
  }
}
