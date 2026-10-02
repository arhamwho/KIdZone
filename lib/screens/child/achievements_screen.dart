import 'package:flutter/material.dart';

import '../../models/points_model.dart';
import '../../models/user_role.dart';
import '../../services/game_service.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_spacing.dart';
import '../../widgets/family_gate.dart';
import '../../widgets/kid_card.dart';
import '../../widgets/page_header.dart';
import '../../widgets/progress_ring.dart';

class AchievementsScreen extends StatelessWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FamilyGate(
      title: '',
      tint: UserRole.child.tint,
      builder: (BuildContext context, FamilyScope scope) {
        return StreamBuilder<PointsModel>(
          stream: GameService.instance.watchPoints(
            familyId: scope.familyId,
            childId: scope.user.uid,
          ),
          builder: (BuildContext context, AsyncSnapshot<PointsModel> snap) {
            final PointsModel points =
                snap.data ?? PointsModel.empty(scope.user.uid);
            return ListView(
              padding: const EdgeInsets.only(bottom: AppSpacing.navClearance),
              children: <Widget>[
                AppTopBar(
                  title: 'Progress',
                  subtitle: 'Level ${points.level} · ${points.points} pts',
                ),
                const SizedBox(height: AppSpacing.sm),
                KidCard(
                  child: Row(
                    children: <Widget>[
                      ProgressRing(
                        value: (points.points % 100) / 100,
                        label: '${points.points}',
                        caption: 'pts',
                        color: UserRole.child.accent,
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      const Expanded(
                        child: Text(
                          'Keep playing and finishing activities to earn more.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Achievements',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final AchievementId badge in AchievementId.values)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: KidCard(
                      background: points.achievements.contains(badge.firestoreValue)
                          ? AppColors.sunshine.withValues(alpha: 0.28)
                          : null,
                      child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(
                          badge.icon,
                          color: points.achievements.contains(badge.firestoreValue)
                              ? AppColors.sunshineInk
                              : Theme.of(context).colorScheme.outline,
                        ),
                        title: Text(badge.label),
                        subtitle: Text(badge.description),
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
