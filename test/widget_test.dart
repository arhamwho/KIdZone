import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzone/main.dart';
import 'package:kidzone/screens/auth/login_screen.dart';
import 'package:kidzone/screens/auth/register_screen.dart';
import 'package:kidzone/screens/onboarding/onboarding_screen.dart';
import 'package:kidzone/screens/onboarding/splash_screen.dart';
import 'package:kidzone/screens/money/pocket_money_screen.dart';
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
  await tester.tap(find.text('Skip'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('Splash shows the brand then moves to onboarding', (
    WidgetTester tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(const KidZoneApp());

    expect(find.byType(SplashScreen), findsOneWidget);
    expect(find.text('KidZone'), findsOneWidget);

    await tester.pumpAndSettle();
    expect(find.byType(OnboardingScreen), findsOneWidget);
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

  testWidgets('Plan tab keeps New activity above the navigation bar', (
    WidgetTester tester,
  ) async {
    _usePhoneSize(tester);
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: AppRoutes.parentHome,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    expect(find.text('New activity'), findsOneWidget);
    final Rect fab = tester.getRect(
      find.widgetWithText(FloatingActionButton, 'New activity'),
    );
    final Rect nav = tester.getRect(find.byType(NavigationBar));
    expect(fab.bottom, lessThanOrEqualTo(nav.top - 8));

    await tester.tap(find.text('New activity'));
    await tester.pumpAndSettle();
    expect(find.text('Please choose a child first.'), findsOneWidget);
  });

  for (final Size size in <Size>[
    const Size(320, 640),
    const Size(360, 800),
    const Size(390, 844),
    const Size(412, 915),
  ]) {
    testWidgets('Set Allowance stays on one line at ${size.width.toInt()}dp', (
      WidgetTester tester,
    ) async {
      _usePhoneSize(tester, size: size);
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 36),
              child: Align(
                alignment: Alignment.topCenter,
                child: PocketMoneyActions(onSend: () {}, onSetAllowance: () {}),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final Size allowance = tester.getSize(find.text('Set Allowance'));
      final Size send = tester.getSize(find.text('Send Money'));
      expect(allowance.height, lessThan(28));
      expect(send.height, lessThan(28));

      final Size allowanceButton = tester.getSize(
        find.widgetWithText(OutlinedButton, 'Set Allowance'),
      );
      final Size sendButton = tester.getSize(
        find.widgetWithText(FilledButton, 'Send Money'),
      );
      expect(allowanceButton.height, sendButton.height);
      expect(allowanceButton.width, greaterThan(sendButton.width));
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('New activity stays above the nav with a system inset', (
    WidgetTester tester,
  ) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    tester.view.viewPadding = const FakeViewPadding(bottom: 48);
    tester.view.padding = const FakeViewPadding(bottom: 48);
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: AppRoutes.parentHome,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Plan'));
    await tester.pumpAndSettle();

    final Rect fab = tester.getRect(
      find.widgetWithText(FloatingActionButton, 'New activity'),
    );
    final Rect nav = tester.getRect(find.byType(NavigationBar));
    expect(fab.bottom, lessThanOrEqualTo(nav.top - 8));
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
