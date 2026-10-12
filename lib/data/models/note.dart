class Note {
  const Note({
    required this.id,
    required this.eventId,
    this.title = '',
    this.body = '',
    this.isPinned = false,
    this.colorValue,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final String eventId;
  final String title;
  final String body;
  final bool isPinned;

  /// Optional tint for the note card; null uses the theme surface colour.
  final int? colorValue;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isEmpty => title.trim().isEmpty && body.trim().isEmpty;

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'title': title,
    'body': body,
    'is_pinned': isPinned ? 1 : 0,
    'color': colorValue,
    'created_at': createdAt.millisecondsSinceEpoch,
    'updated_at': updatedAt.millisecondsSinceEpoch,
  };

  factory Note.fromMap(Map<String, Object?> map) => Note(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    title: map['title'] as String? ?? '',
    body: map['body'] as String? ?? '',
    isPinned: (map['is_pinned'] as int? ?? 0) == 1,
    colorValue: map['color'] as int?,
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
    updatedAt: DateTime.fromMillisecondsSinceEpoch(map['updated_at'] as int),
  );
}
