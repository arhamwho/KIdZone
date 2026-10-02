import 'package:flutter/material.dart';

import '../../models/location_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/location_radar.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';

class LocationTrackerScreen extends StatelessWidget {
  const LocationTrackerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.parent.tint,
      actions: const <Widget>[],
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.selectedChild == null) {
          return const Column(
            children: <Widget>[
              AppTopBar(title: 'Location'),
              Expanded(
                child: MessageView(
                  'Add a child to see location updates.',
                  icon: Icons.location_on_outlined,
                ),
              ),
            ],
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            const AppTopBar(title: 'Location'),
            ChildPicker(
              children: scope.children,
              selectedId: scope.selectedChild?.uid,
              onSelected: FamilySession.instance.selectChild,
            ),
            const SizedBox(height: AppSpacing.md),
            Expanded(
              child: StreamBuilder<LocationModel?>(
                stream: LocationService.instance.watchLatestForChild(
                  familyId: scope.familyId,
                  childId: scope.selectedChild!.uid,
                ),
                builder:
                    (BuildContext context, AsyncSnapshot<LocationModel?> snap) {
                  if (snap.hasError) {
                    return const MessageView(
                      'Unable to load this location right now.',
                    );
                  }
                  if (!snap.hasData &&
                      snap.connectionState == ConnectionState.waiting) {
                    return const LoadingView();
                  }
                  final LocationModel? live = snap.data;
                  return _LocationBody(
                    childName: scope.selectedChild!.name,
                    location: live,
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

class _LocationBody extends StatelessWidget {
  const _LocationBody({required this.childName, required this.location});

  final String childName;
  final LocationModel? location;

  @override
  Widget build(BuildContext context) {
    final bool sharing = location?.sharingEnabled == true;
    final bool hasFix = location != null && location!.hasFix;
    final ThemeData theme = Theme.of(context);

    return ListView(
      padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
      children: <Widget>[
        KidCard(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: <Widget>[
              SizedBox(
                height: 240,
                child: LocationRadar(
                  name: childName,
                  hasFix: hasFix,
                  live: sharing && hasFix,
                  accuracyMeters: hasFix ? location!.accuracy : null,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              SoftBadge(
                label: location?.isDemo == true
                    ? 'Demo Location'
                    : !sharing
                    ? 'Location sharing off'
                    : hasFix
                    ? 'Live GPS'
                    : 'Waiting for a GPS fix',
                background: sharing
                    ? AppColors.sky.withValues(alpha: 0.22)
                    : theme.colorScheme.surfaceContainerHighest,
                foreground: sharing
                    ? AppColors.skyInk
                    : theme.colorScheme.onSurfaceVariant,
                icon: location?.isDemo == true
                    ? Icons.place_outlined
                    : sharing
                    ? Icons.my_location_rounded
                    : Icons.location_off_outlined,
              ),
              const SizedBox(height: AppSpacing.sm),
              Text(
                location?.isDemo == true
                    ? 'Sample pin for $childName. This is not a live GPS reading.'
                    : hasFix
                    ? childName
                    : sharing
                    ? 'Waiting for a live reading from $childName’s phone.'
                    : '$childName has not shared a GPS reading yet.',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodySmall,
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        KidCard(
          child: Column(
            children: <Widget>[
              _CoordRow(
                label: 'Latitude',
                value: hasFix ? formatCoordinate(location!.latitude) : '—',
              ),
              _CoordRow(
                label: 'Longitude',
                value: hasFix ? formatCoordinate(location!.longitude) : '—',
              ),
              _CoordRow(
                label: 'Accuracy',
                value: hasFix ? formatAccuracy(location!.accuracy) : '—',
              ),
              _CoordRow(
                label: 'Last updated',
                value: hasFix && location!.hasTimestamp
                    ? '${formatRelative(location!.timestamp)} · ${formatStamp(location!.timestamp)}'
                    : '—',
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CoordRow extends StatelessWidget {
  const _CoordRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          SizedBox(
            width: 118,
            child: Text(label, style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: Text(
              value,
              style: theme.textTheme.titleSmall,
            ),
          ),
        ],
      ),
    );
  }
}
