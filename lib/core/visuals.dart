import 'package:flutter/material.dart';

import '../data/models/models.dart';

/// Icons a budget category can use, keyed by the value stored in the database.
const Map<String, IconData> categoryIcons = {
  'venue': Icons.location_city_rounded,
  'catering': Icons.restaurant_rounded,
  'drinks': Icons.local_bar_rounded,
  'cake': Icons.cake_rounded,
  'decor': Icons.local_florist_rounded,
  'music': Icons.music_note_rounded,
  'entertainment': Icons.celebration_rounded,
  'photo': Icons.photo_camera_rounded,
  'attire': Icons.checkroom_rounded,
  'beauty': Icons.face_retouching_natural_rounded,
  'transport': Icons.directions_car_rounded,
  'lodging': Icons.hotel_rounded,
  'stationery': Icons.mail_rounded,
  'gifts': Icons.card_giftcard_rounded,
  'av': Icons.speaker_rounded,
  'staff': Icons.groups_rounded,
  'marketing': Icons.campaign_rounded,
  'security': Icons.security_rounded,
  'rentals': Icons.chair_rounded,
  'misc': Icons.category_rounded,
};

IconData categoryIcon(String? key) =>
    categoryIcons[key] ?? Icons.category_rounded;

IconData eventTypeIcon(EventType type) => switch (type) {
  EventType.wedding => Icons.favorite_rounded,
  EventType.birthday => Icons.cake_rounded,
  EventType.conference => Icons.mic_rounded,
  EventType.corporate => Icons.business_center_rounded,
  EventType.party => Icons.celebration_rounded,
  EventType.festival => Icons.festival_rounded,
  EventType.other => Icons.event_rounded,
};

IconData paymentMethodIcon(PaymentMethod method) => switch (method) {
  PaymentMethod.cash => Icons.payments_rounded,
  PaymentMethod.card => Icons.credit_card_rounded,
  PaymentMethod.bankTransfer => Icons.account_balance_rounded,
  PaymentMethod.mobileMoney => Icons.phone_android_rounded,
  PaymentMethod.cheque => Icons.receipt_long_rounded,
  PaymentMethod.other => Icons.more_horiz_rounded,
};

/// Semantic colours that read well in light and dark themes.
class StatusColors {
  static const success = Color(0xFF2E7D32);
  static const warning = Color(0xFFEF6C00);
  static const danger = Color(0xFFC62828);
  static const info = Color(0xFF0B57D0);
  static const neutral = Color(0xFF607D8B);
}

Color paymentStatusColor(PaymentStatus status) => switch (status) {
  PaymentStatus.paid => StatusColors.success,
  PaymentStatus.partial => StatusColors.info,
  PaymentStatus.unpaid => StatusColors.neutral,
  PaymentStatus.overdue => StatusColors.danger,
};

Color rsvpColor(RsvpStatus status) => switch (status) {
  RsvpStatus.attending => StatusColors.success,
  RsvpStatus.maybe => StatusColors.warning,
  RsvpStatus.declined => StatusColors.danger,
  RsvpStatus.pending => StatusColors.neutral,
};

Color vendorStatusColor(VendorStatus status) => switch (status) {
  VendorStatus.booked => StatusColors.success,
  VendorStatus.quoted => StatusColors.info,
  VendorStatus.contacted => StatusColors.warning,
  VendorStatus.researching => StatusColors.neutral,
  VendorStatus.declined => StatusColors.danger,
};

Color priorityColor(TaskPriority priority) => switch (priority) {
  TaskPriority.high => StatusColors.danger,
  TaskPriority.medium => StatusColors.warning,
  TaskPriority.low => StatusColors.neutral,
};

Color eventStatusColor(EventStatus status) => switch (status) {
  EventStatus.planning => StatusColors.info,
  EventStatus.confirmed => StatusColors.success,
  EventStatus.completed => StatusColors.neutral,
  EventStatus.cancelled => StatusColors.danger,
};

/// Colour for a budget usage bar: calm until 85%, amber to 100%, red beyond.
Color usageColor(double fraction, ColorScheme scheme) {
  if (fraction > 1.0001) return StatusColors.danger;
  if (fraction >= 0.85) return StatusColors.warning;
  return scheme.primary;
}
