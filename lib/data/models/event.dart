import 'enums.dart';

class Event {
  const Event({
    required this.id,
    required this.name,
    required this.type,
    required this.status,
    required this.startDate,
    this.endDate,
    this.location = '',
    this.description = '',
    required this.totalBudget,
    required this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String name;
  final EventType type;
  final EventStatus status;
  final DateTime startDate;
  final DateTime? endDate;
  final String location;
  final String description;
  final double totalBudget;
  final int colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  /// The last day the event runs, used to decide whether it is in the past.
  DateTime get lastDay => endDate ?? startDate;

  bool isPast(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    final last = DateTime(lastDay.year, lastDay.month, lastDay.day);
    return last.isBefore(today);
  }

  Event copyWith({
    String? name,
    EventType? type,
    EventStatus? status,
    DateTime? startDate,
    DateTime? Function()? endDate,
    String? location,
    String? description,
    double? totalBudget,
    int? colorValue,
    DateTime? updatedAt,
  }) {
    return Event(
      id: id,
      name: name ?? this.name,
      type: type ?? this.type,
      status: status ?? this.status,
      startDate: startDate ?? this.startDate,
      endDate: endDate != null ? endDate() : this.endDate,
      location: location ?? this.location,
      description: description ?? this.description,
      totalBudget: totalBudget ?? this.totalBudget,
      colorValue: colorValue ?? this.colorValue,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toMap() => {
    'id': id,
    'name': name,
    'type': type.name,
    'status': status.name,
    'start_date': startDate.millisecondsSinceEpoch,
    'end_date': endDate?.millisecondsSinceEpoch,
    'location': location,
    'description': description,
    'total_budget': totalBudget,
    'color': colorValue,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Event.fromMap(Map<String, Object?> map) => Event(
    id: map['id'] as String,
    name: map['name'] as String,
    type: enumByName(EventType.values, map['type'] as String?, EventType.other),
    status: enumByName(
      EventStatus.values,
      map['status'] as String?,
      EventStatus.planning,
    ),
    startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
    endDate: map['end_date'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['end_date'] as int),
    location: map['location'] as String? ?? '',
    description: map['description'] as String? ?? '',
    totalBudget: (map['total_budget'] as num).toDouble(),
    colorValue: map['color'] as int,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}

/// An event together with the money figures shown on the events list.
class EventWithTotals {
  const EventWithTotals({
    required this.event,
    required this.committed,
    required this.paid,
  });

  final Event event;

  /// Sum of all expense amounts, paid or not.
  final double committed;

  /// Sum of all payments made against those expenses.
  final double paid;

  double get remaining => event.totalBudget - committed;

  double get usedFraction =>
      event.totalBudget <= 0 ? 0 : committed / event.totalBudget;
}
