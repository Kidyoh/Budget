import 'package:event_budget/app.dart';
import 'package:event_budget/data/database.dart';
import 'package:event_budget/features/overview/overview_tab.dart';
import 'package:event_budget/state/providers.dart';
import 'package:event_budget/state/settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  Future<void> pumpApp(
    WidgetTester tester, {
    required Size size,
    required double ratio,
    required Map<String, Object> prefs,
  }) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = ratio;
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
      ProviderScope(
        overrides: [
          databaseProvider.overrideWithValue(database),
          sharedPreferencesProvider.overrideWithValue(sharedPrefs),
        ],
        child: const EventBudgetApp(),
      ),
    );
  }

  /// Lets database futures finish and animations play. Pumps for a fixed
  /// time because the onboarding has looping animations.
  Future<void> settle(WidgetTester tester, {int frames = 16}) async {
    for (var i = 0; i < frames; i++) {
      await tester.runAsync(
        () => Future<void>.delayed(const Duration(milliseconds: 10)),
      );
      await tester.pump(const Duration(milliseconds: 100));
    }
  }

  testWidgets('onboarding saves the name and leads to the home screen', (
    tester,
  ) async {
    await pumpApp(tester, size: const Size(1080, 2340), ratio: 3, prefs: {});
    await settle(tester);
    expect(find.textContaining('Plan events'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.north_east_rounded));
    await settle(tester);
    await tester.tap(find.byIcon(Icons.north_east_rounded));
    await settle(tester);
    await tester.enterText(find.byType(TextField), 'Kidus');
    await tester.tap(find.text('Let’s start'));
    await settle(tester);

    expect(find.text('Plan your\nfirst event'), findsOneWidget);
    expect(find.textContaining('Kidus'), findsOneWidget);
    final prefs = await SharedPreferences.getInstance();
    expect(prefs.getBool(SettingsController.onboardedKey), isTrue);
    expect(prefs.getString(SettingsController.nameKey), 'Kidus');
  });

  for (final (name, size, ratio, theme) in [
    ('large phone, light', const Size(1170, 2532), 3.0, 'light'),
    ('small phone, dark', const Size(720, 1280), 2.0, 'dark'),
  ]) {
    testWidgets('sample event and every section render ($name)', (
      tester,
    ) async {
      await pumpApp(
        tester,
        size: size,
        ratio: ratio,
        prefs: {'theme_mode': theme, 'onboarded': true},
      );
      await settle(tester);
      expect(find.text('Plan your\nfirst event'), findsOneWidget);

      await tester.ensureVisible(find.text('Explore a sample event'));
      await tester.pump();
      await tester.tap(find.text('Explore a sample event'));
      await settle(tester, frames: 24);

      expect(find.text('Sara & Daniel’s Wedding'), findsOneWidget);
      expect(find.text('Remaining budget'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Upcoming payments'),
        200,
        scrollable: find.descendant(
          of: find.byType(OverviewTab),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Upcoming payments'), findsOneWidget);

      Future<void> nav(String label) async {
        await tester.tap(find.byTooltip(label));
        await settle(tester);
      }

      await nav('Money');
      expect(find.text('Committed so far'), findsOneWidget);
      await tester.tap(find.text('Expenses'));
      await settle(tester);
      expect(find.text('Still to pay'), findsOneWidget);

      await nav('Tasks');
      expect(find.text('2 of 8 tasks done'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('Mark done').first);
      await settle(tester);
      expect(find.text('3 of 8 tasks done'), findsOneWidget);

      await nav('People');
      expect(find.text('Invited'), findsOneWidget);
      await tester.tap(find.text('Vendors'));
      await settle(tester);
      expect(find.text('DJ Nova'), findsOneWidget);

      await nav('Notes');
      expect(find.text('Day-of timeline'), findsOneWidget);

      // The add button follows the section.
      expect(find.byTooltip('New note'), findsOneWidget);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester, frames: 20);
      expect(find.text('My events'), findsOneWidget);
      expect(find.text('Sara & Daniel’s Wedding'), findsWidgets);
    });
  }
}
