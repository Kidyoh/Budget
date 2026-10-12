import '../core/id.dart';
import '../core/palette.dart';
import 'budget_templates.dart';
import 'database.dart';
import 'models/models.dart';

/// Inserts a realistic demo wedding so the app can be explored without
/// typing everything in. Returns the new event's id.
Future<String> insertSampleEvent(AppDatabase database, {DateTime? now}) async {
  final today = now ?? DateTime.now();
  DateTime day(int offset) =>
      DateTime(today.year, today.month, today.day + offset);

  final eventId = newId();
  final event = Event(
    id: eventId,
    name: 'Sara & Daniel’s Wedding',
    type: EventType.wedding,
    status: EventStatus.confirmed,
    startDate: day(74),
    location: 'Lakeside Garden Venue',
    description: 'Garden ceremony at 3pm followed by dinner and dancing.',
    totalBudget: 25000,
    colorValue: accentPalette[0],
    createdAt: today,
    updatedAt: today,
  );

  final categories = categoriesFromTemplate(
    eventId: eventId,
    type: EventType.wedding,
    totalBudget: event.totalBudget,
  );
  String cat(String name) => categories.firstWhere((c) => c.name == name).id;

  Vendor vendor(
    String name,
    String service,
    VendorStatus status, {
    double? quote,
    int rating = 0,
    String phone = '',
    String email = '',
  }) => Vendor(
    id: newId(),
    eventId: eventId,
    name: name,
    service: service,
    status: status,
    quote: quote,
    rating: rating,
    phone: phone,
    email: email,
    createdAt: today,
  );

  final venue = vendor(
    'Lakeside Garden',
    'Venue',
    VendorStatus.booked,
    quote: 6000,
    rating: 5,
    phone: '+1 555 0100',
    email: 'events@lakeside.example',
  );
  final caterer = vendor(
    'Olive & Thyme Catering',
    'Catering',
    VendorStatus.booked,
    quote: 6500,
    rating: 4,
    phone: '+1 555 0142',
  );
  final photo = vendor(
    'Golden Hour Studio',
    'Photography',
    VendorStatus.booked,
    quote: 2400,
    rating: 5,
    email: 'hello@goldenhour.example',
  );
  final florist = vendor(
    'Petal Theory',
    'Flowers',
    VendorStatus.quoted,
    quote: 1900,
    rating: 4,
  );
  final dj = vendor('DJ Nova', 'Music', VendorStatus.contacted);
  final vendors = [venue, caterer, photo, florist, dj];

  final expenses = <Expense>[];
  final payments = <Payment>[];
  void expense(
    String title,
    double amount,
    String category, {
    Vendor? by,
    int? dueIn,
    List<(double, int, PaymentMethod)> paid = const [],
  }) {
    final id = newId();
    expenses.add(
      Expense(
        id: id,
        eventId: eventId,
        categoryId: cat(category),
        vendorId: by?.id,
        title: title,
        amount: amount,
        dueDate: dueIn == null ? null : day(dueIn),
        createdAt: today,
        updatedAt: today,
      ),
    );
    for (final (value, daysAgo, method) in paid) {
      payments.add(
        Payment(
          id: newId(),
          expenseId: id,
          amount: value,
          date: day(-daysAgo),
          method: method,
        ),
      );
    }
  }

  expense(
    'Venue hire',
    6000,
    'Venue',
    by: venue,
    dueIn: 30,
    paid: [(2000, 40, PaymentMethod.bankTransfer)],
  );
  expense(
    'Dinner for 120 guests',
    6500,
    'Catering',
    by: caterer,
    dueIn: 60,
    paid: [(1500, 20, PaymentMethod.bankTransfer)],
  );
  expense(
    'Photo & video package',
    2400,
    'Photography & video',
    by: photo,
    dueIn: 45,
    paid: [(800, 15, PaymentMethod.card)],
  );
  expense(
    'Wedding dress',
    1800,
    'Attire & beauty',
    paid: [(1800, 10, PaymentMethod.card)],
  );
  expense('Suit tailoring', 650, 'Attire & beauty', dueIn: -3);
  expense(
    'Invitations & printing',
    420,
    'Stationery',
    paid: [(420, 25, PaymentMethod.card)],
  );
  expense('Three-tier cake', 550, 'Cake & drinks', dueIn: 70);
  expense(
    'Arch & table flowers',
    1900,
    'Decor & flowers',
    by: florist,
    dueIn: 50,
  );

  EventTask task(
    String title, {
    int? dueIn,
    bool done = false,
    TaskPriority p = TaskPriority.medium,
  }) => EventTask(
    id: newId(),
    eventId: eventId,
    title: title,
    dueDate: dueIn == null ? null : day(dueIn),
    priority: p,
    isDone: done,
    completedAt: done ? today : null,
    createdAt: today,
  );
  final tasks = [
    task('Book the venue', dueIn: -40, done: true, p: TaskPriority.high),
    task('Send save-the-dates', dueIn: -20, done: true),
    task('Confirm final menu with caterer', dueIn: 5, p: TaskPriority.high),
    task('Pick up suit after tailoring', dueIn: -2, p: TaskPriority.high),
    task('Choose first-dance song', dueIn: 21, p: TaskPriority.low),
    task('Book DJ', dueIn: 10, p: TaskPriority.high),
    task('Finalise seating plan', dueIn: 60),
    task('Write vows'),
  ];

  Note note(String title, String body, {bool pinned = false, int? color}) =>
      Note(
        id: newId(),
        eventId: eventId,
        title: title,
        body: body,
        isPinned: pinned,
        colorValue: color,
        createdAt: today,
        updatedAt: today,
      );
  final notes = [
    note(
      'Day-of timeline',
      '2:00 Guests arrive\n3:00 Ceremony\n4:00 Photos & cocktails\n6:00 Dinner\n8:00 First dance\n11:00 Send-off',
      pinned: true,
      color: notePalette[0],
    ),
    note(
      'Caterer call',
      'Vegetarian option: mushroom risotto. Kids menu available at half price.',
      color: notePalette[3],
    ),
    note(
      'Ideas',
      'Polaroid guest book, sparkler send-off, late-night tacos.',
      color: notePalette[2],
    ),
  ];

  Guest guest(
    String name,
    RsvpStatus rsvp, {
    String group = '',
    int plus = 0,
    String diet = '',
  }) => Guest(
    id: newId(),
    eventId: eventId,
    name: name,
    rsvp: rsvp,
    groupName: group,
    plusOnes: plus,
    dietary: diet,
    createdAt: today,
  );
  final guests = [
    guest('Hanna Bekele', RsvpStatus.attending, group: 'Family', plus: 1),
    guest('Michael Tesfaye', RsvpStatus.attending, group: 'Family', plus: 2),
    guest(
      'Ruth Alemu',
      RsvpStatus.attending,
      group: 'Friends',
      diet: 'Vegetarian',
    ),
    guest('James Carter', RsvpStatus.maybe, group: 'Work', plus: 1),
    guest('Liya Haile', RsvpStatus.pending, group: 'Friends'),
    guest('Samuel Girma', RsvpStatus.declined, group: 'Work'),
    guest(
      'Emma Johnson',
      RsvpStatus.attending,
      group: 'Friends',
      plus: 1,
      diet: 'Gluten-free',
    ),
    guest('Yonas Abebe', RsvpStatus.pending, group: 'Family', plus: 3),
  ];

  await database.db.transaction((txn) async {
    await txn.insert('events', event.toMap());
    for (final c in categories) {
      await txn.insert('categories', c.toMap());
    }
    for (final v in vendors) {
      await txn.insert('vendors', v.toMap());
    }
    for (final e in expenses) {
      await txn.insert('expenses', e.toMap());
    }
    for (final p in payments) {
      await txn.insert('payments', p.toMap());
    }
    for (final t in tasks) {
      await txn.insert('tasks', t.toMap());
    }
    for (final n in notes) {
      await txn.insert('notes', n.toMap());
    }
    for (final g in guests) {
      await txn.insert('guests', g.toMap());
    }
  });
  return eventId;
}
