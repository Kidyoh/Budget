import 'enums.dart';

class Vendor {
  const Vendor({
    required this.id,
    required this.eventId,
    required this.name,
    this.service = '',
    this.contactName = '',
    this.phone = '',
    this.email = '',
    this.website = '',
    this.quote,
    this.status = VendorStatus.researching,
    this.rating = 0,
    this.notes = '',
    required this.createdAt,
  });

  final String id;
  final String eventId;
  final String name;
  final String service;
  final String contactName;
  final String phone;
  final String email;
  final String website;
  final double? quote;
  final VendorStatus status;

  /// 0 means unrated; otherwise 1 to 5.
  final int rating;
  final String notes;
  final DateTime createdAt;

  Map<String, Object?> toMap() => {
    'id': id,
    'event_id': eventId,
    'name': name,
    'service': service,
    'contact_name': contactName,
    'phone': phone,
    'email': email,
    'website': website,
    'quote': quote,
    'status': status.name,
    'rating': rating,
    'notes': notes,
    'created_at': createdAt.millisecondsSinceEpoch,
  };

  factory Vendor.fromMap(Map<String, Object?> map) => Vendor(
    id: map['id'] as String,
    eventId: map['event_id'] as String,
    name: map['name'] as String,
    service: map['service'] as String? ?? '',
    contactName: map['contact_name'] as String? ?? '',
    phone: map['phone'] as String? ?? '',
    email: map['email'] as String? ?? '',
    website: map['website'] as String? ?? '',
    quote: (map['quote'] as num?)?.toDouble(),
    status: enumByName(
      VendorStatus.values,
      map['status'] as String?,
      VendorStatus.researching,
    ),
    rating: map['rating'] as int? ?? 0,
    notes: map['notes'] as String? ?? '',
    createdAt: DateTime.fromMillisecondsSinceEpoch(map['created_at'] as int),
  );
}

/// A vendor with the sum of the expenses linked to it.
class VendorWithSpend {
  const VendorWithSpend({required this.vendor, required this.committed});

  final Vendor vendor;
  final double committed;
}
