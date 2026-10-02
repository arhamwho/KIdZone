import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/activity_model.dart';
import '../models/activity_type.dart';
import '../models/points_model.dart';
import '../utils/firestore_codec.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';
import 'game_service.dart';

class ActivityService {
  ActivityService({FirestoreService? firestore, GameService? games})
    : _db = firestore ?? FirestoreService.instance,
      _games = games ?? GameService.instance;

  static final ActivityService instance = ActivityService();

  final FirestoreService _db;
  final GameService _games;

  Stream<List<ActivityModel>> watchActivities(String familyId) {
    return _db
        .activities(familyId)
        .snapshots()
        .map((QuerySnapshot<Map<String, dynamic>> snapshot) {
          final List<ActivityModel> items = snapshot.docs
              .map(ActivityModel.fromFirestore)
              .toList();
          items.sort(_compare);
          return items;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Stream<List<ActivityModel>> watchChildActivities({
    required String familyId,
    required String childId,
  }) {
    return watchActivities(familyId).map(
      (List<ActivityModel> items) =>
          items.where((ActivityModel item) => item.childId == childId).toList(),
    );
  }

  Future<void> createActivity({
    required String familyId,
    required String childId,
    required String title,
    required String description,
    required ActivityType type,
    required DateTime scheduledDate,
    required String startTime,
    required String endTime,
    required String createdBy,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _db
          .activities(familyId)
          .doc();
      final ActivityModel activity = ActivityModel(
        activityId: doc.id,
        childId: childId,
        title: title.trim(),
        description: description.trim(),
        type: type,
        scheduledDate: dateOnly(scheduledDate),
        startTime: startTime,
        endTime: endTime,
        completed: false,
        createdBy: createdBy,
      );
      await doc.set(activity.toMap(isCreate: true));
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> setCompleted({
    required String familyId,
    required ActivityModel activity,
    required bool completed,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> actRef = _db
          .activities(familyId)
          .doc(activity.activityId);
      bool awardedNow = false;
      await FirebaseFirestore.instance.runTransaction((
        Transaction transaction,
      ) async {
        awardedNow = false;
        final DocumentSnapshot<Map<String, dynamic>> snap = await transaction
            .get(actRef);
        if (!snap.exists) return;
        final ActivityModel current = ActivityModel.fromFirestore(snap);
        final Map<String, dynamic> patch = <String, dynamic>{
          'completed': completed,
        };
        if (completed) {
          patch['completedAt'] = FieldValue.serverTimestamp();
          if (!current.pointsAwarded) {
            patch['pointsAwarded'] = true;
            awardedNow = true;
          }
        }
        transaction.update(actRef, patch);
      });
      if (awardedNow) {
        await _games.awardPoints(
          familyId: familyId,
          childId: activity.childId,
          amount: 10,
          unlock: AchievementId.firstActivity,
        );
        await _maybeUnlockFiveActivities(
          familyId: familyId,
          childId: activity.childId,
        );
      }
    } catch (error) {
      if (error is FirestoreException) rethrow;
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> _maybeUnlockFiveActivities({
    required String familyId,
    required String childId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .activities(familyId)
        .where('childId', isEqualTo: childId)
        .get();
    final int completedCount = snapshot.docs
        .map(ActivityModel.fromFirestore)
        .where((ActivityModel item) => item.completed)
        .length;
    if (completedCount < 5) return;
    await _games.awardPoints(
      familyId: familyId,
      childId: childId,
      amount: 0,
      unlock: AchievementId.fiveActivities,
    );
  }

  int _compare(ActivityModel a, ActivityModel b) {
    final int date = a.scheduledDate.compareTo(b.scheduledDate);
    if (date != 0) return date;
    return a.startTime.compareTo(b.startTime);
  }
}
