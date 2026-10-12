import 'package:sqflite/sqflite.dart';

import 'database.dart';
import 'models/models.dart';

/// Base class for the table accessors.
///
/// Every write calls [onChanged] once it has committed, which is how the UI
/// learns that it should reload (see `dataRevisionProvider`).
abstract class Dao {
  Dao(this.database, this.onChanged);

  final AppDatabase database;
  final void Function() onChanged;

  Database get db => database.db;

  Future<T> write<T>(Future<T> Function() action) async {
    final result = await action();
    onChanged();
    return result;
  }
}

/// Paid-to-date for one expense row aliased as `x`.
const _paidForExpense =
    '(SELECT COALESCE(SUM(p.amount), 0) FROM payments p WHERE p.expense_id = x.id)';

class EventDao extends Dao {
  EventDao(super.database, super.onChanged);

  Future<List<EventWithTotals>> allWithTotals() async {
    final rows = await db.rawQuery('''
      SELECT e.*,
        COALESCE((SELECT SUM(x.amount) FROM expenses x WHERE x.event_id = e.id), 0) AS committed,
        COALESCE((SELECT SUM(p.amount) FROM payments p
                  JOIN expenses x ON x.id = p.expense_id
                  WHERE x.event_id = e.id), 0) AS paid
      FROM events e
      ORDER BY e.start_date ASC
    ''');
    return rows
        .map(
          (r) => EventWithTotals(
            event: Event.fromMap(r),
            committed: (r['committed'] as num).toDouble(),
            paid: (r['paid'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<Event?> byId(String id) async {
    final rows = await db.query('events', where: 'id = ?', whereArgs: [id]);
    return rows.isEmpty ? null : Event.fromMap(rows.first);
  }

  /// Inserts [event] and, in the same transaction, its starting categories.
  Future<void> insert(
    Event event, {
    List<BudgetCategory> categories = const [],
  }) => write(
    () => db.transaction((txn) async {
      await txn.insert('events', event.toMap());
      for (final c in categories) {
        await txn.insert('categories', c.toMap());
      }
    }),
  );

  Future<void> update(Event event) => write(
    () => db.update(
      'events',
      event.toMap(),
      where: 'id = ?',
      whereArgs: [event.id],
    ),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('events', where: 'id = ?', whereArgs: [id]));
}

class CategoryDao extends Dao {
  CategoryDao(super.database, super.onChanged);

  Future<List<CategoryWithSpend>> withSpend(String eventId) async {
    final rows = await db.rawQuery(
      '''
      SELECT c.*,
        COALESCE(SUM(x.amount), 0) AS committed,
        COALESCE(SUM($_paidForExpense), 0) AS paid,
        COUNT(x.id) AS expense_count
      FROM categories c
      LEFT JOIN expenses x ON x.category_id = c.id
      WHERE c.event_id = ?
      GROUP BY c.id
      ORDER BY c.sort_order, c.name COLLATE NOCASE
    ''',
      [eventId],
    );
    return rows
        .map(
          (r) => CategoryWithSpend(
            category: BudgetCategory.fromMap(r),
            committed: (r['committed'] as num).toDouble(),
            paid: (r['paid'] as num).toDouble(),
            expenseCount: r['expense_count'] as int,
          ),
        )
        .toList();
  }

  Future<int> nextSortOrder(String eventId) async {
    final rows = await db.rawQuery(
      'SELECT COALESCE(MAX(sort_order), -1) + 1 AS next FROM categories WHERE event_id = ?',
      [eventId],
    );
    return rows.first['next'] as int;
  }

  Future<void> insert(BudgetCategory category) =>
      write(() => db.insert('categories', category.toMap()));

  Future<void> insertAll(List<BudgetCategory> categories) => write(() async {
    final batch = db.batch();
    for (final c in categories) {
      batch.insert('categories', c.toMap());
    }
    await batch.commit(noResult: true);
  });

  Future<void> update(BudgetCategory category) => write(
    () => db.update(
      'categories',
      category.toMap(),
      where: 'id = ?',
      whereArgs: [category.id],
    ),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('categories', where: 'id = ?', whereArgs: [id]));
}

class ExpenseDao extends Dao {
  ExpenseDao(super.database, super.onChanged);

  Future<List<Expense>> forEvent(String eventId) async {
    final rows = await db.rawQuery(
      '''
      SELECT x.*, $_paidForExpense AS paid
      FROM expenses x
      WHERE x.event_id = ?
      ORDER BY x.due_date IS NULL, x.due_date, x.created_at DESC
    ''',
      [eventId],
    );
    return rows.map(Expense.fromMap).toList();
  }

  Future<Expense?> byId(String id) async {
    final rows = await db.rawQuery(
      'SELECT x.*, $_paidForExpense AS paid FROM expenses x WHERE x.id = ?',
      [id],
    );
    return rows.isEmpty ? null : Expense.fromMap(rows.first);
  }

  Future<void> insert(Expense expense) =>
      write(() => db.insert('expenses', expense.toMap()));

  Future<void> update(Expense expense) => write(
    () => db.update(
      'expenses',
      expense.toMap(),
      where: 'id = ?',
      whereArgs: [expense.id],
    ),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('expenses', where: 'id = ?', whereArgs: [id]));
}

class PaymentDao extends Dao {
  PaymentDao(super.database, super.onChanged);

  Future<List<Payment>> forExpense(String expenseId) async {
    final rows = await db.query(
      'payments',
      where: 'expense_id = ?',
      whereArgs: [expenseId],
      orderBy: 'date DESC',
    );
    return rows.map(Payment.fromMap).toList();
  }

  Future<void> insert(Payment payment) =>
      write(() => db.insert('payments', payment.toMap()));

  Future<void> delete(String id) =>
      write(() => db.delete('payments', where: 'id = ?', whereArgs: [id]));
}

class TaskDao extends Dao {
  TaskDao(super.database, super.onChanged);

  Future<List<EventTask>> forEvent(String eventId) async {
    final rows = await db.query(
      'tasks',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'is_done, due_date IS NULL, due_date, created_at',
    );
    return rows.map(EventTask.fromMap).toList();
  }

  Future<void> insert(EventTask task) =>
      write(() => db.insert('tasks', task.toMap()));

  Future<void> update(EventTask task) => write(
    () =>
        db.update('tasks', task.toMap(), where: 'id = ?', whereArgs: [task.id]),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('tasks', where: 'id = ?', whereArgs: [id]));
}

class NoteDao extends Dao {
  NoteDao(super.database, super.onChanged);

  Future<List<Note>> forEvent(String eventId) async {
    final rows = await db.query(
      'notes',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'is_pinned DESC, updated_at DESC',
    );
    return rows.map(Note.fromMap).toList();
  }

  Future<void> insert(Note note) =>
      write(() => db.insert('notes', note.toMap()));

  Future<void> update(Note note) => write(
    () =>
        db.update('notes', note.toMap(), where: 'id = ?', whereArgs: [note.id]),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('notes', where: 'id = ?', whereArgs: [id]));
}

class GuestDao extends Dao {
  GuestDao(super.database, super.onChanged);

  Future<List<Guest>> forEvent(String eventId) async {
    final rows = await db.query(
      'guests',
      where: 'event_id = ?',
      whereArgs: [eventId],
      orderBy: 'name COLLATE NOCASE',
    );
    return rows.map(Guest.fromMap).toList();
  }

  Future<void> insert(Guest guest) =>
      write(() => db.insert('guests', guest.toMap()));

  Future<void> update(Guest guest) => write(
    () => db.update(
      'guests',
      guest.toMap(),
      where: 'id = ?',
      whereArgs: [guest.id],
    ),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('guests', where: 'id = ?', whereArgs: [id]));
}

class VendorDao extends Dao {
  VendorDao(super.database, super.onChanged);

  Future<List<VendorWithSpend>> withSpend(String eventId) async {
    final rows = await db.rawQuery(
      '''
      SELECT v.*, COALESCE(SUM(x.amount), 0) AS committed
      FROM vendors v
      LEFT JOIN expenses x ON x.vendor_id = v.id
      WHERE v.event_id = ?
      GROUP BY v.id
      ORDER BY v.name COLLATE NOCASE
    ''',
      [eventId],
    );
    return rows
        .map(
          (r) => VendorWithSpend(
            vendor: Vendor.fromMap(r),
            committed: (r['committed'] as num).toDouble(),
          ),
        )
        .toList();
  }

  Future<void> insert(Vendor vendor) =>
      write(() => db.insert('vendors', vendor.toMap()));

  Future<void> update(Vendor vendor) => write(
    () => db.update(
      'vendors',
      vendor.toMap(),
      where: 'id = ?',
      whereArgs: [vendor.id],
    ),
  );

  Future<void> delete(String id) =>
      write(() => db.delete('vendors', where: 'id = ?', whereArgs: [id]));
}
