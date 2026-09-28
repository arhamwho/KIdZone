import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../widgets/role_shell.dart';
import '../activities/todays_activities_screen.dart';
import '../learning/learning_games_screen.dart';
import 'achievements_screen.dart';
import 'child_dashboard_screen.dart';
import 'child_profile_screen.dart';

class ChildShell extends StatelessWidget {
  const ChildShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      accent: UserRole.child.accent,
      destinations: <ShellDestination>[
        ShellDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          builder: (_) => const ChildDashboardScreen(),
        ),
        ShellDestination(
          label: 'Activities',
          icon: Icons.checklist_outlined,
          selectedIcon: Icons.checklist_rounded,
          builder: (_) => const TodaysActivitiesScreen(),
        ),
        ShellDestination(
          label: 'Games',
          icon: Icons.extension_outlined,
          selectedIcon: Icons.extension_rounded,
          builder: (_) => const LearningGamesScreen(),
        ),
        ShellDestination(
          label: 'Progress',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
          builder: (_) => const AchievementsScreen(),
        ),
        ShellDestination(
          label: 'Profile',
          icon: Icons.person_outline_rounded,
          selectedIcon: Icons.person_rounded,
          builder: (_) => const ChildProfileScreen(),
        ),
      ],
    );
  }
}
