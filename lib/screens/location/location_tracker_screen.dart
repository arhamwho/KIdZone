import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import '../../models/location_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/location_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';

class LocationTrackerScreen extends StatefulWidget {
  const LocationTrackerScreen({super.key});

  @override
  State<LocationTrackerScreen> createState() => _LocationTrackerScreenState();
}

class _LocationTrackerScreenState extends State<LocationTrackerScreen> {
  bool _showDemo = false;

  static const LatLng _demoPoint = LatLng(51.5074, -0.1278);

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'Location',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.selectedChild == null) {
          return const MessageView(
            'Add a child to see location updates.',
            icon: Icons.location_on_outlined,
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
                  final LocationModel? live = snap.data;
                  final bool usingDemo = _showDemo && live == null;
                  final LatLng? point = live == null
                      ? (usingDemo ? _demoPoint : null)
                      : LatLng(live.latitude, live.longitude);

                  return ListView(
                    children: <Widget>[
                      if (point == null)
                        const KidCard(
                          child: Text(
                            'No live location yet. Location appears here when this child turns sharing on from their phone.',
                          ),
                        )
                      else
                        ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: SizedBox(
                            height: 280,
                            child: FlutterMap(
                              options: MapOptions(
                                initialCenter: point,
                                initialZoom: 14,
                              ),
                              children: <Widget>[
                                TileLayer(
                                  urlTemplate:
                                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                                  userAgentPackageName: 'com.kidzone.kidzone',
                                ),
                                MarkerLayer(
                                  markers: <Marker>[
                                    Marker(
                                      point: point,
                                      width: 44,
                                      height: 44,
                                      child: Icon(
                                        Icons.location_on_rounded,
                                        color: usingDemo
                                            ? AppColors.sunshineInk
                                            : AppColors.parentAccent,
                                        size: 40,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                      const SizedBox(height: AppSpacing.md),
                      KidCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            SoftBadge(
                              label: usingDemo
                                  ? 'Sample location (not live)'
                                  : live == null
                                      ? 'Waiting for a live pin'
                                      : 'Live location',
                              background: usingDemo
                                  ? AppColors.sunshine.withValues(alpha: 0.4)
                                  : AppColors.sky.withValues(alpha: 0.35),
                              foreground: usingDemo
                                  ? AppColors.sunshineInk
                                  : AppColors.parentAccent,
                              icon: usingDemo
                                  ? Icons.science_outlined
                                  : Icons.my_location_rounded,
                            ),
                            const SizedBox(height: AppSpacing.md),
                            Text(scope.selectedChild!.name),
                            if (live != null) ...<Widget>[
                              Text(
                                '${live.latitude.toStringAsFixed(5)}, ${live.longitude.toStringAsFixed(5)}',
                              ),
                              Text(
                                'Updated ${_ago(live.timestamp)} · ±${live.accuracy.round()} m',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ] else if (usingDemo) ...<Widget>[
                              const Text('51.50740, -0.12780'),
                              Text(
                                'This is sample map data for demos only.',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ],
                        ),
                      ),
                      if (live == null) ...<Widget>[
                        const SizedBox(height: AppSpacing.lg),
                        PrimaryButton(
                          label: _showDemo
                              ? 'Hide sample location'
                              : 'Show sample location',
                          compact: true,
                          expand: true,
                          onPressed: () =>
                              setState(() => _showDemo = !_showDemo),
                        ),
                      ],
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  String _ago(DateTime time) {
    final Duration delta = DateTime.now().difference(time);
    if (delta.inMinutes < 1) return 'just now';
    if (delta.inHours < 1) return '${delta.inMinutes} min ago';
    if (delta.inDays < 1) return '${delta.inHours} hr ago';
    return '${delta.inDays} days ago';
  }
}
