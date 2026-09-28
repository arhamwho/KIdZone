import 'package:flutter/material.dart';

import '../../models/screen_time_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/progress_ring.dart';
import '../../widgets/status_views.dart';

class ScreenTimeMonitorScreen extends StatefulWidget {
  const ScreenTimeMonitorScreen({super.key});

  @override
  State<ScreenTimeMonitorScreen> createState() =>
      _ScreenTimeMonitorScreenState();
}

class _ScreenTimeMonitorScreenState extends State<ScreenTimeMonitorScreen> {
  bool _showDemo = false;

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'Screen Time',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.selectedChild == null) {
          return const MessageView(
            'Add a child to see screen-time updates.',
            icon: Icons.timelapse_outlined,
          );
        }
        return Column(
          children: <Widget>[
            ChildPicker(
              children: scope.children,
              selectedId: scope.selectedChild?.uid,
              onSelected: FamilySession.instance.selectChild,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: StreamBuilder<UserModel?>(
                stream: FirestoreService.instance.watchUserProfile(
                  scope.selectedChild!.uid,
                ),
                builder:
                    (BuildContext context, AsyncSnapshot<UserModel?> profile) {
                  final int limit =
                      profile.data?.dailyScreenLimitMinutes ?? 120;
                  return StreamBuilder<ScreenTimeModel?>(
                    stream: ScreenTimeService.instance.watchToday(
                      familyId: scope.familyId,
                      childId: scope.selectedChild!.uid,
                    ),
                    builder:
                        (
                          BuildContext context,
                          AsyncSnapshot<ScreenTimeModel?> snap,
                        ) {
                      if (snap.hasError) {
                        return const MessageView(
                          'Unable to load screen-time information.',
                        );
                      }
                      ScreenTimeModel? record = snap.data;
                      bool demo = false;
                      if (record == null && _showDemo) {
                        record = ScreenTimeService.instance.demoRecord(
                          scope.selectedChild!.uid,
                        );
                        demo = true;
                      }
                      return ListView(
                        children: <Widget>[
                          _UsageCard(
                            name: scope.selectedChild!.name,
                            record: record,
                            limit: limit,
                            isDemo: demo || (record?.isDemo ?? false),
                          ),
                          const SizedBox(height: AppSpacing.lg),
                          Text(
                            'Daily limit',
                            style: Theme.of(context).textTheme.titleSmall,
                          ),
                          Slider(
                            value: limit.toDouble().clamp(30, 300),
                            min: 30,
                            max: 300,
                            divisions: 9,
                            label: '$limit min',
                            onChanged: (_) {},
                            onChangeEnd: (double value) {
                              FirestoreService.instance.updateUserProfile(
                                scope.selectedChild!.uid,
                                dailyScreenLimitMinutes: value.round(),
                              );
                            },
                          ),
                          if (record == null) ...<Widget>[
                            const SizedBox(height: AppSpacing.md),
                            Text(
                              'This child’s device has not shared usage yet. Usage access is required on their phone.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            PrimaryButton(
                              label: _showDemo
                                  ? 'Hide sample data'
                                  : 'Show sample data',
                              compact: true,
                              expand: true,
                              onPressed: () =>
                                  setState(() => _showDemo = !_showDemo),
                            ),
                          ],
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.name,
    required this.record,
    required this.limit,
    required this.isDemo,
  });

  final String name;
  final ScreenTimeModel? record;
  final int limit;
  final bool isDemo;

  @override
  Widget build(BuildContext context) {
    final int used = record?.totalMinutes ?? 0;
    final int remaining = (limit - used).clamp(0, limit);
    final double progress = limit == 0 ? 0 : (used / limit).clamp(0, 1);

    return KidCard(
      child: Column(
        children: <Widget>[
          if (isDemo)
            const Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.md),
              child: SoftBadge(
                label: 'Sample data (not from this device)',
                background: AppColors.sunshine,
                foreground: AppColors.sunshineInk,
                icon: Icons.science_outlined,
              ),
            ),
          ProgressRing(
            value: progress,
            label: '$used m',
            caption: 'of $limit',
            color: AppColors.parentAccent,
          ),
          const SizedBox(height: AppSpacing.md),
          Text('$name · $remaining min remaining'),
          if (record != null && record!.appUsage.isNotEmpty) ...<Widget>[
            const SizedBox(height: AppSpacing.lg),
            for (final AppUsageItem item in record!.appUsage)
              Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: Row(
                  children: <Widget>[
                    Expanded(child: Text(item.name)),
                    Text('${item.minutes} min'),
                  ],
                ),
              ),
          ],
        ],
      ),
    );
  }
}
