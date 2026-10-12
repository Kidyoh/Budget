/// Enumerations shared by the data models.
///
/// Each enum is persisted by its [Enum.name], so renaming a value is a
/// breaking schema change. Use [enumByName] to read them back safely.
library;

T enumByName<T extends Enum>(List<T> values, String? name, T fallback) {
  if (name == null) return fallback;
  for (final value in values) {
    if (value.name == name) return value;
  }
  return fallback;
}

enum EventType {
  wedding('Wedding'),
  birthday('Birthday'),
  conference('Conference'),
  corporate('Corporate'),
  party('Party'),
  festival('Festival'),
  other('Other');

  const EventType(this.label);
  final String label;
}

enum EventStatus {
  planning('Planning'),
  confirmed('Confirmed'),
  completed('Completed'),
  cancelled('Cancelled');

  const EventStatus(this.label);
  final String label;
}

enum PaymentMethod {
  cash('Cash'),
  card('Card'),
  bankTransfer('Bank transfer'),
  mobileMoney('Mobile money'),
  cheque('Cheque'),
  other('Other');

  const PaymentMethod(this.label);
  final String label;
}

/// Derived from an expense's amount, paid amount and due date.
enum PaymentStatus {
  unpaid('Unpaid'),
  partial('Partially paid'),
  paid('Paid'),
  overdue('Overdue');

  const PaymentStatus(this.label);
  final String label;
}

enum TaskPriority {
  low('Low'),
  medium('Medium'),
  high('High');

  const TaskPriority(this.label);
  final String label;
}

enum RsvpStatus {
  pending('Pending'),
  attending('Attending'),
  maybe('Maybe'),
  declined('Declined');

  const RsvpStatus(this.label);
  final String label;
}

enum VendorStatus {
  researching('Researching'),
  contacted('Contacted'),
  quoted('Quoted'),
  booked('Booked'),
  declined('Declined');

  const VendorStatus(this.label);
  final String label;
}
