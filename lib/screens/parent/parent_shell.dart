import 'package:flutter/material.dart';

import '../../models/user_role.dart';
import '../../widgets/role_shell.dart';
import '../activities/activity_scheduler_screen.dart';
import '../learning/learning_progress_screen.dart';
import '../location/location_tracker_screen.dart';
import '../screen_time/screen_time_monitor_screen.dart';
import 'parent_dashboard_screen.dart';

/// Bottom-navigation container for the parent role.
///
/// The child activity overview is not a tab; it is pushed on top of this
/// shell from the dashboard once a specific child is selected.
class ParentShell extends StatelessWidget {
  const ParentShell({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleShell(
      accent: UserRole.parent.accent,
      destinations: <ShellDestination>[
        ShellDestination(
          label: 'Home',
          icon: Icons.home_outlined,
          selectedIcon: Icons.home_rounded,
          builder: (_) => const ParentDashboardScreen(),
        ),
        ShellDestination(
          label: 'Plan',
          icon: Icons.event_note_outlined,
          selectedIcon: Icons.event_note_rounded,
          builder: (_) => const ActivitySchedulerScreen(),
        ),
        ShellDestination(
          label: 'Location',
          icon: Icons.location_on_outlined,
          selectedIcon: Icons.location_on_rounded,
          builder: (_) => const LocationTrackerScreen(),
        ),
        ShellDestination(
          label: 'Screen',
          icon: Icons.timelapse_outlined,
          selectedIcon: Icons.timelapse_rounded,
          builder: (_) => const ScreenTimeMonitorScreen(),
        ),
        ShellDestination(
          label: 'Learning',
          icon: Icons.insights_outlined,
          selectedIcon: Icons.insights_rounded,
          builder: (_) => const LearningProgressScreen(),
        ),
      ],
    );
  }
}
