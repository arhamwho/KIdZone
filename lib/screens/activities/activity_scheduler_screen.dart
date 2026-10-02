import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../models/activity_model.dart';
import '../../models/activity_type.dart';
import '../../models/user_model.dart';
import '../../models/user_role.dart';
import '../../services/activity_service.dart';
import '../../services/auth_service.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../utils/validators.dart';
import '../../widgets/activity_tile.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';

class ActivitySchedulerScreen extends StatelessWidget {
  const ActivitySchedulerScreen({super.key});

  /// Space occupied by [RoleShell]'s floating navigation, plus a gap so the
  /// FAB sits fully above it on any Android inset.
  ///
  /// The shell draws its bar over the body. [MediaQuery.padding] already
  /// reports that overlap when `extendBody` is on, and the bar itself also
  /// includes the system inset, so the reserve uses whichever is taller.
  static double _shellNavReserve(BuildContext context) {
    final double obstructed = MediaQuery.paddingOf(context).bottom;
    final double viewBottom = MediaQuery.viewPaddingOf(context).bottom;
    final double navHeight = NavigationBarTheme.of(context).height ?? 80;
    const double shellBottomPad = 12;
    // NavigationBar wraps itself in a SafeArea, so the painted bar is the
    // theme height plus the system inset and the shell's bottom padding.
    final double estimated = viewBottom + shellBottomPad + navHeight;
    return math.max(obstructed, estimated) + AppSpacing.md;
  }

