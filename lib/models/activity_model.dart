import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';
import 'activity_type.dart';

class ActivityModel {
  const ActivityModel({
    required this.activityId,
    required this.childId,
    required this.title,
    required this.description,
    required this.type,
    required this.scheduledDate,
    required this.startTime,
    required this.endTime,
    required this.completed,
    required this.createdBy,
    this.createdAt,
    this.completedAt,
    this.pointsAwarded = false,
  });

  final String activityId;
  final String childId;
  final String title;
  final String description;
  final ActivityType type;
  final DateTime scheduledDate;
  final String startTime;
  final String endTime;
  final bool completed;
  final String createdBy;
  final DateTime? createdAt;
  final DateTime? completedAt;
  final bool pointsAwarded;

  bool get isToday => isSameDay(scheduledDate, DateTime.now());

  factory ActivityModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ActivityModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory ActivityModel.fromMap(Map<String, dynamic> data, String id) {
    return ActivityModel(
      activityId: data['activityId'] as String? ?? id,
      childId: data['childId'] as String? ?? '',
      title: data['title'] as String? ?? '',
      description: data['description'] as String? ?? '',
      type: ActivityType.fromFirestore(data['type'] as String?),
      scheduledDate: dateOnly(readDate(data['scheduledDate']) ?? DateTime.now()),
      startTime: data['startTime'] as String? ?? '09:00',
      endTime: data['endTime'] as String? ?? '10:00',
      completed: data['completed'] as bool? ?? false,
      createdBy: data['createdBy'] as String? ?? '',
      createdAt: readDate(data['createdAt']),
      completedAt: readDate(data['completedAt']),
      pointsAwarded: data['pointsAwarded'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap({required bool isCreate}) {
    return <String, dynamic>{
      'activityId': activityId,
      'childId': childId,
      'title': title,
      'description': description,
      'type': type.firestoreValue,
      'scheduledDate': Timestamp.fromDate(dateOnly(scheduledDate)),
      'startTime': startTime,
      'endTime': endTime,
      'completed': completed,
      'pointsAwarded': pointsAwarded,
      'createdBy': createdBy,
      'createdAt': writeDate(isCreate: isCreate, existing: createdAt),
      if (completedAt != null) 'completedAt': Timestamp.fromDate(completedAt!),
    };
  }
}
