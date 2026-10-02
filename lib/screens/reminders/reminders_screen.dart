import 'package:flutter/material.dart';

import '../../models/reminder_model.dart';
import '../../models/user_role.dart';
import '../../services/auth_service.dart';
import '../../services/family_session.dart';
import '../../services/firestore_service.dart';
import '../../services/reminder_service.dart';
import '../../theme/app_spacing.dart';
import '../../utils/firestore_codec.dart';
import '../../utils/validators.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/primary_button.dart';
import '../../widgets/status_views.dart';

class RemindersScreen extends StatelessWidget {
  const RemindersScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      builder: (BuildContext context, FamilyScope scope) {
        final bool isParent = scope.user.role == UserRole.parent;
        final String? childId = isParent
            ? scope.selectedChild?.uid
            : scope.user.uid;
        return Stack(
          children: <Widget>[
            Column(
              children: <Widget>[
                const AppTopBar(title: 'Reminders'),
                if (isParent)
                  ChildPicker(
                    children: scope.children,
                    selectedId: scope.selectedChild?.uid,
                    onSelected: FamilySession.instance.selectChild,
                  ),
                if (isParent) const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: childId == null
                      ? const MessageView(
                          'Add a child to create reminders.',
                          icon: Icons.alarm_outlined,
                        )
                      : StreamBuilder<List<ReminderModel>>(
                          stream: ReminderService.instance.watchReminders(
                            familyId: scope.familyId,
                            childId: childId,
                          ),
                          builder:
                              (
                                BuildContext context,
                                AsyncSnapshot<List<ReminderModel>> snap,
                              ) {
                            if (snap.hasError) {
                              return const MessageView(
                                'Unable to load reminders.',
                              );
                            }
                            final List<ReminderModel> items =
                                snap.data ?? const <ReminderModel>[];
                            if (items.isEmpty) {
                              return const MessageView(
                                'No reminders yet.',
                                icon: Icons.alarm_outlined,
                              );
                            }
                            return ListView.builder(
                              padding: const EdgeInsets.only(
                                bottom: AppSpacing.navClearance,
                              ),
                              itemCount: items.length,
                              itemBuilder: (BuildContext context, int index) {
                                return _ReminderTile(
                                  familyId: scope.familyId,
                                  reminder: items[index],
                                  isParent: isParent,
                                );
                              },
                            );
                          },
                        ),
                ),
              ],
            ),
            if (isParent)
              Positioned(
                right: AppSpacing.lg,
                bottom: AppSpacing.navClearance,
                child: FloatingActionButton.extended(
                  onPressed: () {
                    if (FamilySession.instance.selectedChildId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Please choose a child first.'),
                        ),
                      );
                      return;
                    }
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => const _CreateReminderSheet(),
                    );
                  },
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('New reminder'),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _ReminderTile extends StatelessWidget {
  const _ReminderTile({
    required this.familyId,
    required this.reminder,
    required this.isParent,
  });

  final String familyId;
  final ReminderModel reminder;
  final bool isParent;

  @override
  Widget build(BuildContext context) {
    final DateTime? when = reminder.scheduledAt;
    final String whenLabel = when == null
        ? '${reminder.date}  ${reminder.time}'
        : formatStamp(when);
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: KidCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    reminder.title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                if (isParent)
                  Switch(
                    value: reminder.enabled,
                    onChanged: (bool value) {
                      ReminderService.instance.setEnabled(
                        familyId: familyId,
                        reminderId: reminder.reminderId,
                        enabled: value,
                      );
                    },
                  ),
              ],
            ),
            if (reminder.description.isNotEmpty)
              Text(
                reminder.description,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            const SizedBox(height: AppSpacing.xs),
            Text(whenLabel, style: Theme.of(context).textTheme.bodySmall),
            if (isParent)
              Text(
                reminder.completed ? 'Completed' : 'Waiting for your child',
                style: Theme.of(context).textTheme.bodySmall,
              )
            else
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: reminder.completed,
                title: Text(
                  reminder.completed ? 'Completed' : 'Mark complete',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                onChanged: (bool? value) {
                  ReminderService.instance.setCompleted(
                    familyId: familyId,
                    reminderId: reminder.reminderId,
                    completed: value ?? false,
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _CreateReminderSheet extends StatefulWidget {
  const _CreateReminderSheet();

  @override
  State<_CreateReminderSheet> createState() => _CreateReminderSheetState();
}

class _CreateReminderSheetState extends State<_CreateReminderSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _title = TextEditingController();
  final TextEditingController _description = TextEditingController();
  DateTime _date = dateOnly(DateTime.now());
  TimeOfDay _time = const TimeOfDay(hour: 19, minute: 0);
  bool _enabled = true;
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
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    setState(() => _busy = true);
    try {
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final String? familyId = profile?.familyId;
      if (familyId == null || familyId.isEmpty) {
        setState(() => _error = 'We couldn’t find your family.');
        return;
      }
      await ReminderService.instance.createReminder(
        familyId: familyId,
        childId: childId,
        title: _title.text,
        description: _description.text,
        date: _date,
        time: formatClock(_time),
        createdBy: uid,
        enabled: _enabled,
      );
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Unable to save this reminder.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              Text(
                'New reminder',
                style: Theme.of(context).textTheme.titleLarge,
              ),
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
              KidCard(
                onTap: () async {
                  final TimeOfDay? picked = await showTimePicker(
                    context: context,
                    initialTime: _time,
                  );
                  if (picked != null) setState(() => _time = picked);
                },
                child: Text('Time  ${formatClock(_time)}'),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable reminder'),
                value: _enabled,
                onChanged: (bool value) => setState(() => _enabled = value),
              ),
              if (_error != null)
                Text(
                  _error!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.error,
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              PrimaryButton(
                label: _busy ? 'Saving…' : 'Save reminder',
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
