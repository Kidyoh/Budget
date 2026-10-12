import 'package:event_budget/core/formatters.dart';
import 'package:event_budget/core/widgets/fields.dart';
import 'package:event_budget/data/budget_templates.dart';
import 'package:event_budget/data/csv_export.dart';
import 'package:event_budget/data/models/models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final now = DateTime(2026, 10, 12, 15);

  Expense expense({double amount = 100, double paid = 0, DateTime? due}) =>
      Expense(
        id: 'x',
        eventId: 'e',
        title: 'Thing',
        amount: amount,
        paidAmount: paid,
        dueDate: due,
        createdAt: now,
        updatedAt: now,
      );

  group('Expense.statusAt', () {
    test('unpaid, partial and paid', () {
      expect(expense().statusAt(now), PaymentStatus.unpaid);
      expect(expense(paid: 40).statusAt(now), PaymentStatus.partial);
      expect(expense(paid: 100).statusAt(now), PaymentStatus.paid);
    });

    test('overdue only once the due day has passed', () {
      expect(
        expense(due: DateTime(2026, 10, 12)).statusAt(now),
        PaymentStatus.unpaid,
      );
      expect(
        expense(due: DateTime(2026, 10, 11)).statusAt(now),
        PaymentStatus.overdue,
      );
      expect(
        expense(paid: 100, due: DateTime(2026, 10, 1)).statusAt(now),
        PaymentStatus.paid,
      );
    });

    test('outstanding never goes negative', () {
      expect(expense(paid: 150).outstanding, 0);
      expect(expense(paid: 30).outstanding, 70);
    });
  });

  test('task overdue ignores done tasks and today', () {
    final task = EventTask(
      id: 't',
      eventId: 'e',
      title: 'Call',
      dueDate: DateTime(2026, 10, 11),
      createdAt: now,
    );
    expect(task.isOverdue(now), isTrue);
    expect(task.toggled(now).isOverdue(now), isFalse);
    expect(task.toggled(now).completedAt, now);
  });

  test('event is past only after its last day', () {
    Event event(DateTime start, [DateTime? end]) => Event(
      id: 'e',
      name: 'E',
      type: EventType.party,
      status: EventStatus.planning,
      startDate: start,
      endDate: end,
      totalBudget: 0,
      colorValue: 0,
      createdAt: now,
      updatedAt: now,
    );
    expect(event(DateTime(2026, 10, 12)).isPast(now), isFalse);
    expect(event(DateTime(2026, 10, 11)).isPast(now), isTrue);
    expect(
      event(DateTime(2026, 10, 10), DateTime(2026, 10, 12)).isPast(now),
      isFalse,
    );
  });

  group('budget templates', () {
    test('every template splits exactly 100%', () {
      for (final entry in budgetTemplates.entries) {
        final total = entry.value.fold<double>(0, (s, l) => s + l.share);
        expect(total, closeTo(1, 1e-9), reason: entry.key.name);
      }
    });

    test('allocations add up to the budget after rounding', () {
      final categories = categoriesFromTemplate(
        eventId: 'e',
        type: EventType.wedding,
        totalBudget: 12345.67,
      );
      final total = categories.fold<double>(0, (s, c) => s + c.allocated);
      expect(total, closeTo(12345.67, 1e-6));
      expect(
        categories.map((c) => c.sortOrder),
        List.generate(categories.length, (i) => i),
      );
    });
  });

  test('parseAmount handles separators and junk', () {
    expect(parseAmount('1,250.50'), 1250.5);
    expect(parseAmount(' 300 '), 300);
    expect(parseAmount(''), isNull);
    expect(parseAmount('abc'), isNull);
    expect(amountText(1200), '1200');
    expect(amountText(12.5), '12.50');
  });

  test('relativeDay and initials', () {
    expect(relativeDay(DateTime(2026, 10, 12), now: now), 'Today');
    expect(relativeDay(DateTime(2026, 10, 13), now: now), 'Tomorrow');
    expect(relativeDay(DateTime(2026, 10, 20), now: now), 'In 8 days');
    expect(relativeDay(DateTime(2026, 10, 9), now: now), '3 days ago');
    expect(initials('Hanna Bekele'), 'HB');
    expect(initials('  cher '), 'C');
    expect(initials(''), '?');
  });

  test('CSV export quotes cells that need it', () {
    final csv = expensesCsv(
      expenses: [
        Expense(
          id: 'x',
          eventId: 'e',
          title: 'Cake, "three tier"',
          amount: 550,
          paidAmount: 50,
          notes: 'line1\nline2',
          createdAt: now,
          updatedAt: now,
        ),
      ],
      categories: const [],
      vendors: const [],
      now: now,
    );
    final lines = csv.split('\r\n');
    expect(lines.first, startsWith('Expense,Category,Vendor,Amount'));
    expect(
      lines[1],
      startsWith(
        '"Cake, ""three tier""",Uncategorised,,550.00,50.00,500.00,,Partially paid,"line1',
      ),
    );
  });
}
