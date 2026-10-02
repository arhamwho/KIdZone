import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../models/screen_time_model.dart';
import '../utils/firestore_codec.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

enum ScreenTimeAccess { granted, missing, unavailable }

class ScreenTimeSnapshot {
  const ScreenTimeSnapshot({
    required this.access,
    this.record,
    this.available = true,
  });

  final ScreenTimeAccess access;
  final ScreenTimeModel? record;
  final bool available;
}

class ScreenTimeService {
  ScreenTimeService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final ScreenTimeService instance = ScreenTimeService();
  static const MethodChannel _channel = MethodChannel('com.kidzone/screen_time');
  static const Duration _minWriteGap = Duration(minutes: 2);

  final FirestoreService _db;
  Timer? _syncTimer;
  DateTime? _lastWriteAt;
  int? _lastWrittenTotal;
  String? _syncFamilyId;
  String? _syncChildId;

  Stream<ScreenTimeModel?> watchToday({
    required String familyId,
    required String childId,
  }) {
    final String today = dateKey(DateTime.now());
    return _db
        .screenTime(familyId)
        .doc(childId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return null;
          final ScreenTimeModel record = ScreenTimeModel.fromFirestore(doc);
          if (record.date != today) return null;
          return record;
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<ScreenTimeAccess> checkPermission() => checkAccess();

  Future<ScreenTimeAccess> checkAccess() async {
    if (kIsWeb) return ScreenTimeAccess.unavailable;
    try {
      final bool? granted = await _channel.invokeMethod<bool>(
        'checkUsageAccess',
      );
      if (granted == true) return ScreenTimeAccess.granted;
      if (granted == false) return ScreenTimeAccess.missing;
      return ScreenTimeAccess.unavailable;
    } on MissingPluginException {
      return ScreenTimeAccess.unavailable;
    } catch (_) {
      return ScreenTimeAccess.unavailable;
    }
  }

  Future<void> openPermissionSettings() => openUsageSettings();

  Future<void> openUsageSettings() async {
    try {
      await _channel.invokeMethod<void>('openUsageAccessSettings');
    } catch (_) {}
  }

  Future<Map<String, dynamic>?> getTodayUsage() async {
    try {
      final Object? raw = await _channel.invokeMethod<Object>('getTodayUsage');
      if (raw is! Map) return null;
      return Map<String, dynamic>.from(raw);
    } on MissingPluginException {
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> updateDailyLimit({
    required String familyId,
    required String childId,
    required int dailyLimitMinutes,
  }) async {
    try {
      await _db.screenTime(familyId).doc(childId).set(
        <String, dynamic>{'dailyLimitMinutes': dailyLimitMinutes},
        SetOptions(merge: true),
      );
    } catch (_) {}
  }

  Future<ScreenTimeSnapshot> refreshFromDevice({
    required String familyId,
    required String childId,
    int dailyLimitMinutes = 120,
    bool forceWrite = false,
  }) async {
    final String today = dateKey(DateTime.now());
    final ScreenTimeAccess access = await checkPermission();

    if (access == ScreenTimeAccess.missing) {
      return ScreenTimeSnapshot(access: access);
    }
    if (access != ScreenTimeAccess.granted) {
      return const ScreenTimeSnapshot(
        access: ScreenTimeAccess.unavailable,
        available: false,
      );
    }

    final Map<String, dynamic>? data = await getTodayUsage();
    if (data == null) {
      return const ScreenTimeSnapshot(
        access: ScreenTimeAccess.unavailable,
        available: false,
      );
    }
    if (data['granted'] == false) {
      return const ScreenTimeSnapshot(access: ScreenTimeAccess.missing);
    }
    if (data['available'] == false) {
      return const ScreenTimeSnapshot(
        access: ScreenTimeAccess.granted,
        available: false,
      );
    }

    final List<dynamic> apps = data['apps'] as List<dynamic>? ?? <dynamic>[];
    final List<AppUsageModel> parsed = apps
        .whereType<Map<dynamic, dynamic>>()
        .map(
          (Map<dynamic, dynamic> item) =>
              AppUsageModel.fromMap(Map<String, dynamic>.from(item)),
        )
        .where((AppUsageModel item) => item.minutes > 0)
        .toList();
    final ScreenTimeModel record = ScreenTimeModel(
      recordId: childId,
      childId: childId,
      date: today,
      totalMinutes: parsed.fold<int>(
        0,
        (int sum, AppUsageModel item) => sum + item.minutes,
      ),
      dailyLimitMinutes: dailyLimitMinutes,
      appUsage: parsed,
      source: 'device',
    );

    final bool shouldWrite =
        forceWrite ||
        _lastWrittenTotal != record.totalMinutes ||
        _lastWriteAt == null ||
        DateTime.now().difference(_lastWriteAt!) >= _minWriteGap;
    if (shouldWrite) {
      try {
        await _db.screenTime(familyId).doc(childId).set(record.toMap());
        _lastWriteAt = DateTime.now();
        _lastWrittenTotal = record.totalMinutes;
      } catch (_) {}
    }
    return ScreenTimeSnapshot(access: access, record: record);
  }

  void startChildSync({
    required String familyId,
    required String childId,
    int dailyLimitMinutes = 120,
  }) {
    _syncFamilyId = familyId;
    _syncChildId = childId;
    unawaited(
      _syncOnce(fallbackLimit: dailyLimitMinutes, forceWrite: true),
    );
    _syncTimer?.cancel();
    _syncTimer = Timer.periodic(const Duration(minutes: 3), (_) {
      unawaited(_syncOnce(fallbackLimit: dailyLimitMinutes));
    });
  }

  Future<void> _syncOnce({
    required int fallbackLimit,
    bool forceWrite = false,
  }) async {
    final String? family = _syncFamilyId;
    final String? child = _syncChildId;
    if (family == null || child == null) return;
    int limit = fallbackLimit;
    try {
      final profile = await _db.getUserProfile(child);
      if (profile != null) limit = profile.dailyScreenLimitMinutes;
    } catch (_) {}
    await refreshFromDevice(
      familyId: family,
      childId: child,
      dailyLimitMinutes: limit,
      forceWrite: forceWrite,
    );
  }

  void stopChildSync() {
    _syncTimer?.cancel();
    _syncTimer = null;
    _syncFamilyId = null;
    _syncChildId = null;
  }
}
