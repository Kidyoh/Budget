import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/palette.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';

Future<void> openNoteEditor(
  BuildContext context, {
  required String eventId,
  Note? note,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => NoteEditorScreen(eventId: eventId, note: note),
    ),
  );
}

/// Edits a note. Changes are saved when leaving the screen; an empty new
/// note is discarded.
class NoteEditorScreen extends ConsumerStatefulWidget {
  const NoteEditorScreen({super.key, required this.eventId, this.note});

  final String eventId;
  final Note? note;

  @override
  ConsumerState<NoteEditorScreen> createState() => _NoteEditorScreenState();
}

class _NoteEditorScreenState extends ConsumerState<NoteEditorScreen> {
  late final _title = TextEditingController(text: widget.note?.title);
  late final _body = TextEditingController(text: widget.note?.body);
  late bool _pinned = widget.note?.isPinned ?? false;
  late int? _color = widget.note?.colorValue;
  bool _deleted = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  bool get _changed {
    final n = widget.note;
    if (n == null) return true;
    return n.title != _title.text ||
        n.body != _body.text ||
        n.isPinned != _pinned ||
        n.colorValue != _color;
  }

  Future<void> _persist() async {
    if (_deleted || !_changed) return;
    final existing = widget.note;
    final now = DateTime.now();
    final note = Note(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      title: _title.text.trim(),
      body: _body.text.trim(),
      isPinned: _pinned,
      colorValue: _color,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    final dao = ref.read(noteDaoProvider);
    if (existing == null) {
      if (!note.isEmpty) await dao.insert(note);
    } else if (note.isEmpty) {
      await dao.delete(existing.id);
    } else {
      await dao.update(note);
    }
  }

  Future<void> _delete() async {
    final existing = widget.note;
    if (existing != null) {
      final ok = await confirmDialog(
        context,
        title: 'Delete note?',
        message: 'This note will be permanently deleted.',
      );
      if (!ok) return;
      await ref.read(noteDaoProvider).delete(existing.id);
    }
    _deleted = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = _color == null ? null : Color(_color!);
    final background = tint == null
        ? scheme.surface
        : Color.alphaBlend(
            tint.withValues(alpha: isDark ? 0.18 : 0.4),
            scheme.surface,
          );

    return PopScope(
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) _persist();
      },
      child: Scaffold(
        backgroundColor: background,
        appBar: pageBar(
          context,
          background: background,
          actions: [
            CircleButton(
              tooltip: _pinned ? 'Unpin' : 'Pin',
              icon: _pinned ? Icons.push_pin_rounded : Icons.push_pin_outlined,
              onTap: () => setState(() => _pinned = !_pinned),
            ),
            CircleButton(
              tooltip: 'Colour',
              icon: Icons.palette_outlined,
              onTap: () => showModalBottomSheet<void>(
                context: context,
                builder: (context) => Padding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                  child: ColorSwatchPicker(
                    colors: notePalette,
                    selected: _color,
                    allowNone: true,
                    onChanged: (c) {
                      setState(() => _color = c);
                      Navigator.pop(context);
                    },
                  ),
                ),
              ),
            ),
            CircleButton(
              tooltip: 'Delete',
              icon: Icons.delete_outline_rounded,
              onTap: _delete,
            ),
          ],
        ),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 40),
          children: [
            TextField(
              controller: _title,
              autofocus: widget.note == null,
              textCapitalization: TextCapitalization.sentences,
              style: text.headlineSmall,
              decoration: const InputDecoration(
                hintText: 'Title',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
            TextField(
              controller: _body,
              maxLines: null,
              minLines: 12,
              keyboardType: TextInputType.multiline,
              textCapitalization: TextCapitalization.sentences,
              style: text.bodyLarge?.copyWith(height: 1.5),
              decoration: const InputDecoration(
                hintText:
                    'Write anything: ideas, call notes, the day-of timeline…',
                filled: false,
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
