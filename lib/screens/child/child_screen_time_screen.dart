import 'package:flutter/material.dart';

import '../../models/screen_time_model.dart';
import '../../models/user_role.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/screen_time_summary.dart';
import '../../widgets/status_views.dart';

class ChildScreenTimeScreen extends StatefulWidget {
  const ChildScreenTimeScreen({super.key});

  @override
  State<ChildScreenTimeScreen> createState() => _ChildScreenTimeScreenState();
}

class _ChildScreenTimeScreenState extends State<ChildScreenTimeScreen>
    with WidgetsBindingObserver {
  ScreenTimeAccess _access = ScreenTimeAccess.unavailable;
  bool _available = true;
  bool _checking = true;
  FamilyScope? _scope;
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAccess(sync: true);
    }
  }

  Future<void> _refreshAccess({bool sync = false}) async {
    final ScreenTimeAccess access = await ScreenTimeService.instance
        .checkPermission();
    if (!mounted) return;
    setState(() {
      _access = access;
      _checking = false;
      if (access == ScreenTimeAccess.unavailable) {
        _available = false;
      } else if (access == ScreenTimeAccess.missing) {
        _available = true;
      }
    });
    final FamilyScope? scope = _scope;
    if (access == ScreenTimeAccess.granted && scope != null) {
      final ScreenTimeSnapshot snapshot = await ScreenTimeService.instance
          .refreshFromDevice(
            familyId: scope.familyId,
            childId: scope.user.uid,
            dailyLimitMinutes: scope.user.dailyScreenLimitMinutes,
            forceWrite: sync,
          );
      if (!mounted) return;
      setState(() => _available = snapshot.available);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        _scope = scope;
        if (!_primed) {
          _primed = true;
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _refreshAccess(sync: true);
          });
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppTopBar(title: 'Screen Time'),
            Expanded(child: _body(scope)),
          ],
        );
      },
    );
  }

  Widget _body(FamilyScope scope) {
    if (_checking) {
      return const LoadingView();
    }
    if (_access == ScreenTimeAccess.missing) {
      return ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: <Widget>[
          UsageAccessCard(
            friendly: true,
            onEnable: () async {
              await ScreenTimeService.instance.openPermissionSettings();
            },
          ),
        ],
      );
    }
    if (_access == ScreenTimeAccess.unavailable || !_available) {
      return ListView(
        padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
        children: const <Widget>[
          KidCard(
            child: Text('Screen-time data is unavailable on this device.'),
          ),
        ],
      );
    }

    final int limit = scope.user.dailyScreenLimitMinutes;
    return StreamBuilder<ScreenTimeModel?>(
      stream: ScreenTimeService.instance.watchToday(
        familyId: scope.familyId,
        childId: scope.user.uid,
      ),
      builder: (BuildContext context, AsyncSnapshot<ScreenTimeModel?> snap) {
        if (snap.hasError) {
          return ListView(
            padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
            children: const <Widget>[
              KidCard(child: Text('Unable to load screen-time information.')),
            ],
          );
        }
        final ScreenTimeModel? record = snap.data;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
          children: <Widget>[
            ScreenTimeSummary(
              used: record?.totalMinutes ?? 0,
              limit: limit,
              hasRecord: record != null,
              updatedAt: record?.updatedAt,
              friendly: true,
              demo: record?.isDemo == true,
            ),
            const SizedBox(height: AppSpacing.lg),
            ScreenTimeAppList(
              apps: record?.appUsage ?? const <AppUsageModel>[],
              emptyLabel: record == null
                  ? 'Play a bit, then come back to see today’s apps.'
                  : 'No app breakdown yet for today.',
            ),
          ],
        );
      },
    );
  }
}
