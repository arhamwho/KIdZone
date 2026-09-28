import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';

import '../models/screen_time_model.dart';
import '../utils/firestore_codec.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

enum ScreenTimeAccess { granted, missing, unavailable }

class ScreenTimeSnapshot {
  const ScreenTimeSnapshot({
    required this.access,
    required this.record,
  });

  final ScreenTimeAccess access;
  final ScreenTimeModel record;
}

class ScreenTimeService {
  ScreenTimeService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final ScreenTimeService instance = ScreenTimeService();
  static const MethodChannel _channel = MethodChannel('kidzone/usage_stats');

  final FirestoreService _db;

  Stream<ScreenTimeModel?> watchToday({
    required String familyId,
    required String childId,
  }) {
    final String today = dateKey(DateTime.now());
    final String recordId = '${childId}_$today';
    return _db
        .screenTime(familyId)
        .doc(recordId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          return ScreenTimeModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<ScreenTimeAccess> checkAccess() async {
    try {
      final bool? granted = await _channel.invokeMethod<bool>('hasPermission');
      if (granted == true) return ScreenTimeAccess.granted;
      if (granted == false) return ScreenTimeAccess.missing;
      return ScreenTimeAccess.unavailable;
    } catch (_) {
      return ScreenTimeAccess.unavailable;
    }
  }

  Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod<void>('openSettings');
    } catch (_) {}
  }

  Future<ScreenTimeSnapshot> refreshFromDevice({
    required String familyId,
    required String childId,
  }) async {
    final String today = dateKey(DateTime.now());
    final String recordId = '${childId}_$today';
    final ScreenTimeAccess access = await checkAccess();

    if (access != ScreenTimeAccess.granted) {
      return ScreenTimeSnapshot(
        access: access,
        record: ScreenTimeModel(
          recordId: recordId,
          childId: childId,
          date: today,
          totalMinutes: 0,
          appUsage: const <AppUsageItem>[],
          source: 'unavailable',
        ),
      );
    }

    try {
      final Object? raw = await _channel.invokeMethod<Object>('todayUsage');
      final Map<String, dynamic> data = Map<String, dynamic>.from(
        raw as Map<dynamic, dynamic>? ?? <dynamic, dynamic>{},
      );
      final List<dynamic> apps =
          data['apps'] as List<dynamic>? ?? <dynamic>[];
      final ScreenTimeModel record = ScreenTimeModel(
        recordId: recordId,
        childId: childId,
        date: today,
        totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
        appUsage: apps
            .whereType<Map<dynamic, dynamic>>()
            .map(
              (Map<dynamic, dynamic> item) =>
                  AppUsageItem.fromMap(Map<String, dynamic>.from(item)),
            )
            .toList(),
        source: 'device',
      );
      await _db.screenTime(familyId).doc(recordId).set(record.toMap());
      return ScreenTimeSnapshot(access: access, record: record);
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  /// Clearly labeled sample data for demos when the device cannot share usage.
  ScreenTimeModel demoRecord(String childId) {
    final String today = dateKey(DateTime.now());
    return ScreenTimeModel(
      recordId: '${childId}_$today',
      childId: childId,
      date: today,
      totalMinutes: 78,
      appUsage: const <AppUsageItem>[
        AppUsageItem(name: 'Learning', minutes: 28),
        AppUsageItem(name: 'Videos', minutes: 22),
        AppUsageItem(name: 'Games', minutes: 18),
        AppUsageItem(name: 'Messages', minutes: 10),
      ],
      source: 'demo',
    );
  }
}
