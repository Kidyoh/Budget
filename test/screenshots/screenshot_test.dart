import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'harness.dart';

/// Renders every screen to PNGs (1080x2340) for design review and the
/// Figma import pack:
///   SCREENSHOT_DIR=/some/dir flutter test test/screenshots
void main() {
  setUpAll(() async {
    sqfliteFfiInit();
    await loadFonts();
    goldenFileComparator = ScreenshotWriter();
  });

  Future<void> tapNav(WidgetTester tester, String label) async {
    await tester.tap(find.byTooltip(label));
    await settle(tester);
  }

  Future<void> back(WidgetTester tester) async {
    tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
    await settle(tester);
  }

  Future<void> openSample(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Explore a sample event'));
    await tester.pump();
    await tester.tap(find.text('Explore a sample event'));
    await settle(tester, frames: 24);
  }

  for (final theme in ['light', 'dark']) {
    testWidgets('tour ($theme)', (tester) async {
      await pumpApp(tester, prefs: {'theme_mode': theme});
      final dir = '$theme/';
      var n = 0;
      Future<void> shot(String name) =>
          shoot(tester, '$dir${(++n).toString().padLeft(2, '0')} $name');

      await shot('Onboarding 1 - Plan events');
      await tester.tap(find.byIcon(Icons.north_east_rounded));
      await settle(tester);
      await shot('Onboarding 2 - Every birr');
      await tester.tap(find.byIcon(Icons.north_east_rounded));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Kidus');
      await settle(tester);
      await shot('Onboarding 3 - Your people');
      await tester.tap(find.text('Let’s start'));
      await settle(tester);
      await shot('Home - first run');

      await openSample(tester);
      await shot('Event - Overview');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await settle(tester);
      await shot('Event - Overview (scrolled)');

      await tapNav(tester, 'Money');
      await shot('Event - Budget');
      await tester.tap(find.text('Venue').last);
      await settle(tester);
      await shot('Category detail');
      await back(tester);
      await tester.tap(find.text('Expenses'));
      await settle(tester);
      await shot('Event - Expenses');
      await tester.tap(find.text('Venue hire').first);
      await settle(tester);
      await shot('Expense detail');
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await shot('Expense form');
      await back(tester);
      await back(tester);

      await tapNav(tester, 'Tasks');
      await shot('Event - Tasks');
      await tapNav(tester, 'People');
      await shot('Event - Guests');
      await tester.tap(find.text('Vendors'));
      await settle(tester);
      await shot('Event - Vendors');
      await tapNav(tester, 'Notes');
      await shot('Event - Notes');
      await tester.tap(find.text('Day-of timeline'));
      await settle(tester);
      await shot('Note editor');
      await back(tester);

      await tester.tap(find.byTooltip('More'));
      await settle(tester);
      await shot('Event - More actions');
      await back(tester);

      await tester.tap(find.byTooltip('Back'));
      await settle(tester, frames: 20);
      await shot('Home');

      await tester.tap(find.text('All events'));
      await settle(tester);
      await shot('All events');
      await tester.tap(find.byTooltip('New event'));
      await settle(tester);
      await shot('New event form');
      await back(tester);
      await back(tester);

      await tester.tap(find.byTooltip('Settings').first);
      await settle(tester);
      await shot('Settings');
    }, skip: screenshotDir == null);

    testWidgets('full-length pages ($theme)', (tester) async {
      await pumpApp(
        tester,
        screen: const Size(360, 2160),
        prefs: {'theme_mode': theme, 'onboarded': true, 'name': 'Kidus'},
      );
      await openSample(tester);
      await shoot(tester, 'full-length/$theme - Event overview');
      await tester.tap(find.byTooltip('Money'));
      await settle(tester);
      await shoot(tester, 'full-length/$theme - Budget');
      await tester.tap(find.byTooltip('Back'));
      await settle(tester, frames: 20);
      await shoot(tester, 'full-length/$theme - Home');
    }, skip: screenshotDir == null);
  }
}
