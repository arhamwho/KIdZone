import 'dart:async';

import '../models/user_role.dart';
import 'auth_service.dart';
import 'firestore_service.dart';
import 'location_service.dart';
import 'screen_time_service.dart';
import 'notification_service.dart';

/// Keeps a child session visible to the parent and resumes location sharing.
class PresenceService {
  PresenceService();

  static final PresenceService instance = PresenceService();

  Timer? _timer;

  Future<void> start() async {
    await ping();
    await _resumeLocationIfNeeded();
    await _startScreenTimeSync();
    await _startReminderSync();
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 45), (_) {
      unawaited(ping());
    });
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
    ScreenTimeService.instance.stopChildSync();
    ReminderNotificationBinder.instance.stop();
  }

  Future<void> ping() async {
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    try {
      await FirestoreService.instance.updateUserProfile(
        uid,
        touchLastActive: true,
      );
    } catch (_) {}
  }

  Future<void> _resumeLocationIfNeeded() async {
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    try {
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final String? familyId = profile?.familyId;
      if (profile == null || familyId == null) return;
      if (!profile.locationSharingEnabled) return;
      await LocationService.instance.startSharing(
        familyId: familyId,
        childId: uid,
      );
    } catch (_) {}
  }

  Future<void> _startScreenTimeSync() async {
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    try {
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final String? familyId = profile?.familyId;
      if (profile == null || familyId == null) return;
      if (profile.role != UserRole.child) return;
      ScreenTimeService.instance.startChildSync(
        familyId: familyId,
        childId: uid,
        dailyLimitMinutes: profile.dailyScreenLimitMinutes,
      );
    } catch (_) {}
  }

  Future<void> _startReminderSync() async {
    final String? uid = AuthService.instance.currentFirebaseUser?.uid;
    if (uid == null) return;
    try {
      final profile = await FirestoreService.instance.getUserProfile(uid);
      final String? familyId = profile?.familyId;
      if (profile == null || familyId == null) return;
      if (profile.role != UserRole.child) return;
      ReminderNotificationBinder.instance.start(
        familyId: familyId,
        childId: uid,
      );
    } catch (_) {}
  }
}
