import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/firestore_service.dart';
import '../../services/location_service.dart';
import '../../services/screen_time_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
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

  Future<void> _setSharing({
    required FamilyScope scope,
    required bool enabled,
  }) async {
    setState(() {
      _busy = true;
      _locationNote = null;
    });
    try {
      await FirestoreService.instance.updateUserProfile(
        scope.user.uid,
        locationSharingEnabled: enabled,
      );
      if (enabled) {
        final LocationShareState state = await LocationService.instance
            .startSharing(familyId: scope.familyId, childId: scope.user.uid);
        setState(() => _locationNote = _locationMessage(state));
      } else {
        await LocationService.instance.stopSharing();
        setState(() => _locationNote = 'Location sharing is off.');
      }
    } catch (_) {
      setState(
        () => _locationNote = 'Location permission is required.',
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String _locationMessage(LocationShareState state) {
    return switch (state) {
      LocationShareState.sharing || LocationShareState.ready =>
        'Live location is on while KidZone is open.',
      LocationShareState.permissionDenied =>
        'Location permission is required.',
      LocationShareState.permissionPermanentlyDenied =>
        'Location permission is turned off for this app. You can enable it in Settings.',
      LocationShareState.serviceDisabled =>
        'Turn on Location services to share your place.',
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
          );
      setState(() {
        _access = snapshot.access;
        _usageNote = switch (snapshot.access) {
          ScreenTimeAccess.granted => 'Today’s usage was updated.',
          ScreenTimeAccess.missing => 'Screen-time permission is required.',
          ScreenTimeAccess.unavailable =>
            'Usage data is unavailable on this device.',
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
      title: 'Profile',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        return ListView(
          children: <Widget>[
            KidCard(
              child: ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(scope.user.name),
                subtitle: Text(scope.user.email),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
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
                        'Share today’s usage so your parent can see a friendly summary.',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  PrimaryButton(
                    label: 'Update today’s usage',
                    compact: true,
                    expand: true,
                    onPressed: _busy ? null : () => _refreshUsage(scope),
                  ),
                  if (_access == ScreenTimeAccess.missing) ...<Widget>[
                    const SizedBox(height: AppSpacing.sm),
                    TextButton(
                      onPressed: ScreenTimeService.instance.openUsageSettings,
                      child: const Text('Open usage access settings'),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
