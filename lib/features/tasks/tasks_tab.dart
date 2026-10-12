import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import 'task_form.dart';

class TasksTab extends ConsumerStatefulWidget {
  const TasksTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<TasksTab> createState() => _TasksTabState();
}

class _TasksTabState extends ConsumerState<TasksTab> {
  bool _showCompleted = true;

  Future<void> _delete(EventTask task) async {
    final dao = ref.read(taskDaoProvider);
    await dao.delete(task.id);
    if (!mounted) return;
    showSnack(
      context,
      'Task deleted',
      action: SnackBarAction(label: 'Undo', onPressed: () => dao.insert(task)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    return AsyncView(
      value: ref.watch(tasksProvider(widget.eventId)),
      data: (tasks) {
        if (tasks.isEmpty) {
          return EmptyState(
            icon: Icons.checklist_rounded,
            title: 'No tasks yet',
            message:
                'Build your planning checklist with due dates and priorities.',
            action: FilledButton.icon(
              onPressed: () =>
                  showTaskForm(context, ref, eventId: widget.eventId),
              icon: const Icon(Icons.add_task_rounded),
              label: const Text('Add a task'),
            ),
          );
        }
        final now = DateTime.now();
        final open = tasks.where((t) => !t.isDone);
        final overdue = open.where((t) => t.isOverdue(now)).toList();
        final upcoming = open
            .where((t) => t.dueDate != null && !t.isOverdue(now))
            .toList();
        final anytime = open.where((t) => t.dueDate == null).toList();
        final done = tasks.where((t) => t.isDone).toList()
          ..sort(
            (a, b) => (b.completedAt ?? b.createdAt).compareTo(
              a.completedAt ?? a.createdAt,
            ),
          );
        final progress = tasks.isEmpty ? 0.0 : done.length / tasks.length;

        Widget group(String title, List<EventTask> items, {Color? color}) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader(
                '$title · ${items.length}',
                padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
              ),
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 56),
                      _TaskTile(
                        task: items[i],
                        now: now,
                        onDelete: () => _delete(items[i]),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    SizedBox(
                      width: 52,
                      height: 52,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          CircularProgressIndicator(
                            value: progress,
                            strokeWidth: 6,
                            strokeCap: StrokeCap.round,
                            backgroundColor: scheme.surfaceContainerHighest,
                          ),
                          Center(
                            child: Text(
                              '${(progress * 100).round()}%',
                              style: text.labelMedium,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '${done.length} of ${tasks.length} tasks done',
                            style: text.titleSmall,
                          ),
                          Text(
                            overdue.isEmpty
                                ? '${open.length} still to do'
                                : '${overdue.length} overdue · ${open.length} still to do',
                            style: text.bodySmall?.copyWith(
                              color: overdue.isEmpty
                                  ? scheme.onSurfaceVariant
                                  : StatusColors.danger,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: _showCompleted
                          ? 'Hide completed'
                          : 'Show completed',
                      onPressed: () =>
                          setState(() => _showCompleted = !_showCompleted),
                      icon: Icon(
                        _showCompleted
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            group('Overdue', overdue),
            group('Upcoming', upcoming),
            group('Anytime', anytime),
            if (_showCompleted) group('Completed', done),
          ],
        );
      },
    );
  }
}

class _TaskTile extends ConsumerWidget {
  const _TaskTile({
    required this.task,
    required this.now,
    required this.onDelete,
  });

  final EventTask task;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final overdue = task.isOverdue(now);

    return Dismissible(
      key: ValueKey(task.id),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        color: scheme.errorContainer,
        child: Icon(
          Icons.delete_outline_rounded,
          color: scheme.onErrorContainer,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: ListTile(
        contentPadding: const EdgeInsets.fromLTRB(4, 2, 12, 2),
        onTap: () =>
            showTaskForm(context, ref, eventId: task.eventId, task: task),
        leading: Checkbox(
          value: task.isDone,
          shape: const CircleBorder(),
          onChanged: (_) =>
              ref.read(taskDaoProvider).update(task.toggled(DateTime.now())),
        ),
        title: Text(
          task.title,
          style: text.bodyLarge?.copyWith(
            decoration: task.isDone ? TextDecoration.lineThrough : null,
            color: task.isDone ? scheme.onSurfaceVariant : null,
          ),
        ),
        subtitle: (task.dueDate == null && task.notes.isEmpty)
            ? null
            : Text(
                [
                  if (task.dueDate != null)
                    '${formatShortDate(task.dueDate!)} · ${relativeDay(task.dueDate!, now: now)}',
                  if (task.notes.isNotEmpty) task.notes,
                ].join('\n'),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: text.bodySmall?.copyWith(
                  color: overdue
                      ? StatusColors.danger
                      : scheme.onSurfaceVariant,
                ),
              ),
        trailing: task.isDone
            ? null
            : Tooltip(
                message: '${task.priority.label} priority',
                child: Icon(
                  Icons.flag_rounded,
                  size: 18,
                  color: priorityColor(task.priority),
                ),
              ),
      ),
    );
  }
}
