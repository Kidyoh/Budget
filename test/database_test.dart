import 'package:event_budget/data/budget_templates.dart';
import 'package:event_budget/data/daos.dart';
import 'package:event_budget/data/database.dart';
import 'package:event_budget/data/event_overview.dart';
import 'package:event_budget/data/models/models.dart';
import 'package:event_budget/data/sample_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late AppDatabase database;
  late int changes;
  final now = DateTime(2026, 10, 12);

  setUpAll(sqfliteFfiInit);

  setUp(() async {
    database = await AppDatabase.open(
      factory: databaseFactoryFfiNoIsolate,
      path: inMemoryDatabasePath,
    );
    changes = 0;
  });

  tearDown(() => database.close());

  void onChanged() => changes++;

  Event event({String id = 'e1', double budget = 1000}) => Event(
    id: id,
    name: 'Party',
    type: EventType.party,
    status: EventStatus.planning,
    startDate: now.add(const Duration(days: 30)),
    totalBudget: budget,
    colorValue: 0xFF000000,
    createdAt: now,
    updatedAt: now,
  );

  Expense expense(
    String id,
    double amount, {
    String? categoryId,
    String? vendorId,
  }) => Expense(
    id: id,
    eventId: 'e1',
    categoryId: categoryId,
    vendorId: vendorId,
    title: id,
    amount: amount,
    createdAt: now,
    updatedAt: now,
  );

  Payment payment(String id, String expenseId, double amount) => Payment(
    id: id,
    expenseId: expenseId,
    amount: amount,
    date: now,
    method: PaymentMethod.cash,
  );

  test(
    'totals roll up from payments to expenses, categories and events',
    () async {
      final events = EventDao(database, onChanged);
      final categories = CategoryDao(database, onChanged);
      final expenses = ExpenseDao(database, onChanged);
      final payments = PaymentDao(database, onChanged);

      final cats = categoriesFromTemplate(
        eventId: 'e1',
        type: EventType.party,
        totalBudget: 1000,
      );
      await events.insert(event(), categories: cats);
      await expenses.insert(expense('a', 300, categoryId: cats.first.id));
      await expenses.insert(expense('b', 200, categoryId: cats.first.id));
      await expenses.insert(expense('c', 50));
      await payments.insert(payment('p1', 'a', 100));
      await payments.insert(payment('p2', 'a', 50));
      await payments.insert(payment('p3', 'c', 50));
      expect(changes, 7);

      final all = await events.allWithTotals();
      expect(all.single.committed, 550);
      expect(all.single.paid, 200);

      final withSpend = await categories.withSpend('e1');
      expect(withSpend.length, cats.length);
      final venue = withSpend.firstWhere((c) => c.category.id == cats.first.id);
      expect(venue.committed, 500);
      expect(venue.paid, 150);
      expect(venue.expenseCount, 2);
      expect(
        withSpend
            .where((c) => c.category.id != cats.first.id)
            .every((c) => c.committed == 0),
        isTrue,
      );

      final a = await expenses.byId('a');
      expect(a!.paidAmount, 150);
      expect(a.statusAt(now), PaymentStatus.partial);
    },
  );

  test('deleting a category keeps its expenses, uncategorised', () async {
    final categories = CategoryDao(database, onChanged);
    final expenses = ExpenseDao(database, onChanged);
    final cats = categoriesFromTemplate(
      eventId: 'e1',
      type: EventType.party,
      totalBudget: 1000,
    );
    await EventDao(database, onChanged).insert(event(), categories: cats);
    await expenses.insert(expense('a', 300, categoryId: cats.first.id));

    await categories.delete(cats.first.id);

    final remaining = await expenses.forEvent('e1');
    expect(remaining.single.categoryId, isNull);
  });

  test('deleting a vendor unlinks its expenses', () async {
    final vendors = VendorDao(database, onChanged);
    final expenses = ExpenseDao(database, onChanged);
    await EventDao(database, onChanged).insert(event());
    await vendors.insert(
      Vendor(id: 'v', eventId: 'e1', name: 'DJ', createdAt: now),
    );
    await expenses.insert(expense('a', 300, vendorId: 'v'));
    expect((await vendors.withSpend('e1')).single.committed, 300);

    await vendors.delete('v');
    expect((await expenses.forEvent('e1')).single.vendorId, isNull);
  });

  test('deleting an event cascades to everything it owns', () async {
    final id = await insertSampleEvent(database, now: now);
    await insertSampleEvent(database, now: now);
    final db = database.db;
    Future<int> count(String table) async =>
        (await db.rawQuery('SELECT COUNT(*) AS n FROM $table')).first['n']
            as int;
    final before = {
      for (final t in [
        'categories',
        'vendors',
        'expenses',
        'payments',
        'tasks',
        'notes',
        'guests',
      ])
        t: await count(t),
    };
    expect(before.values.every((n) => n > 0 && n.isEven), isTrue);

    await EventDao(database, onChanged).delete(id);

    for (final entry in before.entries) {
      expect(await count(entry.key), entry.value ~/ 2, reason: entry.key);
    }
  });

  test('sample event produces a sensible overview', () async {
    final id = await insertSampleEvent(database, now: now);
    final overview = EventOverview(
      event: (await EventDao(database, onChanged).byId(id))!,
      categories: await CategoryDao(database, onChanged).withSpend(id),
      expenses: await ExpenseDao(database, onChanged).forEvent(id),
      tasks: await TaskDao(database, onChanged).forEvent(id),
      guests: await GuestDao(database, onChanged).forEvent(id),
      vendors: await VendorDao(database, onChanged).withSpend(id),
      now: now,
    );
    expect(overview.allocated, closeTo(overview.budget, 0.001));
    expect(overview.committed, 20220);
    expect(overview.paid, 6520);
    expect(overview.daysUntil, 74);
    expect(overview.overdueExpenses.single.title, 'Suit tailoring');
    expect(overview.overdueTasks.single.title, 'Pick up suit after tailoring');
    expect(overview.tasksDone, 2);
    expect(overview.headcount, 2 + 3 + 1 + 2);
    expect(overview.vendorsBooked, 3);
    expect(overview.upcomingPayments.first.title, 'Suit tailoring');
  });

  test('clearAll empties every table', () async {
    await insertSampleEvent(database, now: now);
    await database.clearAll();
    final rows = await database.db.rawQuery(
      "SELECT (SELECT COUNT(*) FROM expenses) + (SELECT COUNT(*) FROM payments) + (SELECT COUNT(*) FROM guests) AS n",
    );
    expect(rows.first['n'], 0);
  });
}
