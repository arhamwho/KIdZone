import 'package:flutter/material.dart';

import '../../models/screen_time_model.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/screen_time_summary.dart';
import '../../widgets/status_views.dart';

class ScreenTimeMonitorScreen extends StatelessWidget {
  const ScreenTimeMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.parent.tint,
      actions: const <Widget>[],
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.user.role == UserRole.child) {
          return const _ChildCannotEdit();
        }
        if (scope.selectedChild == null) {
          return const Column(
            children: <Widget>[
              AppTopBar(title: 'Screen Time'),
              Expanded(
                child: MessageView(
                  'Add a child to see screen-time updates.',
                  icon: Icons.timelapse_outlined,
                ),
              ),
            ],
          );
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppTopBar(title: 'Screen Time'),
            ChildPicker(
              children: scope.children,
              selectedId: scope.selectedChild?.uid,
              onSelected: FamilySession.instance.selectChild,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: _ParentUsagePane(
                familyId: scope.familyId,
                childId: scope.selectedChild!.uid,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ParentUsagePane extends StatelessWidget {
  const _ParentUsagePane({required this.familyId, required this.childId});

  final String familyId;
  final String childId;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserModel?>(
      stream: FirestoreService.instance.watchUserProfile(childId),
      builder: (BuildContext context, AsyncSnapshot<UserModel?> profile) {
        final int limit = profile.data?.dailyScreenLimitMinutes ?? 120;
        return StreamBuilder<ScreenTimeModel?>(
          stream: ScreenTimeService.instance.watchToday(
            familyId: familyId,
            childId: childId,
          ),
          builder:
              (BuildContext context, AsyncSnapshot<ScreenTimeModel?> snap) {
            if (snap.hasError) {
              return const MessageView(
                'Unable to load screen-time information.',
              );
            }
            final ScreenTimeModel? record = snap.data;
            return _UsageList(
              familyId: familyId,
              childId: childId,
              limit: limit,
              record: record,
            );
          },
        );
      },
    );
  }
}

class _UsageList extends StatefulWidget {
  const _UsageList({
    required this.familyId,
    required this.childId,
    required this.limit,
    required this.record,
  });

  final String familyId;
  final String childId;
  final int limit;
  final ScreenTimeModel? record;

  @override
  State<_UsageList> createState() => _UsageListState();
}

class _UsageListState extends State<_UsageList> {
  double? _draftLimit;
  bool _saving = false;

  Future<void> _refresh() async {
    try {
      await ScreenTimeService.instance
          .watchToday(familyId: widget.familyId, childId: widget.childId)
          .first;
    } catch (_) {}
  }

  Future<void> _saveLimit(double value) async {
    final int minutes = value.round().clamp(30, 300);
    setState(() {
      _draftLimit = null;
      _saving = true;
    });
    try {
      await FirestoreService.instance.updateUserProfile(
        widget.childId,
        dailyScreenLimitMinutes: minutes,
      );
      await ScreenTimeService.instance.updateDailyLimit(
        familyId: widget.familyId,
        childId: widget.childId,
        dailyLimitMinutes: minutes,
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final int limit = widget.limit;
    final ScreenTimeModel? record = widget.record;
    final double sliderValue =
        (_draftLimit ?? limit.toDouble()).clamp(30, 300);

    return RefreshIndicator(
      onRefresh: _refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: <Widget>[
          ScreenTimeSummary(
            used: record?.totalMinutes ?? 0,
            limit: limit,
            hasRecord: record != null,
            updatedAt: record?.updatedAt,
            demo: record?.isDemo == true,
          ),
          const SizedBox(height: AppSpacing.lg),
          ScreenTimeAppList(
            apps: record?.appUsage ?? const <AppUsageModel>[],
            emptyLabel: record == null
                ? 'This child’s device has not shared usage yet. Usage Access must be enabled on their phone.'
                : 'No app breakdown yet for today.',
          ),
          const SizedBox(height: AppSpacing.lg),
          KidCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Daily limit',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
                Slider(
                  value: sliderValue,
                  min: 30,
                  max: 300,
                  divisions: 9,
                  label: '${sliderValue.round()} min',
                  onChanged: _saving
                      ? null
                      : (double value) {
                          setState(() => _draftLimit = value);
                        },
                  onChangeEnd: _saving ? null : _saveLimit,
                ),
                Text(
                  '${formatHoursMinutes(limit)} each day. This does not block apps.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          TextButton.icon(
            onPressed: _refresh,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Refresh usage'),
          ),
          Text(
            'Usage is collected on the child’s phone and updates here automatically.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _ChildCannotEdit extends StatelessWidget {
  const _ChildCannotEdit();

  @override
  Widget build(BuildContext context) {
    return const Column(
      children: <Widget>[
        AppTopBar(title: 'Screen Time'),
        Expanded(
          child: MessageView('Open Screen Time from the child Home tab.'),
        ),
      ],
    );
  }
}
