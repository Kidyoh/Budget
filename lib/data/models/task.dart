import 'enums.dart';

class EventTask {
  const EventTask({
    required this.id,
    required this.eventId,
    required this.title,
    this.notes = '',
    this.dueDate,
    this.priority = TaskPriority.medium,
    this.isDone = false,
    this.completedAt,
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String title;
  final String notes;
  final DateTime? dueDate;
  final TaskPriority priority;
  final bool isDone;
  final DateTime? completedAt;
  final DateTime createdAt;

  bool isOverdue(DateTime now) {
    final due = dueDate;
    if (isDone || due == null) return false;
    return DateTime(
      due.year,
      due.month,
      due.day,
    ).isBefore(DateTime(now.year, now.month, now.day));
  }

  EventTask toggled(DateTime now) => EventTask(
    id: id,
    eventId: eventId,
    title: title,
    notes: notes,
    dueDate: dueDate,
    priority: priority,
    isDone: !isDone,
    completedAt: isDone ? null : now,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'title': title,
    'notes': notes,
    'due_date': dueDate?.millisecondsSinceEpoch,
    'priority': priority.name,
    'is_done': isDone ? 1 : 0,
    'completed_at': completedAt?.millisecondsSinceEpoch,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory EventTask.fromMap(Map<String, Object?> map) => EventTask(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    title: map['title'] as String,
    notes: map['notes'] as String? ?? '',
    dueDate: map['due_date'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int),
    priority: enumByName(
      TaskPriority.values,
      map['priority'] as String?,
      TaskPriority.medium,
    ),
    isDone: (map['is_done'] as int? ?? 0) == 1,
    completedAt: map['completed_at'] == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(map['completed_at'] as int),
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
