import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

class AppUsageItem {
  const AppUsageItem({required this.name, required this.minutes});

  final String name;
  final int minutes;

  factory AppUsageItem.fromMap(Map<String, dynamic> data) {
    return AppUsageItem(
      name: data['name'] as String? ?? 'App',
      minutes: (data['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'name': name,
    'minutes': minutes,
  };
}

class ScreenTimeModel {
  const ScreenTimeModel({
    required this.recordId,
    required this.childId,
    required this.date,
    required this.totalMinutes,
    required this.appUsage,
    this.updatedAt,
    this.source = 'device',
  });

  final String recordId;
  final String childId;
  final String date;
  final int totalMinutes;
  final List<AppUsageItem> appUsage;
  final DateTime? updatedAt;

  /// `device` or `demo`. Never treat demo as live usage.
  final String source;

  bool get isDemo => source == 'demo';

  factory ScreenTimeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ScreenTimeModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory ScreenTimeModel.fromMap(Map<String, dynamic> data, String id) {
    final List<dynamic> raw = data['appUsage'] as List<dynamic>? ?? <dynamic>[];
    return ScreenTimeModel(
      recordId: data['recordId'] as String? ?? id,
      childId: data['childId'] as String? ?? '',
      date: data['date'] as String? ?? dateKey(DateTime.now()),
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      appUsage: raw
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> item) =>
                AppUsageItem.fromMap(Map<String, dynamic>.from(item)),
          )
          .toList(),
      updatedAt: readDate(data['updatedAt']),
      source: data['source'] as String? ?? 'device',
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'recordId': recordId,
      'childId': childId,
      'date': date,
      'totalMinutes': totalMinutes,
      'appUsage': appUsage.map((AppUsageItem item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': source,
    };
  }
}
