import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/daos.dart';
import '../data/database.dart';
import '../data/event_overview.dart';
import '../data/models/models.dart';

/// Overridden in `main()` with the opened database.
final databaseProvider = Provider<AppDatabase>(
  (ref) => throw UnimplementedError('databaseProvider not overridden'),
);

/// Bumped after every database write. Every query provider watches it, so a
/// write anywhere refreshes whatever is on screen.
final dataRevisionProvider = NotifierProvider<DataRevision, int>(
  DataRevision.new,
);

class DataRevision extends Notifier<int> {
  @override
  int build() => 0;

  void bump() => state++;
}

void Function() _notifier(Ref ref) =>
    () => ref.read(dataRevisionProvider.notifier).bump();

final eventDaoProvider = Provider(
  (ref) => EventDao(ref.watch(databaseProvider), _notifier(ref)),
);
final categoryDaoProvider = Provider(
  (ref) => CategoryDao(ref.watch(databaseProvider), _notifier(ref)),
);
final expenseDaoProvider = Provider(
  (ref) => ExpenseDao(ref.watch(databaseProvider), _notifier(ref)),
);
final paymentDaoProvider = Provider(
  (ref) => PaymentDao(ref.watch(databaseProvider), _notifier(ref)),
);
final taskDaoProvider = Provider(
  (ref) => TaskDao(ref.watch(databaseProvider), _notifier(ref)),
);
final noteDaoProvider = Provider(
  (ref) => NoteDao(ref.watch(databaseProvider), _notifier(ref)),
);
final guestDaoProvider = Provider(
  (ref) => GuestDao(ref.watch(databaseProvider), _notifier(ref)),
);
final vendorDaoProvider = Provider(
  (ref) => VendorDao(ref.watch(databaseProvider), _notifier(ref)),
);

final eventsProvider = FutureProvider<List<EventWithTotals>>((ref) {
  ref.watch(dataRevisionProvider);
  return ref.watch(eventDaoProvider).allWithTotals();
});

final eventProvider = FutureProvider.family<Event?, String>((ref, id) {
  ref.watch(dataRevisionProvider);
  return ref.watch(eventDaoProvider).byId(id);
});

final categoriesProvider =
    FutureProvider.family<List<CategoryWithSpend>, String>((ref, eventId) {
      ref.watch(dataRevisionProvider);
      return ref.watch(categoryDaoProvider).withSpend(eventId);
    });

final expensesProvider = FutureProvider.family<List<Expense>, String>((
  ref,
  eventId,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(expenseDaoProvider).forEvent(eventId);
});

final expenseProvider = FutureProvider.family<Expense?, String>((ref, id) {
  ref.watch(dataRevisionProvider);
  return ref.watch(expenseDaoProvider).byId(id);
});

final paymentsProvider = FutureProvider.family<List<Payment>, String>((
  ref,
  expenseId,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(paymentDaoProvider).forExpense(expenseId);
});

final tasksProvider = FutureProvider.family<List<EventTask>, String>((
  ref,
  eventId,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(taskDaoProvider).forEvent(eventId);
});

final notesProvider = FutureProvider.family<List<Note>, String>((ref, eventId) {
  ref.watch(dataRevisionProvider);
  return ref.watch(noteDaoProvider).forEvent(eventId);
});

final guestsProvider = FutureProvider.family<List<Guest>, String>((
  ref,
  eventId,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(guestDaoProvider).forEvent(eventId);
});

final vendorsProvider = FutureProvider.family<List<VendorWithSpend>, String>((
  ref,
  eventId,
) {
  ref.watch(dataRevisionProvider);
  return ref.watch(vendorDaoProvider).withSpend(eventId);
});

/// The Overview tab's figures; null when the event no longer exists.
final overviewProvider = FutureProvider.family<EventOverview?, String>((
  ref,
  eventId,
) async {
  // Watch everything before the first await so all dependencies register.
  final eventFuture = ref.watch(eventProvider(eventId).future);
  final pending = Future.wait<Object>([
    ref.watch(categoriesProvider(eventId).future),
    ref.watch(expensesProvider(eventId).future),
    ref.watch(tasksProvider(eventId).future),
    ref.watch(guestsProvider(eventId).future),
    ref.watch(vendorsProvider(eventId).future),
  ]);
  final event = await eventFuture;
  final results = await pending;
  if (event == null) return null;
  return EventOverview(
    event: event,
    categories: results[0] as List<CategoryWithSpend>,
    expenses: results[1] as List<Expense>,
    tasks: results[2] as List<EventTask>,
    guests: results[3] as List<Guest>,
    vendors: results[4] as List<VendorWithSpend>,
    now: DateTime.now(),
  );
});
