import 'package:cloud_firestore/cloud_firestore.dart';

import '../data/quiz_catalog.dart';
import '../models/game_progress_model.dart';
import '../models/learning_game_model.dart';
import '../models/points_model.dart';
import 'firestore_errors.dart';
import 'firestore_service.dart';

class GameService {
  GameService({FirestoreService? firestore})
    : _db = firestore ?? FirestoreService.instance;

  static final GameService instance = GameService();

  final FirestoreService _db;

  List<LearningGameModel> get catalog => quizCatalog;

  LearningGameModel? gameById(String gameId) {
    for (final LearningGameModel game in quizCatalog) {
      if (game.gameId == gameId) return game;
    }
    return null;
  }

  Stream<List<GameProgressModel>> watchProgress(String familyId) {
    return _db
        .gameProgress(familyId)
        .snapshots()
        .map(
          (QuerySnapshot<Map<String, dynamic>> snapshot) =>
              snapshot.docs.map(GameProgressModel.fromFirestore).toList(),
        )
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Stream<List<GameProgressModel>> watchChildProgress({
    required String familyId,
    required String childId,
  }) {
    return watchProgress(familyId).map(
      (List<GameProgressModel> items) => items
          .where((GameProgressModel item) => item.childId == childId)
          .toList(),
    );
  }

  Stream<PointsModel> watchPoints({
    required String familyId,
    required String childId,
  }) {
    return _db
        .points(familyId)
        .doc(childId)
        .snapshots()
        .map((DocumentSnapshot<Map<String, dynamic>> doc) {
          if (!doc.exists) return PointsModel.empty(childId);
          return PointsModel.fromFirestore(doc);
        })
        .handleError((Object error, StackTrace stackTrace) {
          Error.throwWithStackTrace(
            FirestoreException(friendlyFirestoreMessage(error)),
            stackTrace,
          );
        });
  }

  Future<void> saveQuizResult({
    required String familyId,
    required String childId,
    required String gameId,
    required int score,
    required int maxScore,
  }) async {
    try {
      final bool perfect = score == maxScore && maxScore > 0;
      final String progressId = '${childId}_$gameId';
      final DocumentReference<Map<String, dynamic>> doc = _db
          .gameProgress(familyId)
          .doc(progressId);
      final DocumentSnapshot<Map<String, dynamic>> existing = await doc.get();
      final int previousBest = existing.exists
          ? GameProgressModel.fromFirestore(existing).bestScore
          : 0;
      final GameProgressModel progress = GameProgressModel(
        progressId: progressId,
        childId: childId,
        gameId: gameId,
        score: score,
        bestScore: score > previousBest ? score : previousBest,
        completed: true,
      );
      await doc.set(progress.toMap());

      await awardPoints(
        familyId: familyId,
        childId: childId,
        amount: perfect ? 30 : 20,
        unlock: AchievementId.firstGame,
      );
      await _maybeUnlockLearningStar(familyId: familyId, childId: childId);
    } catch (error) {
      if (error is FirestoreException) rethrow;
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> awardPoints({
    required String familyId,
    required String childId,
    required int amount,
    AchievementId? unlock,
  }) async {
    try {
      final DocumentReference<Map<String, dynamic>> doc = _db
          .points(familyId)
          .doc(childId);
      await FirebaseFirestore.instance.runTransaction((
        Transaction transaction,
      ) async {
        final DocumentSnapshot<Map<String, dynamic>> snap = await transaction
            .get(doc);
        final PointsModel current = snap.exists
            ? PointsModel.fromFirestore(snap)
            : PointsModel.empty(childId);
        final int nextPoints = current.points + amount;
        final List<String> badges = List<String>.from(current.achievements);
        if (unlock != null && !badges.contains(unlock.firestoreValue)) {
          badges.add(unlock.firestoreValue);
        }
        if (nextPoints >= 100 &&
            !badges.contains(AchievementId.hundredPoints.firestoreValue)) {
          badges.add(AchievementId.hundredPoints.firestoreValue);
        }
        final PointsModel next = PointsModel(
          childId: childId,
          points: nextPoints,
          level: PointsModel.levelFor(nextPoints),
          achievements: badges,
        );
        transaction.set(doc, next.toMap());
      });
    } catch (error) {
      throw FirestoreException(friendlyFirestoreMessage(error));
    }
  }

  Future<void> _maybeUnlockLearningStar({
    required String familyId,
    required String childId,
  }) async {
    final QuerySnapshot<Map<String, dynamic>> snapshot = await _db
        .gameProgress(familyId)
        .where('childId', isEqualTo: childId)
        .get();
    final Set<String> completed = snapshot.docs
        .map(GameProgressModel.fromFirestore)
        .where((GameProgressModel item) => item.completed)
        .map((GameProgressModel item) => item.gameId)
        .toSet();
    final bool allDone = quizCatalog.every(
      (LearningGameModel game) => completed.contains(game.gameId),
    );
    if (!allDone) return;
    await awardPoints(
      familyId: familyId,
      childId: childId,
      amount: 0,
      unlock: AchievementId.learningStar,
    );
  }
}
