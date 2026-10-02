import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/reminder_model.dart';
import '../utils/firestore_codec.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

class ReminderService {
  ReminderService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final ReminderService instance = ReminderService();

  final FirestoreService _db;

  Stream<List<ReminderModel>> watchReminders({
    required String familyId,
    String? childId,
  }) {
    return _db
        .reminders(familyId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<ReminderModel> items = snapshot.docs
              .map(ReminderModel.fromFirestore)
              .where(
                (ReminderModel item) =>
                    childId == null || item.childId == childId,
              )
              .toList();
          items.sort((ReminderModel a, ReminderModel b) {
            final DateTime left =
                a.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            final DateTime right =
                b.scheduledAt ?? DateTime.fromMillisecondsSinceEpoch(0);
            return left.compareTo(right);
          });
          return items;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<void> createReminder({
    required String familyId,
    required String childId,
    required String title,
    required String description,
    required DateTime date,
    required String time,
    required String createdBy,
    bool enabled = true,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _db
          .reminders(familyId)
          .doc();
      final ReminderModel reminder = ReminderModel(
        reminderId: doc.id,
        childId: childId,
        title: title.trim(),
        description: description.trim(),
        date: dateKey(date),
        time: time,
        enabled: enabled,
        createdBy: createdBy,
        completed: false,
      );
      await doc.set(reminder.toMap());
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> setEnabled({
    required String familyId,
    required String reminderId,
    required bool enabled,
  }) async {
    try {
      await _db.reminders(familyId).doc(reminderId).update(<String, dynamic>{
        'enabled': enabled,
      });
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> setCompleted({
    required String familyId,
    required String reminderId,
    required bool completed,
  }) async {
    try {
      await _db.reminders(familyId).doc(reminderId).update(<String, dynamic>{
        'completed': completed,
      });
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }
}
