import 'package:flutter/material.dart';

import '../../data/quiz_catalog.dart';
import '../../models/game_progress_model.dart';
import '../../models/points_model.dart';
import '../../models/user_role.dart';
import '../../services/family_session.dart';
import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/child_picker.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/status_views.dart';

class LearningProgressScreen extends StatelessWidget {
  const LearningProgressScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.parent.tint,
      builder: (BuildContext context, FamilyScope scope) {
        if (scope.user.role == UserRole.child) {
          return Column(
            children: <Widget>[
              const AppTopBar(title: 'Learning'),
              Expanded(
                child: _ProgressBody(
                  familyId: scope.familyId,
                  childId: scope.user.uid,
                  childName: scope.user.name,
                ),
              ),
            ],
          );
        }
        if (scope.selectedChild == null) {
          return const Column(
            children: <Widget>[
              AppTopBar(title: 'Learning'),
              Expanded(
                child: MessageView(
                  'Add a child to see learning progress.',
                  icon: Icons.extension_outlined,
                ),
              ),
            ],
          );
        }
        return Column(
          children: <Widget>[
            const AppTopBar(title: 'Learning'),
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
            final int gamesDone = byId.values
                .where((GameProgressModel item) => item.completed)
                .length;
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
              children: <Widget>[
                InsightCard(
                  tiles: <InsightTile>[
                    InsightTile(
                      icon: Icons.star_rounded,
                      value: '${points.points}',
                      label: 'Level ${points.level}',
                      color: AppColors.tileOrange,
                    ),
                    InsightTile(
                      icon: Icons.extension_rounded,
                      value: '$gamesDone',
                      label: 'games done',
                      color: AppColors.tilePurple,
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                for (int i = 0; i < quizCatalog.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: KidCard(
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: AppColors.categoryAt(i),
                          child: Icon(
                            quizCatalog[i].icon,
                            color: Colors.white,
                          ),
                        ),
                        title: Text(quizCatalog[i].title),
                        subtitle: Text(
                          byId[quizCatalog[i].gameId]?.completed == true
                              ? 'Latest ${byId[quizCatalog[i].gameId]!.score}/${quizCatalog[i].questions.length} · Best ${byId[quizCatalog[i].gameId]!.bestScore}/${quizCatalog[i].questions.length}'
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
