import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';

class ChildProfileScreen extends StatefulWidget {
  const ChildProfileScreen({super.key});

  @override
  State<ChildProfileScreen> createState() => _ChildProfileScreenState();
}

class _ChildProfileScreenState extends State<ChildProfileScreen>
    with WidgetsBindingObserver {
  bool _busy = false;
  String? _locationNote;
  String? _usageNote;
  ScreenTimeAccess _access = ScreenTimeAccess.unavailable;
  FamilyScope? _scope;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshAccess();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshAccess();
      final FamilyScope? scope = _scope;
      if (scope != null && scope.user.locationSharingEnabled) {
        LocationService.instance.startSharing(
          familyId: scope.familyId,
          childId: scope.user.uid,
        );
      }
    }
  }

  Future<void> _refreshAccess() async {
    final ScreenTimeAccess access = await ScreenTimeService.instance
        .checkPermission();
    if (mounted) setState(() => _access = access);
  }

  Future<void> _setSharing({
    required FamilyScope scope,
    required bool enabled,
  }) async {
    setState(() {
      _busy = true;
      _locationNote = null;
    });
    try {
      if (enabled) {
        final LocationShareState state = await LocationService.instance
            .startSharing(familyId: scope.familyId, childId: scope.user.uid);
        if (state != LocationShareState.sharing &&
            state != LocationShareState.ready) {
          await FirestoreService.instance.updateUserProfile(
            scope.user.uid,
            locationSharingEnabled: false,
          );
          setState(() => _locationNote = _locationMessage(state));
          return;
        }
        await FirestoreService.instance.updateUserProfile(
          scope.user.uid,
          locationSharingEnabled: true,
        );
        setState(() => _locationNote = _locationMessage(state));
      } else {
        await LocationService.instance.stopSharing();
        await LocationService.instance.markSharingOff(
          familyId: scope.familyId,
          childId: scope.user.uid,
        );
        await FirestoreService.instance.updateUserProfile(
          scope.user.uid,
          locationSharingEnabled: false,
        );
        setState(() => _locationNote = 'Location sharing is off.');
      }
    } catch (_) {
      setState(
        () => _locationNote =
            'Location permission is required to share your location.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _locationMessage(LocationShareState state) {
    return switch (state) {
      LocationShareState.sharing || LocationShareState.ready =>
        'Live location is on while KidZone is open.',
      LocationShareState.permissionDenied ||
      LocationShareState.permissionPermanentlyDenied =>
        'Location permission is required to share your location.',
      LocationShareState.serviceDisabled =>
        'Turn on Location Services to continue.',
      LocationShareState.unavailable =>
        'Location is unavailable on this device.',
    };
  }

  Future<void> _refreshUsage(FamilyScope scope) async {
    setState(() {
      _busy = true;
      _usageNote = null;
    });
    try {
      final ScreenTimeSnapshot snapshot = await ScreenTimeService.instance
          .refreshFromDevice(
            familyId: scope.familyId,
            childId: scope.user.uid,
            dailyLimitMinutes: scope.user.dailyScreenLimitMinutes,
            forceWrite: true,
          );
      setState(() {
        _access = snapshot.access;
        _usageNote = switch (snapshot.access) {
          ScreenTimeAccess.granted => snapshot.available
              ? 'Today’s usage was updated.'
              : 'Screen-time data is unavailable on this device.',
          ScreenTimeAccess.missing =>
            'Screen-time access is not enabled. KidZone needs Usage Access permission to calculate today’s screen time.',
          ScreenTimeAccess.unavailable =>
            'Screen-time data is unavailable on this device.',
        };
      });
    } catch (_) {
      setState(
        () => _usageNote = 'Unable to read screen time right now.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        _scope = scope;
        return ListView(
          padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
          children: <Widget>[
            ProfileHeader(
              name: scope.user.name,
              caption: scope.user.email,
            ),
            const SizedBox(height: AppSpacing.md),
            KidCard(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Share my location'),
                subtitle: Text(
                  _locationNote ??
                      (scope.user.locationSharingEnabled
                          ? 'Sharing while KidZone is open.'
                          : 'Off — your parent will not see a live pin.'),
                ),
                value: scope.user.locationSharingEnabled,
                onChanged: _busy
                    ? null
                    : (bool value) => _setSharing(scope: scope, enabled: value),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            KidCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  const Text('Screen time'),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    _usageNote ??
                        (_access == ScreenTimeAccess.missing
                            ? 'Screen-time access is not enabled. KidZone needs Usage Access permission to calculate today’s screen time.'
                            : _access == ScreenTimeAccess.unavailable
                            ? 'Screen-time data is unavailable on this device.'
                            : 'Share today’s usage so your parent can see a friendly summary.'),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: _access == ScreenTimeAccess.missing
                        ? 'Enable Screen Time'
                        : 'Update today’s usage',
                    compact: true,
                    expand: true,
                    onPressed: _busy
                        ? null
                        : () async {
                            if (_access == ScreenTimeAccess.missing) {
                              await ScreenTimeService.instance
                                  .openPermissionSettings();
                              return;
                            }
                            await _refreshUsage(scope);
                          },
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
