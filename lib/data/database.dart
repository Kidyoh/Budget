import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';

/// Owns the SQLite connection and the schema.
///
/// Child rows reference their event with `ON DELETE CASCADE`, so deleting an
/// event removes everything that belongs to it. Expenses keep existing when
/// their category or vendor is deleted; the link is set to null instead.
class AppDatabase {
  AppDatabase._(this.db);

  final Database db;

  static const schemaVersion = 1;
  static const fileName = 'event_budget.db';

  static Future<AppDatabase> open({
    DatabaseFactory? factory,
    String? path,
  }) async {
    final dbFactory = factory ?? databaseFactory;
    final dbPath = path ?? p.join(await dbFactory.getDatabasesPath(), fileName);
    final db = await dbFactory.openDatabase(
      dbPath,
      options: OpenDatabaseOptions(
        version: schemaVersion,
        onConfigure: (db) => db.execute('PRAGMA foreign_keys = ON'),
        onCreate: (db, _) => _createSchema(db),
      ),
    );
    return AppDatabase._(db);
  }

  Future<void> close() => db.close();

  /// Removes every row from every table, keeping the schema.
  Future<void> clearAll() async {
    // Children first is not required thanks to the cascades, but deleting
    // events alone would leave nothing behind anyway.
    await db.delete('events');
  }

  static Future<void> _createSchema(Database db) async {
    final batch = db.batch();
    batch.execute('''
      CREATE TABLE events (
        id TEXT PRIMARY KEY,
        name TEXT NOT NULL,
        type TEXT NOT NULL,
        status TEXT NOT NULL,
        start_date INTEGER NOT NULL,
        end_date INTEGER,
        location TEXT NOT NULL DEFAULT '',
        description TEXT NOT NULL DEFAULT '',
        total_budget REAL NOT NULL DEFAULT 0,
        color INTEGER NOT NULL,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE categories (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        icon TEXT NOT NULL,
        color INTEGER NOT NULL,
        allocated REAL NOT NULL DEFAULT 0,
        sort_order INTEGER NOT NULL DEFAULT 0
      )
    ''');
    batch.execute('''
      CREATE TABLE vendors (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        service TEXT NOT NULL DEFAULT '',
        contact_name TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        email TEXT NOT NULL DEFAULT '',
        website TEXT NOT NULL DEFAULT '',
        quote REAL,
        status TEXT NOT NULL,
        rating INTEGER NOT NULL DEFAULT 0,
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE expenses (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        category_id TEXT REFERENCES categories(id) ON DELETE SET NULL,
        vendor_id TEXT REFERENCES vendors(id) ON DELETE SET NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        due_date INTEGER,
        notes TEXT NOT NULL DEFAULT '',
        receipt_path TEXT,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE payments (
        id TEXT PRIMARY KEY,
        expense_id TEXT NOT NULL REFERENCES expenses(id) ON DELETE CASCADE,
        amount REAL NOT NULL,
        date INTEGER NOT NULL,
        method TEXT NOT NULL,
        note TEXT NOT NULL DEFAULT ''
      )
    ''');
    batch.execute('''
      CREATE TABLE tasks (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        title TEXT NOT NULL,
        notes TEXT NOT NULL DEFAULT '',
        due_date INTEGER,
        priority TEXT NOT NULL,
        is_done INTEGER NOT NULL DEFAULT 0,
        completed_at INTEGER,
        created_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE notes (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        title TEXT NOT NULL DEFAULT '',
        body TEXT NOT NULL DEFAULT '',
        is_pinned INTEGER NOT NULL DEFAULT 0,
        color INTEGER,
        created_at INTEGER NOT NULL,
        updated_at INTEGER NOT NULL
      )
    ''');
    batch.execute('''
      CREATE TABLE guests (
        id TEXT PRIMARY KEY,
        event_id TEXT NOT NULL REFERENCES events(id) ON DELETE CASCADE,
        name TEXT NOT NULL,
        email TEXT NOT NULL DEFAULT '',
        phone TEXT NOT NULL DEFAULT '',
        group_name TEXT NOT NULL DEFAULT '',
        rsvp TEXT NOT NULL,
        plus_ones INTEGER NOT NULL DEFAULT 0,
        dietary TEXT NOT NULL DEFAULT '',
        table_name TEXT NOT NULL DEFAULT '',
        notes TEXT NOT NULL DEFAULT '',
        created_at INTEGER NOT NULL
      )
    ''');
    for (final table in [
      'categories',
      'vendors',
      'expenses',
      'tasks',
      'notes',
      'guests',
    ]) {
      batch.execute('CREATE INDEX idx_${table}_event ON $table(event_id)');
    }
    batch.execute('CREATE INDEX idx_payments_expense ON payments(expense_id)');
    await batch.commit(noResult: true);
  }
}
