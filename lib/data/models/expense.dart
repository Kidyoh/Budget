import 'enums.dart';

class Expense {
  const Expense({
    required this.id,
    required this.eventId,
    this.categoryId,
    this.vendorId,
    required this.title,
    required this.amount,
    this.dueDate,
    this.notes = '',
    this.receiptPath,
    required this.createdAt,
    required this.updatedAt,
    this.paidAmount = 0,
  });

  final String id;
  final String eventId;
  final String? categoryId;
  final String? vendorId;
  final String title;
  final double amount;
  final DateTime? dueDate;
  final String notes;
  final String? receiptPath;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// Sum of the payments recorded for this expense. Computed by the query
  /// that loads the expense; it is not a column of the expenses table.
  final double paidAmount;

  double get outstanding => (amount - paidAmount).clamp(0, double.infinity);

  PaymentStatus statusAt(DateTime now) {
    if (amount > 0 && paidAmount >= amount - 0.005) return PaymentStatus.paid;
    if (amount <= 0) return PaymentStatus.paid;
    final due = dueDate;
    if (due != null) {
      final today = DateTime(now.year, now.month, now.day);
      if (DateTime(due.year, due.month, due.day).isBefore(today)) {
        return PaymentStatus.overdue;
      }
    }
    return paidAmount > 0 ? PaymentStatus.partial : PaymentStatus.unpaid;
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'category_id': categoryId,
    'vendor_id': vendorId,
    'title': title,
    'amount': amount,
    'due_date': dueDate?.millisecondsSinceEpoch,
    'notes': notes,
    'receipt_path': receiptPath,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Expense.fromMap(Map<String, Object?> map) => Expense(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    categoryId: map['category_id'] as String?,
    vendorId: map['vendor_id'] as String?,
    title: map['title'] as String,
    amount: (map['amount'] as num).toDouble(),
    dueDate: map['due_date'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
    notes: map['notes'] as String? ?? '',
    receiptPath: map['receipt_path'] as String?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
    paidAmount: (map['paid'] as num?)?.toDouble() ?? 0,
  );
}

class Payment {
  const Payment({
    required this.id,
    required this.expenseId,
    required this.amount,
    required this.date,
    required this.method,
    this.note = '',
  });

  final String id;
  final String expenseId;
  final double amount;
  final DateTime date;
  final PaymentMethod method;
  final String note;

  Map<String, Object?> toMap() => {
    'id': id,
    'expense_id': expenseId,
    'amount': amount,
    'date': date.millisecondsSinceEpoch,
    'method': method.name,
    'note': note,
  };

  factory Payment.fromMap(Map<String, Object?> map) => Payment(
    id: map['id'] as String,
    expenseId: map['expense_id'] as String,
    amount: (map['amount'] as num).toDouble(),
    date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
    method: enumByName(
      PaymentMethod.values,
      map['method'] as String?,
      PaymentMethod.other,
    ),
    note: map['note'] as String? ?? '',
  );
}
