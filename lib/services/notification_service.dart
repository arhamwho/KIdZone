import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/data/latest.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;

import '../models/reminder_model.dart';
import 'reminder_service.dart';

class NotificationService {
  NotificationService();

  static final NotificationService instance = NotificationService();

  static const String _channelId = 'kidzone_reminders';
  static const String _channelName = 'KidZone reminders';

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  final Set<int> _scheduled = <int>{};
  bool _ready = false;

  Future<void> initialize() async {
    if (kIsWeb || _ready) return;
    const AndroidInitializationSettings android = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const DarwinInitializationSettings apple = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: apple,
        macOS: apple,
      ),
    );
    await _configureLocalTime();
    _ready = true;
  }

  Future<void> _configureLocalTime() async {
    tzdata.initializeTimeZones();
    try {
      if (defaultTargetPlatform == TargetPlatform.linux ||
          defaultTargetPlatform == TargetPlatform.windows) {
        tz.setLocalLocation(tz.UTC);
        return;
      }
      final TimezoneInfo info = await FlutterTimezone.getLocalTimezone();
      String name = info.identifier;
      if (name == 'Asia/Calcutta') name = 'Asia/Kolkata';
      tz.setLocalLocation(tz.getLocation(name));
    } catch (_) {
      tz.setLocalLocation(tz.UTC);
    }
  }

  Future<bool> requestPermission() async {
    if (kIsWeb) return false;
    await initialize();
    final AndroidFlutterLocalNotificationsPlugin? android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    final bool? androidOk = await android?.requestNotificationsPermission();
    final IOSFlutterLocalNotificationsPlugin? ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    final bool? iosOk = await ios?.requestPermissions(
      alert: true,
      badge: true,
      sound: true,
    );
    return androidOk ?? iosOk ?? true;
  }

  Future<void> syncChildReminders(List<ReminderModel> reminders) async {
    if (kIsWeb) return;
    await initialize();
    final Set<int> keep = <int>{};
    for (final ReminderModel reminder in reminders) {
      final int id = _idFor(reminder.reminderId);
      if (reminder.enabled && !reminder.completed && reminder.isDueInFuture) {
        await _schedule(reminder);
        keep.add(id);
      } else {
        await _plugin.cancel(id: id);
      }
    }
    for (final int id in _scheduled.difference(keep)) {
      await _plugin.cancel(id: id);
    }
    _scheduled
      ..clear()
      ..addAll(keep);
  }

  Future<void> _schedule(ReminderModel reminder) async {
    final DateTime? when = reminder.scheduledAt;
    if (when == null) return;
    final tz.TZDateTime scheduled = tz.TZDateTime.from(when, tz.local);
    if (!scheduled.isAfter(tz.TZDateTime.now(tz.local))) return;
    final NotificationDetails details = NotificationDetails(
      android: AndroidNotificationDetails(
        _channelId,
        _channelName,
        channelDescription: 'Homework, health and sleep reminders',
        importance: Importance.high,
        priority: Priority.high,
        icon: '@mipmap/ic_launcher',
      ),
      iOS: const DarwinNotificationDetails(),
    );
    try {
      await _plugin.zonedSchedule(
        id: _idFor(reminder.reminderId),
        title: reminder.title,
        body: reminder.description.isEmpty
            ? 'KidZone reminder'
            : reminder.description,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: reminder.reminderId,
      );
    } catch (_) {
      await _plugin.zonedSchedule(
        id: _idFor(reminder.reminderId),
        title: reminder.title,
        body: reminder.description.isEmpty
            ? 'KidZone reminder'
            : reminder.description,
        scheduledDate: scheduled,
        notificationDetails: details,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        payload: reminder.reminderId,
      );
    }
  }

  static int _idFor(String reminderId) => reminderId.hashCode & 0x7fffffff;
}

class ReminderNotificationBinder {
  ReminderNotificationBinder();

  static final ReminderNotificationBinder instance =
      ReminderNotificationBinder();

  StreamSubscription<List<ReminderModel>>? _sub;

  void start({required String familyId, required String childId}) {
    stop();
    unawaited(NotificationService.instance.requestPermission());
    _sub = ReminderService.instance
        .watchReminders(familyId: familyId, childId: childId)
        .listen((List<ReminderModel> items) {
          unawaited(NotificationService.instance.syncChildReminders(items));
        });
  }

  void stop() {
    _sub?.cancel();
    _sub = null;
  }
}
