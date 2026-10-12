import 'models/models.dart';

/// Builds a CSV report of an event's expenses, one row per expense.
String expensesCsv({
  required List<Expense> expenses,
  required List<CategoryWithSpend> categories,
  required List<VendorWithSpend> vendors,
  required DateTime now,
}) {
  final categoryNames = {
    for (final c in categories) c.category.id: c.category.name,
  };
  final vendorNames = {for (final v in vendors) v.vendor.id: v.vendor.name};
  String date(DateTime? d) => d == null
      ? ''
      : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  String money(double v) => v.toStringAsFixed(2);

  final rows = <List<String>>[
    [
      'Expense',
      'Category',
      'Vendor',
      'Amount',
      'Paid',
      'Outstanding',
      'Due date',
      'Status',
      'Notes',
    ],
    for (final e in expenses)
      [
        e.title,
        categoryNames[e.categoryId] ?? 'Uncategorised',
        vendorNames[e.vendorId] ?? '',
        money(e.amount),
        money(e.paidAmount),
        money(e.outstanding),
        date(e.dueDate),
        e.statusAt(now).label,
        e.notes,
      ],
  ];
  return rows.map((r) => r.map(_csvCell).join(',')).join('\r\n');
}

String _csvCell(String value) {
  if (value.contains(RegExp(r'[",\r\n]'))) {
    return '"${value.replaceAll('"', '""')}"';
  }
  return value;
}
