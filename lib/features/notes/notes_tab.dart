import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import 'note_editor_screen.dart';

class NotesTab extends ConsumerStatefulWidget {
  const NotesTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<NotesTab> createState() => _NotesTabState();
}

class _NotesTabState extends ConsumerState<NotesTab> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(notesProvider(widget.eventId)),
      data: (notes) {
        if (notes.isEmpty) {
          return EmptyState(
            icon: Icons.sticky_note_2_outlined,
            title: 'No notes yet',
            message: 'Keep ideas, call notes, timelines and anything else you need to remember.',
            action: FilledButton.icon(
              onPressed: () => openNoteEditor(context, eventId: widget.eventId),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Write a note'),
            ),
          );
        }
        final query = _query.trim().toLowerCase();
        final visible = query.isEmpty
            ? notes
            : notes
                  .where(
                    (n) =>
                        n.title.toLowerCase().contains(query) ||
                        n.body.toLowerCase().contains(query),
                  )
                  .toList();

        return CustomScrollView(
          slivers: [
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              sliver: SliverToBoxAdapter(
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Search notes',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _query = v),
                ),
              ),
            ),
            if (visible.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No notes match.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 104),
                sliver: SliverGrid.builder(
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 240,
                    mainAxisSpacing: 10,
                    crossAxisSpacing: 10,
                    childAspectRatio: 0.9,
                  ),
                  itemCount: visible.length,
                  itemBuilder: (context, i) => _NoteCard(note: visible[i]),
                ),
              ),
          ],
        );
      },
    );
  }
}

class _NoteCard extends StatelessWidget {
  const _NoteCard({required this.note});

  final Note note;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tint = note.colorValue == null ? null : Color(note.colorValue!);
    final background = tint == null
        ? scheme.surfaceContainerLow
        : Color.alphaBlend(
            tint.withValues(alpha: isDark ? 0.22 : 0.55),
            scheme.surface,
          );

    return Card(
      color: background,
      child: InkWell(
        onTap: () => openNoteEditor(context, eventId: note.eventId, note: note),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      note.title.isEmpty ? 'Untitled' : note.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: text.titleSmall,
                    ),
                  ),
                  if (note.isPinned)
                    Icon(
                      Icons.push_pin_rounded,
                      size: 16,
                      color: scheme.primary,
                    ),
                ],
              ),
              const SizedBox(height: 6),
              Expanded(
                child: Text(
                  note.body,
                  overflow: TextOverflow.fade,
                  style: text.bodySmall,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                formatShortDate(note.updatedAt),
                style: text.labelSmall?.copyWith(
                  color: scheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
