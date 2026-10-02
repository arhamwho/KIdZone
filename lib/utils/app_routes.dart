import 'package:flutter/material.dart';

import '../models/user_role.dart';
import '../screens/activities/activity_scheduler_screen.dart';
import '../screens/activities/todays_activities_screen.dart';
import '../screens/auth/login_screen.dart';
import '../screens/auth/register_screen.dart';
import '../screens/auth/role_selection_screen.dart';
import '../screens/child/achievements_screen.dart';
import '../screens/child/child_shell.dart';
import '../screens/learning/learning_games_screen.dart';
import '../screens/learning/learning_progress_screen.dart';
import '../screens/learning/quiz_play_screen.dart';
import '../screens/location/location_tracker_screen.dart';
import '../screens/onboarding/onboarding_screen.dart';
import '../screens/onboarding/splash_screen.dart';
import '../screens/parent/add_child_screen.dart';
import '../screens/parent/child_overview_screen.dart';
import '../screens/messages/family_messages_screen.dart';
import '../screens/money/pocket_money_screen.dart';
import '../screens/parent/parent_shell.dart';
import '../screens/reminders/reminders_screen.dart';
import '../screens/screen_time/screen_time_monitor_screen.dart';

/// Named routes for the whole app plus the generator used by `MaterialApp`.
///
/// Keeping every route in one place makes navigation explicit and avoids
/// importing screen files all over the codebase.
class AppRoutes {
  const AppRoutes._();

  // Entry flow: splash -> login / register (or dashboard if already signed in).
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String roleSelection = '/role';
  static const String login = '/login';
  static const String register = '/register';
  static const String addChild = '/parent/add-child';

  // Parent — [parentHome] is the bottom-navigation shell, the rest are
  // pushed on top of it.
  static const String parentHome = '/parent';
  static const String childOverview = '/parent/child-overview';
  static const String activityScheduler = '/parent/scheduler';
  static const String locationTracker = '/parent/location';
  static const String screenTimeMonitor = '/parent/screen-time';
  static const String pocketMoney = '/family/pocket-money';
  static const String familyMessages = '/family/messages';
  static const String reminders = '/family/reminders';

  // Child — [childHome] is the bottom-navigation shell.
  static const String childHome = '/child';
  static const String todaysActivities = '/child/today';
  static const String learningGames = '/child/games';
  static const String quizPlay = '/child/games/play';
  static const String achievements = '/child/achievements';

  static const String learningProgress = '/learning-progress';

  /// Dashboard route for an authenticated role.
  static String homeFor(UserRole role) =>
      role == UserRole.child ? childHome : parentHome;

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    final WidgetBuilder builder = switch (settings.name) {
      splash => (_) => const SplashScreen(),
      onboarding => (_) => const OnboardingScreen(),
      roleSelection => (_) => const RoleSelectionScreen(),
      login => (_) => const LoginScreen(),
      register => (_) => const RegisterScreen(),
      addChild => (_) => const AddChildScreen(),
      parentHome => (_) => const ParentShell(),
      childOverview => (_) => const ChildOverviewScreen(),
      activityScheduler => (_) => const ActivitySchedulerScreen(),
      locationTracker => (_) => const LocationTrackerScreen(),
      screenTimeMonitor => (_) => const ScreenTimeMonitorScreen(),
      pocketMoney => (_) => const PocketMoneyScreen(),
      familyMessages => (_) => const FamilyMessagesScreen(),
      reminders => (_) => const RemindersScreen(),
      childHome => (_) => const ChildShell(),
      todaysActivities => (_) => const TodaysActivitiesScreen(),
      learningGames => (_) => const LearningGamesScreen(),
      quizPlay => (BuildContext context) {
        final Object? args = ModalRoute.of(context)?.settings.arguments;
        return QuizPlayScreen(gameId: args is String ? args : '');
      },
      achievements => (_) => const AchievementsScreen(),
      learningProgress => (_) => const LearningProgressScreen(),
      _ => (_) => _UnknownRouteScreen(routeName: settings.name),
    };

    return MaterialPageRoute<dynamic>(builder: builder, settings: settings);
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen({this.routeName});

  final String? routeName;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page not found')),
      body: Center(
        child: Text('No route defined for "${routeName ?? 'unknown'}".'),
      ),
    );
  }
}