  void _openNewActivity(BuildContext context) {
    if (FamilySession.instance.selectedChildId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please choose a child first.')),
      );
      return;
    }
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const CreateActivitySheet(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      floatingActionButtonLocation: const _RaisedEndFloat(10),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openNewActivity(context),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New activity'),
      ),
      bottomNavigationBar: SizedBox(height: _shellNavReserve(context)),
      body: FamilyGate(
        title: '',
        tint: UserRole.parent.tint,
        builder: (BuildContext context, FamilyScope scope) {
          return Column(
            children: <Widget>[
              const AppTopBar(title: 'Plan'),
              ChildPicker(
                children: scope.children,
                selectedId: scope.selectedChild?.uid,
                onSelected: FamilySession.instance.selectChild,
              ),
              const SizedBox(height: AppSpacing.lg),
              Expanded(
                child: scope.selectedChild == null
                    ? const MessageView(
                        'Add a child to start planning activities.',
                        icon: Icons.event_note_outlined,
                      )
                    : StreamBuilder<List<ActivityModel>>(
                        stream: ActivityService.instance.watchChildActivities(
                          familyId: scope.familyId,
                          childId: scope.selectedChild!.uid,
                        ),
                        builder:
                            (
                              BuildContext context,
                              AsyncSnapshot<List<ActivityModel>> snapshot,
                            ) {
                              if (snapshot.hasError) {
                                return const MessageView(
                                  'Unable to load your activities.',
                                );
                              }
                              final List<ActivityModel> items =
                                  snapshot.data ?? <ActivityModel>[];
                              if (items.isEmpty) {
                                return const MessageView(
                                  'No activities scheduled yet.',
                                  icon: Icons.event_available_outlined,
                                );
                              }
                              return ListView.builder(
                                padding: const EdgeInsets.only(
                                  bottom: AppSpacing.huge,
                                ),
                                itemCount: items.length,
                                itemBuilder: (BuildContext context, int index) {
                                  return ActivityTile(activity: items[index]);
                                },
                              );
                            },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// [FloatingActionButtonLocation.endFloat] raised by a fixed logical gap.
///
/// The base location already clears the shell navigation and system inset.
/// [lift] adds a small amount of space so the button sits between that
/// clearance and a larger offset.
class _RaisedEndFloat extends FloatingActionButtonLocation {
  const _RaisedEndFloat(this.lift);

  final double lift;

  @override
  Offset getOffset(ScaffoldPrelayoutGeometry scaffoldGeometry) {
    final Offset base = FloatingActionButtonLocation.endFloat.getOffset(
      scaffoldGeometry,
    );
    return Offset(base.dx, base.dy - lift);
  }
}

class CreateActivitySheet extends StatefulWidget {
  const CreateActivitySheet({super.key});

  @override
  State<CreateActivitySheet> createState() => _CreateActivitySheetState();
}

class _CreateActivitySheetState extends State<CreateActivitySheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  ActivityType _type = ActivityType.homework;
  DateTime _date = dateOnly(DateTime.now());
  TimeOfDay _start = const TimeOfDay(hour: 16, minute: 0);
  TimeOfDay _end = const TimeOfDay(hour: 17, minute: 0);
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _description.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    setState(() => _error = null);
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final String? childId = FamilySession.instance.selectedChildId;
    if (childId == null) {
      setState(() => _error = 'Please choose a child first.');
      return;
    }
    if (minutesBetween(formatClock(_start), formatClock(_end)) <= 0) {
      setState(() => _error = 'End time must be after start time.');
      return;
    }
    setState(() => _busy = true);
    try {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Save this activity?'),
            content: Text(_title.text.trim()),
            actions: <Widget>[
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      );
      if (confirmed != true) {
        if (mounted) setState(() => _busy = false);
        return;
      }
      final String? uid = AuthService.instance.currentFirebaseUser?.uid;
      if (uid == null) {
        throw Exception();
      }
      final UserModel? profile = await FirestoreService.instance.getUserProfile(
        uid,
      );
      final String? familyId = profile?.familyId;
      if (familyId == null) {
        setState(
          () => _error = 'We couldn’t find your family. Please try again.',
        );
        return;
      }
      await ActivityService.instance.createActivity(
        familyId: familyId,
        childId: childId,
        title: _title.text,
        description: _description.text,
        type: _type,
        scheduledDate: _date,
        startTime: formatClock(_start),
        endTime: formatClock(_end),
        createdBy: uid,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(
          () => _error = 'Unable to save this activity. Please try again.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ThemeData theme = Theme.of(context);
    return Padding(
      padding: EdgeInsets.only(
        left: AppSpacing.lg,
        right: AppSpacing.lg,
        top: AppSpacing.lg,
        bottom: MediaQuery.viewInsetsOf(context).bottom + AppSpacing.lg,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Text('New activity', style: theme.textTheme.titleLarge),
              const SizedBox(height: AppSpacing.lg),
              TextFormField(
                controller: _title,
                textCapitalization: TextCapitalization.sentences,
                decoration: const InputDecoration(labelText: 'Title'),
                validator: (String? value) =>
                    Validators.required(value, field: 'Title'),
              ),
              const SizedBox(height: AppSpacing.md),
              TextFormField(
                controller: _description,
                maxLines: 2,
                decoration: const InputDecoration(labelText: 'Description'),
              ),
              const SizedBox(height: AppSpacing.md),
              DropdownButtonFormField<ActivityType>(
                initialValue: _type,
                decoration: const InputDecoration(labelText: 'Type'),
                items: <DropdownMenuItem<ActivityType>>[
                  for (final ActivityType type in ActivityType.values)
                    DropdownMenuItem<ActivityType>(
                      value: type,
                      child: Text(type.label),
                    ),
                ],
                onChanged: (ActivityType? value) {
                  if (value != null) setState(() => _type = value);
                },
              ),
              const SizedBox(height: AppSpacing.md),
              KidCard(
                onTap: () async {
                  final DateTime? picked = await showDatePicker(
                    context: context,
                    initialDate: _date,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _date = dateOnly(picked));
                },
                child: Text('Date  ${_date.day}/${_date.month}/${_date.year}'),
              ),
              const SizedBox(height: AppSpacing.sm),
              Row(
                children: <Widget>[
                  Expanded(
                    child: KidCard(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _start,
                        );
                        if (picked != null) setState(() => _start = picked);
                      },
                      child: Text('Start  ${formatClock(_start)}'),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: KidCard(
                      onTap: () async {
                        final TimeOfDay? picked = await showTimePicker(
                          context: context,
                          initialTime: _end,
                        );
                        if (picked != null) setState(() => _end = picked);
                      },
                      child: Text('End  ${formatClock(_end)}'),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...<Widget>[
                const SizedBox(height: AppSpacing.md),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _busy ? 'Saving…' : 'Save activity',
                expand: true,
                compact: true,
                onPressed: _busy ? null : _save,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
