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

  for (final (name, size, ratio, theme) in [
    ('large phone, light', const Size(1170, 2532), 3.0, 'light'),
    ('small phone, dark', const Size(720, 1280), 2.0, 'dark'),
  ]) {
    testWidgets('empty state, sample event and every tab render ($name)', (
      tester,
    ) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = ratio;
      addTearDown(tester.view.reset);

      SharedPreferences.setMockInitialValues({'theme_mode': theme});
      final prefs = await SharedPreferences.getInstance();
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
            sharedPreferencesProvider.overrideWithValue(prefs),
          ],
          child: const EventBudgetApp(),
        ),
      );

      Future<void> settle() async {
        for (var i = 0; i < 5; i++) {
          await tester.runAsync(
            () => Future<void>.delayed(const Duration(milliseconds: 20)),
          );
          await tester.pumpAndSettle();
        }
      }

      Future<void> openTab(String label) async {
        final tab = find.widgetWithText(Tab, label);
        await tester.ensureVisible(tab);
        await tester.pumpAndSettle();
        await tester.tap(tab);
        await settle();
      }

      await settle();
      expect(find.text('Plan your first event'), findsOneWidget);

      await tester.tap(find.text('Explore a sample event'));
      await settle();

      expect(find.text('Sara & Daniel’s Wedding'), findsOneWidget);
      expect(find.text('days to go'), findsOneWidget);
      await tester.scrollUntilVisible(
        find.text('Spending by category'),
        200,
        scrollable: find.descendant(
          of: find.byType(OverviewTab),
          matching: find.byType(Scrollable),
        ),
      );
      expect(find.text('Spending by category'), findsOneWidget);

      for (final (tab, expected) in [
        ('Budget', 'Allocation'),
        ('Expenses', 'Outstanding'),
        ('Tasks', 'Overdue · 1'),
        ('Notes', 'Day-of timeline'),
        ('Guests', 'Invited'),
        ('Vendors', 'DJ Nova'),
      ]) {
        await openTab(tab);
        expect(find.text(expected), findsWidgets, reason: tab);
      }

      // Completing a task updates the list.
      await openTab('Tasks');
      expect(find.text('2 of 8 tasks done'), findsOneWidget);
      await tester.tap(find.byType(Checkbox).first);
      await settle();
      expect(find.text('3 of 8 tasks done'), findsOneWidget);

      // Back on the home screen the event card shows up.
      await tester.pageBack();
      await settle();
      expect(find.text('Your events'), findsWidgets);
      expect(find.text('Sara & Daniel’s Wedding'), findsOneWidget);
    });
  }
}
