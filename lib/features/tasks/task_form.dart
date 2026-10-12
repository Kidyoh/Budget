import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/visuals.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';

Future<void> showTaskForm(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  EventTask? task,
}) {
  return showFormSheet(
    context,
    child: _TaskForm(eventId: eventId, task: task),
  );
}

class _TaskForm extends ConsumerStatefulWidget {
  const _TaskForm({required this.eventId, this.task});

  final String eventId;
  final EventTask? task;

  @override
  ConsumerState<_TaskForm> createState() => _TaskFormState();
}

class _TaskFormState extends ConsumerState<_TaskForm> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.task?.title);
  late final _notes = TextEditingController(text: widget.task?.notes);
  late DateTime? _due = widget.task?.dueDate;
  late TaskPriority _priority = widget.task?.priority ?? TaskPriority.medium;

  @override
  void dispose() {
    _title.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.task;
    final task = EventTask(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      title: _title.text.trim(),
      notes: _notes.text.trim(),
      dueDate: _due,
      priority: _priority,
      isDone: existing?.isDone ?? false,
      completedAt: existing?.completedAt,
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final dao = ref.read(taskDaoProvider);
    if (existing == null) {
      await dao.insert(task);
    } else {
      await dao.update(task);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.task == null ? 'New task' : 'Edit task',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _title,
            autofocus: widget.task == null,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Task'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Describe the task' : null,
            onFieldSubmitted: (_) => _save(),
          ),
          const SizedBox(height: 12),
          DateField(
            label: 'Due date',
            value: _due,
            icon: Icons.flag_outlined,
            onChanged: (d) => setState(() => _due = d),
          ),
          const SizedBox(height: 12),
          SegmentedButton<TaskPriority>(
            segments: [
              for (final p in TaskPriority.values)
                ButtonSegment(
                  value: p,
                  label: Text(p.label),
                  icon: Icon(Icons.circle, size: 12, color: priorityColor(p)),
                ),
            ],
            selected: {_priority},
            showSelectedIcon: false,
            onSelectionChanged: (s) => setState(() => _priority = s.first),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save task')),
        ],
      ),
    );
  }
}
