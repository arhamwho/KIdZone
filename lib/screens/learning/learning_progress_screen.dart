import 'package:flutter/material.dart';

import '../../data/quiz_catalog.dart';
import '../../models/game_progress_model.dart';
import '../../models/learning_game_model.dart';
import '../../models/points_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/game_service.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/status_views.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'Learning',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.user.role == UserRole.child) {
          return _ProgressBody(
            familyId: scope.familyId,
            childId: scope.user.uid,
            childName: scope.user.name,
          );
        }
        if (scope.selectedChild == null) {
          return const MessageView(
            'Add a child to see learning progress.',
            icon: Icons.extension_outlined,
          );
        }
        return Column(
          children: <Widget>[
            ChildPicker(
              children: scope.children,
              selectedId: scope.selectedChild?.uid,
              onSelected: FamilySession.instance.selectChild,
            ),
            const SizedBox(height: AppSpacing.lg),
            Expanded(
              child: _ProgressBody(
                familyId: scope.familyId,
                childId: scope.selectedChild!.uid,
                childName: scope.selectedChild!.name,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({
    required this.familyId,
    required this.childId,
    required this.childName,
  });

  final String familyId;
  final String childId;
  final String childName;

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<PointsModel>(
      stream: GameService.instance.watchPoints(
        familyId: familyId,
        childId: childId,
      ),
      builder: (BuildContext context, AsyncSnapshot<PointsModel> pointsSnap) {
        return StreamBuilder<List<GameProgressModel>>(
          stream: GameService.instance.watchChildProgress(
            familyId: familyId,
            childId: childId,
          ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<GameProgressModel>> gamesSnap,
              ) {
            if (pointsSnap.hasError || gamesSnap.hasError) {
              return const MessageView('Unable to load learning progress.');
            }
            final PointsModel points =
                pointsSnap.data ?? PointsModel.empty(childId);
            final Map<String, GameProgressModel> byId = <String, GameProgressModel>{
              for (final GameProgressModel item
                  in gamesSnap.data ?? <GameProgressModel>[])
                item.gameId: item,
            };
            return ListView(
              children: <Widget>[
                KidCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(childName),
                    subtitle: Text(
                      '${points.points} points · Level ${points.level}',
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final LearningGameModel game in quizCatalog)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: KidCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(game.icon),
                        title: Text(game.title),
                        subtitle: Text(
                          byId[game.gameId]?.completed == true
                              ? 'Best ${byId[game.gameId]!.bestScore}/${game.questions.length}'
                              : 'Not played yet',
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}
