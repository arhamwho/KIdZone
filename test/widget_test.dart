import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzone/main.dart';
import 'package:kidzone/screens/auth/login_screen.dart';
import 'package:kidzone/screens/auth/register_screen.dart';
import 'package:kidzone/screens/onboarding/onboarding_screen.dart';
import 'package:kidzone/screens/onboarding/splash_screen.dart';
import 'package:kidzone/screens/parent/parent_shell.dart';
import 'package:kidzone/theme/app_theme.dart';
import 'package:kidzone/utils/app_routes.dart';

void _usePhoneSize(WidgetTester tester, {Size size = const Size(390, 844)}) {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);
}

Future<void> _bootToLogin(WidgetTester tester) async {
  await tester.pumpWidget(const KidZoneApp());
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash shows the brand then moves to login', (
    WidgetTester tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(const KidZoneApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('KidZone'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Onboarding still walks through all three pages', (
    WidgetTester tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(OnboardingScreen), findsOneWidget);
    expect(find.text('A smarter way to care & learn'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Keep track of activities & routines'), findsOneWidget);

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    expect(find.text('Learn, play & earn!'), findsOneWidget);

    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('Login opens the register screen', (WidgetTester tester) async {
    _usePhoneSize(tester);
    await _bootToLogin(tester);

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();

    expect(find.byType(RegisterScreen), findsOneWidget);
    expect(find.text('Create a parent account'), findsOneWidget);
  });

  testWidgets('Login validates empty fields', (WidgetTester tester) async {
    _usePhoneSize(tester);
    await _bootToLogin(tester);

    await tester.tap(find.text('Log in'));
    await tester.pump();

    expect(find.text('Email is required'), findsOneWidget);
    expect(find.text('Password is required'), findsOneWidget);
  });

  testWidgets('Parent shell still switches tabs', (WidgetTester tester) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: AppRoutes.parentHome,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(ParentShell), findsOneWidget);

    NavigationBar bar = tester.widget(find.byType(NavigationBar));
    expect(bar.destinations.length, 5);

    await tester.tap(find.text('Location'));
    await tester.pumpAndSettle();

    bar = tester.widget(find.byType(NavigationBar));
    expect(bar.selectedIndex, 2);
  });

  for (final Size size in <Size>[
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('Login layout is clean at ${size.width.toInt()}dp wide', (
      WidgetTester tester,
    ) async {
      _usePhoneSize(tester, size: size);
      await _bootToLogin(tester);

      expect(find.byType(LoginScreen), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
}
