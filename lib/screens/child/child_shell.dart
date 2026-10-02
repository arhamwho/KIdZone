import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../services/presence_service.dart';
import '../../widgets/role_shell.dart';
import '../activities/todays_activities_screen.dart';
import '../learning/learning_games_screen.dart';
import 'child_dashboard_screen.dart';
import 'child_profile_screen.dart';
import 'child_screen_time_screen.dart';

class ChildShell extends StatefulWidget {
  const ChildShell({super.key});

  @override
  State<ChildShell> createState() => _ChildShellState();
}

class _ChildShellState extends State<ChildShell> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PresenceService.instance.start();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    PresenceService.instance.stop();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      PresenceService.instance.start();
    } else if (state == AppLifecycleState.paused) {
      PresenceService.instance.ping();
    }
  }

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
          label: 'Screen',
          icon: Icons.timelapse_outlined,
          selectedIcon: Icons.timelapse_rounded,
          builder: (_) => const ChildScreenTimeScreen(),
        ),
        ShellDestination(
          label: 'Games',
          icon: Icons.extension_outlined,
          selectedIcon: Icons.extension_rounded,
          builder: (_) => const LearningGamesScreen(),
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
