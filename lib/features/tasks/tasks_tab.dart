import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
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

        Widget group(String title, List<EventTask> items) {
          if (items.isEmpty) return const SizedBox.shrink();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SectionHeader('$title · ${items.length}'),
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < items.length; i++) ...[
                      if (i > 0) const Divider(indent: 60, endIndent: 16),
                      _TaskTile(
                        key: ValueKey(items[i].id),
                        task: items[i],
                        now: now,
                        onDelete: () => _delete(items[i]),
                      ).enter(i),
                    ],
                  ],
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.page,
            12,
            Insets.page,
            Insets.navClearance,
          ),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.highlight,
                borderRadius: BorderRadius.circular(Insets.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          '${done.length} of ${tasks.length} tasks done',
                          style: text.titleMedium?.copyWith(
                            color: inkOnHighlight,
                          ),
                        ),
                      ),
                      Pressable(
                        onTap: () =>
                            setState(() => _showCompleted = !_showCompleted),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 7,
                          ),
                          decoration: BoxDecoration(
                            color: inkOnHighlight,
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            _showCompleted ? 'Hide done' : 'Show done',
                            style: text.labelMedium?.copyWith(
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '${(progress * 100).round()}%',
                    style: text.displayMedium?.copyWith(color: inkOnHighlight),
                  ),
                  Text(
                    overdue.isEmpty
                        ? '${open.length} still to do'
                        : '${overdue.length} overdue · ${open.length} still to do',
                    style: text.bodyMedium?.copyWith(
                      color: inkOnHighlight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 16),
                  DotsProgress(value: progress, count: 18),
                ],
              ),
            ).enter(),
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
    super.key,
    required this.task,
    required this.now,
    required this.onDelete,
  });

  final EventTask task;
  final DateTime now;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    final text = context.text;
    final overdue = task.isOverdue(now);
    final details = [
      if (task.dueDate != null)
        '${formatShortDate(task.dueDate!)} · ${relativeDay(task.dueDate!, now: now)}',
      if (task.notes.isNotEmpty) task.notes,
    ].join('\n');

    return Dismissible(
      key: ValueKey('dismiss-${task.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        decoration: BoxDecoration(
          color: StatusColors.danger.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(Insets.smallRadius),
        ),
        child: const Icon(
          Icons.delete_outline_rounded,
          color: StatusColors.danger,
        ),
      ),
      onDismissed: (_) => onDelete(),
      child: Pressable(
        onTap: () =>
            showTaskForm(context, ref, eventId: task.eventId, task: task),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
          child: Row(
            crossAxisAlignment: details.isEmpty
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              CheckCircle(
                done: task.isDone,
                color: priorityColor(task.priority),
                onTap: () => ref
                    .read(taskDaoProvider)
                    .update(task.toggled(DateTime.now())),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: const Duration(milliseconds: 250),
                      style: text.bodyLarge!.copyWith(
                        decoration: task.isDone
                            ? TextDecoration.lineThrough
                            : null,
                        color: task.isDone ? t.faint : t.ink,
                      ),
                      child: Text(task.title),
                    ),
                    if (details.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        details,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: text.bodySmall?.copyWith(
                          color: overdue ? StatusColors.danger : t.muted,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!task.isDone)
                Padding(
                  padding: const EdgeInsets.only(left: 8, top: 2),
                  child: StatusPill(
                    label: task.priority.label,
                    color: priorityColor(task.priority),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// A round checkbox that fills with the highlight colour and pops when
/// ticked. Its ring takes the task's priority colour while open.
class CheckCircle extends StatelessWidget {
  const CheckCircle({
    super.key,
    required this.done,
    required this.color,
    required this.onTap,
  });

  final bool done;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      checked: done,
      label: done ? 'Mark not done' : 'Mark done',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.mediumImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.all(2),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 280),
            curve: Curves.easeOutBack,
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              color: done ? context.highlight : Colors.transparent,
              shape: BoxShape.circle,
              border: Border.all(
                color: done ? context.highlight : color,
                width: 2,
              ),
            ),
            child: AnimatedScale(
              scale: done ? 1 : 0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOutBack,
              child: const Icon(
                Icons.check_rounded,
                size: 18,
                color: inkOnHighlight,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
