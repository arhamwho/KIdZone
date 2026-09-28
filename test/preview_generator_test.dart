@Tags(<String>['preview'])
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kidzone/main.dart';
import 'package:kidzone/theme/app_theme.dart';
import 'package:kidzone/utils/app_routes.dart';

/// Loads the real Roboto and Material Icons fonts from the Flutter cache so
/// the generated previews show actual text instead of placeholder boxes.
Future<void> _loadFonts() async {
  // The Dart binary lives somewhere under the Flutter cache; walk up until we
  // find the folder holding the bundled fonts.
  Directory? fonts;
  for (
    Directory dir = File(Platform.resolvedExecutable).parent;
    dir.path != dir.parent.path;
    dir = dir.parent
  ) {
    final Directory candidate = Directory(
      '${dir.path}/artifacts/material_fonts',
    );
    if (candidate.existsSync()) {
      fonts = candidate;
      break;
    }
  }
  if (fonts == null) {
    fail('Could not locate the bundled Flutter fonts.');
  }
  final Directory fontsDir = fonts;

  Future<void> load(String family, List<String> files) async {
    final FontLoader loader = FontLoader(family);
    for (final String file in files) {
      final Uint8List bytes = await File(
        '${fontsDir.path}/$file',
      ).readAsBytes();
      loader.addFont(Future<ByteData>.value(ByteData.view(bytes.buffer)));
    }
    await loader.load();
  }

  await load('Roboto', <String>[
    'Roboto-Regular.ttf',
    'Roboto-Medium.ttf',
    'Roboto-Bold.ttf',
    'Roboto-Black.ttf',
  ]);
  await load('MaterialIcons', <String>['MaterialIcons-Regular.otf']);
}

void main() {
  setUpAll(_loadFonts);

  testWidgets('generate design previews', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(780, 1688); // 390 x 844 @2x
    tester.view.devicePixelRatio = 2;
    addTearDown(tester.view.reset);

    final Finder app = find.byType(MaterialApp);

    await tester.pumpWidget(const KidZoneApp());
    await tester.pump(const Duration(milliseconds: 900));
    await expectLater(app, matchesGoldenFile('previews/01_splash.png'));

    await tester.pumpAndSettle();
    await expectLater(app, matchesGoldenFile('previews/05_login.png'));

    await tester.tap(find.text('Create an account'));
    await tester.pumpAndSettle();
    await expectLater(app, matchesGoldenFile('previews/06_register.png'));

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        initialRoute: AppRoutes.onboarding,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/02_onboarding_1.png'),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/03_onboarding_2.png'),
    );

    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('previews/04_onboarding_3.png'),
    );
  });
}
