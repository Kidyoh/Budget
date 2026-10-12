import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'harness.dart';

/// Renders the main screens to PNGs for design review:
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

  for (final theme in ['light', 'dark']) {
    testWidgets('tour ($theme)', (tester) async {
      await pumpApp(tester, prefs: {'theme_mode': theme});
      final p = theme == 'light' ? '' : 'dark_';

      await shoot(tester, '${p}01_onboarding_1');
      await tester.tap(find.byIcon(Icons.north_east_rounded));
      await settle(tester);
      await shoot(tester, '${p}02_onboarding_2');
      await tester.tap(find.byIcon(Icons.north_east_rounded));
      await settle(tester);
      await tester.enterText(find.byType(TextField), 'Kidus');
      await settle(tester);
      await shoot(tester, '${p}03_onboarding_3');
      await tester.tap(find.text('Let’s start'));
      await settle(tester);
      await shoot(tester, '${p}04_home_empty');

      await tester.ensureVisible(find.text('Explore a sample event'));
      await tester.pump();
      await tester.tap(find.text('Explore a sample event'));
      await settle(tester, frames: 24);
      await shoot(tester, '${p}05_overview');
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -700));
      await settle(tester);
      await shoot(tester, '${p}06_overview_scrolled');

      await tapNav(tester, 'Money');
      await shoot(tester, '${p}07_budget');
      await tester.tap(find.text('Expenses'));
      await settle(tester);
      await shoot(tester, '${p}08_expenses');
      await tapNav(tester, 'Tasks');
      await shoot(tester, '${p}09_tasks');
      await tapNav(tester, 'People');
      await shoot(tester, '${p}10_guests');
      await tester.tap(find.text('Vendors'));
      await settle(tester);
      await shoot(tester, '${p}11_vendors');
      await tapNav(tester, 'Notes');
      await shoot(tester, '${p}12_notes');

      await tester.tap(find.byTooltip('Back'));
      await settle(tester, frames: 20);
      await shoot(tester, '${p}13_home');

      await tester.tap(find.text('Venue hire').first);
      await settle(tester);
      await shoot(tester, '${p}14_expense_detail');
      await tester.tap(find.byTooltip('Edit'));
      await settle(tester);
      await shoot(tester, '${p}15_expense_form');
      for (var i = 0; i < 2; i++) {
        tester.state<NavigatorState>(find.byType(Navigator)).maybePop();
        await settle(tester);
      }
      await tester.tap(find.byTooltip('Settings').first);
      await settle(tester);
      await shoot(tester, '${p}16_settings');
    }, skip: screenshotDir == null);
  }
}
