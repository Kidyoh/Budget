import 'models/models.dart';

/// Everything the Overview tab shows, computed from the event's rows.
class EventOverview {
  EventOverview({
    required this.event,
    required this.categories,
    required this.expenses,
    required this.tasks,
    required this.guests,
    required this.vendors,
    required this.now,
  });

  final Event event;
  final List<CategoryWithSpend> categories;
  final List<Expense> expenses;
  final List<EventTask> tasks;
  final List<Guest> guests;
  final List<VendorWithSpend> vendors;
  final DateTime now;

  double get budget => event.totalBudget;

  late final double allocated = categories.fold(
    0,
    (sum, c) => sum + c.category.allocated,
  );

  late final double committed = expenses.fold(0, (sum, e) => sum + e.amount);

  late final double paid = expenses.fold(0, (sum, e) => sum + e.paidAmount);

  double get outstanding => committed - paid;

  double get remaining => budget - committed;

  double get unallocated => budget - allocated;

  double get usedFraction => budget <= 0 ? 0 : committed / budget;

  bool get isOverBudget => committed > budget + 0.005;

  /// Committed spend that has no category.
  late final double uncategorised = expenses
      .where((e) => e.categoryId == null)
      .fold(0, (sum, e) => sum + e.amount);

  late final List<CategoryWithSpend> overBudgetCategories = categories
      .where((c) => c.isOverBudget)
      .toList();

  late final List<Expense> overdueExpenses = expenses
      .where((e) => e.statusAt(now) == PaymentStatus.overdue)
      .toList();

  /// Unpaid expenses that have a due date, soonest first.
  late final List<Expense> upcomingPayments =
      (expenses.where((e) => e.outstanding > 0 && e.dueDate != null).toList()
        ..sort((a, b) => a.dueDate!.compareTo(b.dueDate!)));

  int get taskCount => tasks.length;
  late final int tasksDone = tasks.where((t) => t.isDone).length;
  double get taskProgress => tasks.isEmpty ? 0 : tasksDone / tasks.length;

  late final List<EventTask> overdueTasks = tasks
      .where((t) => t.isOverdue(now))
      .toList();

  /// Open tasks, those with a due date first and soonest first.
  late final List<EventTask> nextTasks = (tasks.where((t) => !t.isDone).toList()
    ..sort((a, b) {
      if (a.dueDate == null && b.dueDate == null) return 0;
      if (a.dueDate == null) return 1;
      if (b.dueDate == null) return -1;
      return a.dueDate!.compareTo(b.dueDate!);
    }));

  int rsvpCount(RsvpStatus status) =>
      guests.where((g) => g.rsvp == status).length;

  /// Expected headcount: attending guests and their plus-ones.
  late final int headcount = guests
      .where((g) => g.rsvp == RsvpStatus.attending)
      .fold(0, (sum, g) => sum + g.partySize);

  late final int vendorsBooked = vendors
      .where((v) => v.vendor.status == VendorStatus.booked)
      .length;

  /// Whole days from today until the event starts; negative once started.
  int get daysUntil {
    // UTC dates so a daylight-saving change in between can't shave off a day.
    final today = DateTime.utc(now.year, now.month, now.day);
    final s = event.startDate;
    return DateTime.utc(s.year, s.month, s.day).difference(today).inDays;
  }
}
