import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

class AppUsageModel {
  const AppUsageModel({
    required this.packageName,
    required this.appName,
    required this.minutes,
  });

  final String packageName;
  final String appName;
  final int minutes;

  /// Display name used by existing list rows.
  String get name => appName;

  factory AppUsageModel.fromMap(Map<String, dynamic> data) {
    final String appName =
        data['appName'] as String? ?? data['name'] as String? ?? 'App';
    return AppUsageModel(
      packageName: data['packageName'] as String? ?? '',
      appName: appName,
      minutes: (data['minutes'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => <String, dynamic>{
    'packageName': packageName,
    'appName': appName,
    'name': appName,
    'minutes': minutes,
  };
}

typedef AppUsageItem = AppUsageModel;

enum ScreenTimeLevel { empty, normal, warning, exceeded }

class ScreenTimeModel {
  const ScreenTimeModel({
    required this.recordId,
    required this.childId,
    required this.date,
    required this.totalMinutes,
    required this.appUsage,
    this.dailyLimitMinutes = 120,
    this.updatedAt,
    this.source = 'device',
  });

  final String recordId;
  final String childId;
  final String date;
  final int totalMinutes;
  final int dailyLimitMinutes;
  final List<AppUsageModel> appUsage;
  final DateTime? updatedAt;

  /// `device`, `demo`, or `unavailable`.
  final String source;

  bool get isDemo => source == 'demo';

  bool get isToday => date == dateKey(DateTime.now());

  int get remainingMinutes {
    final int left = dailyLimitMinutes - totalMinutes;
    return left < 0 ? 0 : left;
  }

  double get percentage {
    if (dailyLimitMinutes <= 0) return 0;
    return totalMinutes / dailyLimitMinutes;
  }

  ScreenTimeLevel levelFor(int limit) {
    if (limit <= 0) return ScreenTimeLevel.empty;
    final double value = totalMinutes / limit;
    if (value > 1) return ScreenTimeLevel.exceeded;
    if (value >= 0.75) return ScreenTimeLevel.warning;
    return ScreenTimeLevel.normal;
  }

  ScreenTimeModel withLimit(int limit) {
    return ScreenTimeModel(
      recordId: recordId,
      childId: childId,
      date: date,
      totalMinutes: totalMinutes,
      dailyLimitMinutes: limit,
      appUsage: appUsage,
      updatedAt: updatedAt,
      source: source,
    );
  }

  factory ScreenTimeModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return ScreenTimeModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory ScreenTimeModel.fromMap(Map<String, dynamic> data, String id) {
    final List<dynamic> raw = data['appUsage'] as List<dynamic>? ?? <dynamic>[];
    return ScreenTimeModel(
      recordId: data['recordId'] as String? ?? data['childId'] as String? ?? id,
      childId: data['childId'] as String? ?? id,
      date: data['date'] as String? ?? dateKey(DateTime.now()),
      totalMinutes: (data['totalMinutes'] as num?)?.toInt() ?? 0,
      dailyLimitMinutes:
          (data['dailyLimitMinutes'] as num?)?.toInt() ?? 120,
      appUsage: raw
          .whereType<Map<dynamic, dynamic>>()
          .map(
            (Map<dynamic, dynamic> item) =>
                AppUsageModel.fromMap(Map<String, dynamic>.from(item)),
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
      'dailyLimitMinutes': dailyLimitMinutes,
      'appUsage': appUsage.map((AppUsageModel item) => item.toMap()).toList(),
      'updatedAt': FieldValue.serverTimestamp(),
      'source': source,
    };
  }
}
