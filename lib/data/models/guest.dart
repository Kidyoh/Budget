import 'enums.dart';

class Guest {
  const Guest({
    required this.id,
    required this.eventId,
    required this.name,
    this.email = '',
    this.phone = '',
    this.groupName = '',
    this.rsvp = RsvpStatus.pending,
    this.plusOnes = 0,
    this.dietary = '',
    this.tableName = '',
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String email;
  final String phone;
  final String groupName;
  final RsvpStatus rsvp;
  final int plusOnes;
  final String dietary;
  final String tableName;
  final String notes;
  final DateTime createdAt;

  /// The guest plus everyone they bring.
  int get partySize => 1 + plusOnes;

  Guest withRsvp(RsvpStatus value) => Guest(
    id: id,
    eventId: eventId,
    name: name,
    email: email,
    phone: phone,
    groupName: groupName,
    rsvp: value,
    plusOnes: plusOnes,
    dietary: dietary,
    tableName: tableName,
    notes: notes,
    createdAt: createdAt,
  );

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'name': name,
    'email': email,
    'phone': phone,
    'group_name': groupName,
    'rsvp': rsvp.name,
    'plus_ones': plusOnes,
    'dietary': dietary,
    'table_name': tableName,
    'notes': notes,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Guest.fromMap(Map<String, Object?> map) => Guest(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    name: map['name'] as String,
    email: map['email'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    groupName: map['group_name'] as String? ?? '',
    rsvp: enumByName(
      RsvpStatus.values,
      map['rsvp'] as String?,
      RsvpStatus.pending,
    ),
    plusOnes: map['plus_ones'] as int? ?? 0,
    dietary: map['dietary'] as String? ?? '',
    tableName: map['table_name'] as String? ?? '',
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}
