import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/firestore_codec.dart';

class ReminderModel {
  const ReminderModel({
    required this.reminderId,
    required this.childId,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.enabled,
    required this.createdBy,
    required this.completed,
    this.createdAt,
  });

  final String reminderId;
  final String childId;
  final String title;
  final String description;
  final String date;
  final String time;
  final bool enabled;
  final String createdBy;
  final bool completed;
  final DateTime? createdAt;

  DateTime? get scheduledAt {
    final TimeOfDay? clock = parseClock(time);
    final List<String> parts = date.split('-');
    if (clock == null || parts.length != 3) return null;
    final int? year = int.tryParse(parts[0]);
    final int? month = int.tryParse(parts[1]);
    final int? day = int.tryParse(parts[2]);
    if (year == null || month == null || day == null) return null;
    return DateTime(year, month, day, clock.hour, clock.minute);
  }

  bool get isDueInFuture {
    final DateTime? when = scheduledAt;
    if (when == null) return false;
    return when.isAfter(DateTime.now());
  }

  factory ReminderModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final Map<String, dynamic> data = doc.data() ?? <String, dynamic>{};
    return ReminderModel(
      reminderId: data['reminderId'] as String? ?? doc.id,
      childId: data['childId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      date: data['date'] as String? ?? dateKey(DateTime.now()),
      time: data['time'] as String? ?? '19:00',
      enabled: data['enabled'] as bool? ?? true,
      createdBy: data['createdBy'] as String? ?? '',
      completed: data['completed'] as bool? ?? false,
      createdAt: readDate(data['createdAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'reminderId': reminderId,
      'childId': childId,
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'enabled': enabled,
      'createdBy': createdBy,
      'createdAt': FieldValue.serverTimestamp(),
      'completed': completed,
    };
  }
}
