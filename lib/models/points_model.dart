import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../utils/firestore_codec.dart';

enum AchievementId {
  firstActivity,
  firstGame,
  hundredPoints,
  fiveHundredPoints,
  perfectQuiz,
  fiveActivities,
  learningStar;

  String get firestoreValue => name;

  String get label => switch (this) {
    AchievementId.firstActivity => 'First Activity',
    AchievementId.firstGame => 'First Game',
    AchievementId.hundredPoints => '100 Points',
    AchievementId.fiveHundredPoints => '500 Points',
    AchievementId.perfectQuiz => 'Perfect Quiz',
    AchievementId.fiveActivities => '5 Activities Completed',
    AchievementId.learningStar => 'Learning Star',
  };

  String get description => switch (this) {
    AchievementId.firstActivity => 'Finished your first planned activity.',
    AchievementId.firstGame => 'Played your first learning game.',
    AchievementId.hundredPoints => 'Reached 100 family points.',
    AchievementId.fiveHundredPoints => 'Reached 500 family points.',
    AchievementId.perfectQuiz => 'Got every answer right in a quiz.',
    AchievementId.fiveActivities => 'Finished five planned activities.',
    AchievementId.learningStar => 'Completed every learning game.',
  };

  IconData get icon => switch (this) {
    AchievementId.firstActivity => Icons.task_alt_rounded,
    AchievementId.firstGame => Icons.extension_rounded,
    AchievementId.hundredPoints => Icons.stars_rounded,
    AchievementId.fiveHundredPoints => Icons.military_tech_rounded,
    AchievementId.perfectQuiz => Icons.verified_rounded,
    AchievementId.fiveActivities => Icons.playlist_add_check_rounded,
    AchievementId.learningStar => Icons.auto_awesome_rounded,
  };

  static AchievementId? fromValue(String value) {
    for (final AchievementId id in AchievementId.values) {
      if (id.name == value) return id;
    }
    return null;
  }
}

class PointsModel {
  const PointsModel({
    required this.childId,
    required this.points,
    required this.level,
    this.updatedAt,
    this.achievements = const <String>[],
  });

  final String childId;
  final int points;
  final int level;
  final DateTime? updatedAt;
  final List<String> achievements;

  factory PointsModel.empty(String childId) =>
      PointsModel(childId: childId, points: 0, level: 1);

  factory PointsModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return PointsModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory PointsModel.fromMap(Map<String, dynamic> data, String id) {
    final List<dynamic> raw =
        data['achievements'] as List<dynamic>? ?? <dynamic>[];
    return PointsModel(
      childId: data['childId'] as String? ?? id,
      points: (data['points'] as num?)?.toInt() ?? 0,
      level: (data['level'] as num?)?.toInt() ?? 1,
      updatedAt: readDate(data['updatedAt']),
      achievements: raw.map((dynamic item) => item.toString()).toList(),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'childId': childId,
      'points': points,
      'level': level,
      'updatedAt': FieldValue.serverTimestamp(),
      'achievements': achievements,
    };
  }

  /// 0–99 = Level 1, 100–199 = Level 2, and so on.
  static int levelFor(int points) => 1 + (points < 0 ? 0 : points ~/ 100);
}
