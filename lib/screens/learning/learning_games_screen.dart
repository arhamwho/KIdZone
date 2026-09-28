import 'package:flutter/material.dart';

import '../../data/quiz_catalog.dart';
import '../../models/game_progress_model.dart';
import '../../models/learning_game_model.dart';
import '../../models/user_role.dart';
import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../utils/app_routes.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';

class LearningGamesScreen extends StatelessWidget {
  const LearningGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: 'Learning Games',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        return StreamBuilder<List<GameProgressModel>>(
          stream: GameService.instance.watchChildProgress(
            familyId: scope.familyId,
            childId: scope.user.uid,
          ),
          builder:
              (
                BuildContext context,
                AsyncSnapshot<List<GameProgressModel>> snap,
              ) {
            final Map<String, GameProgressModel> byId = <String, GameProgressModel>{
              for (final GameProgressModel item in snap.data ?? <GameProgressModel>[])
                item.gameId: item,
            };
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.xxl),
              children: <Widget>[
                Text(
                  'Play, learn and earn points.',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                const SizedBox(height: AppSpacing.lg),
                for (final LearningGameModel game in quizCatalog)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: KidCard(
                      background: AppColors.categoryAt(
                        quizCatalog.indexOf(game),
                      ).withValues(alpha: 0.22),
                      borderColor: Colors.transparent,
                      onTap: () => Navigator.of(context).pushNamed(
                        AppRoutes.quizPlay,
                        arguments: game.gameId,
                      ),
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(game.icon, color: UserRole.child.accent),
                        title: Text(game.title),
                        subtitle: Text(
                          byId[game.gameId]?.completed == true
                              ? 'Best ${byId[game.gameId]!.bestScore}/${game.questions.length}'
                              : game.subtitle,
                        ),
                        trailing: const Icon(Icons.play_arrow_rounded),
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
