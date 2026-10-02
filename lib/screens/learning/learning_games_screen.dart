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
import '../../widgets/feature_tile.dart';
import '../../widgets/page_header.dart';

class LearningGamesScreen extends StatelessWidget {
  const LearningGamesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
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
            final Map<String, GameProgressModel> byId =
                <String, GameProgressModel>{
              for (final GameProgressModel item
                  in snap.data ?? <GameProgressModel>[])
                item.gameId: item,
            };
            return Column(
              children: <Widget>[
                const AppTopBar(title: 'Games'),
                Expanded(
                  child: GridView.builder(
                    padding: const EdgeInsets.only(
                      bottom: AppSpacing.navClearance,
                    ),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: AppSpacing.md,
                      crossAxisSpacing: AppSpacing.md,
                      childAspectRatio: 1.05,
                    ),
                    itemCount: quizCatalog.length,
                    itemBuilder: (BuildContext context, int index) {
                      final LearningGameModel game = quizCatalog[index];
                      final GameProgressModel? progress = byId[game.gameId];
                      return FeatureTile(
                        color: AppColors.categoryAt(index),
                        icon: game.icon,
                        title: game.title,
                        subtitle: progress?.completed == true
                            ? 'Best ${progress!.bestScore}/${game.questions.length}'
                            : game.subtitle,
                        onTap: () => Navigator.of(context).pushNamed(
                          AppRoutes.quizPlay,
                          arguments: game.gameId,
                        ),
                      );
                    },
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
