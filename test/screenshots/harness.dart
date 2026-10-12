import 'dart:io';

import 'package:event_budget/app.dart';
import 'package:event_budget/data/database.dart';
import 'package:event_budget/state/providers.dart';
import 'package:event_budget/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Where screenshots go; when unset the screenshot tests are skipped.
final String? screenshotDir = Platform.environment['SCREENSHOT_DIR'];

final _boundaryKey = GlobalKey();

/// Loads the real fonts so screenshots show actual text instead of the
/// blocky test font.
Future<void> loadFonts() async {
  final flutterRoot =
      Platform.environment['FLUTTER_ROOT'] ??
      File(Platform.resolvedExecutable)
          .parent
          .parent
          .parent
          .parent
          .parent
          .parent
          .path;
  final materialFonts = '$flutterRoot/bin/cache/artifacts/material_fonts';

  Future<void> load(String family, List<String> files) async {
    final loader = FontLoader(family);
    for (final f in files) {
      final bytes = f.startsWith('assets/')
          ? rootBundle.load(f)
          : File(f).readAsBytes().then((b) => ByteData.view(b.buffer));
      loader.addFont(bytes);
    }
    await loader.load();
  }

  await load('PlusJakartaSans', [
    for (final w in [400, 500, 600, 700, 800])
      'assets/fonts/PlusJakartaSans-w$w.ttf',
  ]);
  await load('MaterialIcons', ['$materialFonts/MaterialIcons-Regular.otf']);
  await load('Roboto', [
    for (final w in ['Regular', 'Medium', 'Bold'])
      '$materialFonts/Roboto-$w.ttf',
  ]);
}

/// Pumps the whole app with an in-memory database.
///
/// The app is laid out at the phone's logical [screen] size and drawn
/// [scale] times larger, so screenshots come out at full device resolution
/// (golden captures are taken at one image pixel per logical pixel).
Future<void> pumpApp(
  WidgetTester tester, {
  Size screen = const Size(360, 780),
  double scale = 3,
  Map<String, Object> prefs = const {},
}) async {
  tester.view.physicalSize = screen * scale;
  tester.view.devicePixelRatio = 1;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues(prefs);
  final sharedPrefs = await SharedPreferences.getInstance();
  final database = (await tester.runAsync(
    () => AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    ),
  ))!;
  addTearDown(() => tester.runAsync(database.close));

  await tester.pumpWidget(
    RepaintBoundary(
      key: _boundaryKey,
      child: _Scaled(
        screen: screen,
        scale: scale,
        child: ProviderScope(
          overrides: [
            databaseProvider.overrideWithValue(database),
            sharedPreferencesProvider.overrideWithValue(sharedPrefs),
          ],
          child: const EventBudgetApp(),
        ),
      ),
    ),
  );
  await settle(tester);
}

/// Lays [child] out at [screen] size with a phone-like MediaQuery, then
/// scales it up to fill the test view.
class _Scaled extends StatelessWidget {
  const _Scaled({
    required this.screen,
    required this.scale,
    required this.child,
  });

  final Size screen;
  final double scale;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final media = MediaQuery.of(context).copyWith(
      size: screen,
      devicePixelRatio: scale,
      padding: EdgeInsets.zero,
      viewPadding: EdgeInsets.zero,
    );
    return MediaQuery(
      data: media,
      child: Align(
        alignment: Alignment.topLeft,
        child: Transform.scale(
          scale: scale,
          alignment: Alignment.topLeft,
          child: SizedBox.fromSize(size: screen, child: child),
        ),
      ),
    );
  }
}

/// Lets database futures complete and animations play out. Pumps for a
/// fixed time because some screens have looping animations.
Future<void> settle(WidgetTester tester, {int frames = 16}) async {
  for (var i = 0; i < frames; i++) {
    await tester.runAsync(
      () => Future<void>.delayed(const Duration(milliseconds: 10)),
    );
    await tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> shoot(WidgetTester tester, String name) async {
  if (screenshotDir == null) return;
  await expectLater(find.byKey(_boundaryKey), matchesGoldenFile('$name.png'));
}

/// Writes every "golden" to [screenshotDir] instead of comparing it.
class ScreenshotWriter extends GoldenFileComparator {
  @override
  Future<bool> compare(Uint8List imageBytes, Uri golden) async {
    await update(golden, imageBytes);
    return true;
  }

  @override
  Future<void> update(Uri golden, Uint8List imageBytes) async {
    final file = File('$screenshotDir/${golden.path}');
    await file.parent.create(recursive: true);
    await file.writeAsBytes(imageBytes);
  }
}
