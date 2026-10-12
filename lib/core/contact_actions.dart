import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import 'widgets/common.dart';

/// Opens the dialer, mail app or browser for a contact detail.
Future<void> launchContact(BuildContext context, Uri uri) async {
  final ok = await launchUrl(
    uri,
    mode: LaunchMode.externalApplication,
  ).catchError((_) => false);
  if (!ok && context.mounted) {
    showSnack(context, 'No app available to open this.');
  }
}

Uri phoneUri(String phone) =>
    Uri(scheme: 'tel', path: phone.replaceAll(RegExp(r'[^\d+]'), ''));

Uri emailUri(String email) => Uri(scheme: 'mailto', path: email.trim());

Uri webUri(String site) {
  final trimmed = site.trim();
  return Uri.parse(trimmed.contains('://') ? trimmed : 'https://$trimmed');
}
