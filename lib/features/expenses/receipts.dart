import 'dart:io';

import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../../core/id.dart';

/// Lets the user take or choose a receipt photo and copies it into the app's
/// documents folder, so it survives the picker's temporary file being
/// cleaned up. Returns the stored path, or null if nothing was picked.
Future<String?> pickReceipt(ImageSource source) async {
  final picked = await ImagePicker().pickImage(
    source: source,
    maxWidth: 2000,
    imageQuality: 85,
  );
  if (picked == null) return null;
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'receipts'));
  await dir.create(recursive: true);
  final ext = p.extension(picked.path).isEmpty
      ? '.jpg'
      : p.extension(picked.path);
  final target = p.join(dir.path, '${newId()}$ext');
  await File(picked.path).copy(target);
  return target;
}

/// Deletes a stored receipt, ignoring files that are already gone.
Future<void> deleteReceipt(String? path) async {
  if (path == null) return;
  try {
    final file = File(path);
    if (await file.exists()) await file.delete();
  } on FileSystemException {
    // Best effort: a leftover image is harmless.
  }
}
