import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/firestore_codec.dart';

class GameProgressModel {
  const GameProgressModel({
    required this.progressId,
    required this.childId,
    required this.gameId,
    required this.score,
    required this.bestScore,
    required this.completed,
    this.lastPlayed,
    this.updatedAt,
  });

  final String progressId;
  final String childId;
  final String gameId;
  final int score;
  final int bestScore;
  final bool completed;
  final DateTime? lastPlayed;
  final DateTime? updatedAt;

  factory GameProgressModel.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    return GameProgressModel.fromMap(doc.data() ?? <String, dynamic>{}, doc.id);
  }

  factory GameProgressModel.fromMap(Map<String, dynamic> data, String id) {
    return GameProgressModel(
      progressId: data['progressId'] as String? ?? id,
      childId: data['childId'] as String? ?? '',
      gameId: data['gameId'] as String? ?? '',
      score: (data['score'] as num?)?.toInt() ?? 0,
      bestScore: (data['bestScore'] as num?)?.toInt() ?? 0,
      completed: data['completed'] as bool? ?? false,
      lastPlayed: readDate(data['lastPlayed']),
      updatedAt: readDate(data['updatedAt']),
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'progressId': progressId,
      'childId': childId,
      'gameId': gameId,
      'score': score,
      'bestScore': bestScore,
      'completed': completed,
      'lastPlayed': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
  }
}
