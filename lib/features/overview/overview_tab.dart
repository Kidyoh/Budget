import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/common.dart';
import '../../data/event_overview.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../budget/category_form.dart';
import '../events/event_detail_screen.dart';
import '../expenses/expense_detail_screen.dart';
import '../expenses/expense_form_screen.dart';
import '../guests/guest_form.dart';
import '../notes/note_editor_screen.dart';
import '../tasks/task_form.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({super.key, required this.eventId, required this.onOpen});

  final String eventId;
  final OpenSection onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(overviewProvider(eventId)),
      data: (o) {
        if (o == null) return const SizedBox.shrink();
        var i = 0;
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.page,
            4,
            Insets.page,
            Insets.navClearance,
          ),
          children: [
            _Title(o: o).enter(i++),
            const SizedBox(height: 18),
            _HeroCard(o: o).enter(i++),
            const SizedBox(height: 22),
            _QuickActions(eventId: eventId).enter(i++),
            const SizedBox(height: 22),
            _StatCards(o: o).enter(i++),
            _Attention(o: o, onOpen: onOpen),
            SectionHeader(
              'Upcoming payments',
              onSeeAll: () =>
                  onOpen(EventSection.money, money: MoneyView.expenses),
            ),
            _Payments(o: o).enter(i++),
            SectionHeader('Tasks', onSeeAll: () => onOpen(EventSection.tasks)),
            _Tasks(o: o).enter(i++),
            SectionHeader(
              'Guests',
              onSeeAll: () =>
                  onOpen(EventSection.people, people: PeopleView.guests),
            ),
            _Guests(o: o, onOpen: onOpen).enter(i++),
          ],
        );
      },
    );
  }
}

class _Title extends StatelessWidget {
  const _Title({required this.o});

  final EventOverview o;

  @override
  Widget build(BuildContext context) {
    final e = o.event;
    final t = context.tokens;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: visible(Color(e.colorValue), context),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                [
                  '${e.type.label} · ${e.status.label}',
                  if (e.location.isNotEmpty) e.location,
                ].join(' · '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelMedium?.copyWith(color: t.muted),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        Text(e.name, style: context.text.headlineMedium),
        const SizedBox(height: 2),
        Text(
          formatDateRange(e.startDate, e.endDate),
          style: context.text.bodyMedium?.copyWith(color: t.muted),
        ),
      ],
    );
  }
}

class _HeroCard extends ConsumerWidget {
  const _HeroCard({required this.o});

  final EventOverview o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final bg = context.heroBg;
    final fg = context.onHero;
    final pillBg = context.isDark ? inkOnHighlight : context.highlight;
    final pillFg = context.isDark ? context.highlight : inkOnHighlight;
    final days = o.daysUntil;
    final past = o.event.isPast(o.now);
    final text = context.text;

    return Hero(
      tag: 'event-card-${o.event.id}',
      flightShuttleBuilder: (_, _, _, _, _) => Container(
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Insets.radius),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(Insets.radius),
        ),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(12, 12, 8, 10),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        o.isOverBudget ? 'Over budget by' : 'Remaining budget',
                        style: text.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 4),
                      BigAmount(
                        o.remaining.abs(),
                        style: text.displaySmall,
                        color: fg,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'of ${money.format(o.budget)} · ${(o.usedFraction * 100).round()}% committed',
                        style: text.bodySmall?.copyWith(
                          color: fg.withValues(alpha: 0.65),
                        ),
                      ),
                      const SizedBox(height: 18),
                      SpendBar(
                        paid: o.paid,
                        unpaid: o.outstanding,
                        budget: o.budget,
                        paidColor: fg,
                        unpaidColor: context.isDark
                            ? Colors.white
                            : context.highlight,
                        hatchColor: fg.withValues(alpha: 0.35),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 14,
                        runSpacing: 4,
                        children: [
                          _Legend(
                            color: fg,
                            label: 'Paid ${money.compact(o.paid)}',
                            fg: fg,
                          ),
                          _Legend(
                            color: context.isDark
                                ? Colors.white
                                : context.highlight,
                            label: 'Unpaid ${money.compact(o.outstanding)}',
                            fg: fg,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              Container(
                width: 74,
                decoration: BoxDecoration(
                  color: pillBg,
                  borderRadius: BorderRadius.circular(22),
                ),
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Icon(
                      Icons.hourglass_bottom_rounded,
                      color: pillFg,
                      size: 20,
                    ),
                    Column(
                      children: [
                        FittedBox(
                          child: Text(
                            past ? '✓' : (days <= 0 ? '0' : '$days'),
                            style: text.headlineMedium?.copyWith(color: pillFg),
                          ),
                        ),
                        Text(
                          past
                              ? 'done'
                              : days <= 0
                              ? 'today'
                              : days == 1
                              ? 'day'
                              : 'days',
                          style: text.labelSmall?.copyWith(
                            color: pillFg.withValues(alpha: 0.7),
                          ),
                        ),
                      ],
                    ),
                    Icon(Icons.north_east_rounded, color: pillFg, size: 20),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend({required this.color, required this.label, required this.fg});

  final Color color;
  final String label;
  final Color fg;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.text.labelSmall?.copyWith(
            color: fg.withValues(alpha: 0.8),
          ),
        ),
      ],
    );
  }
}

class _QuickActions extends ConsumerWidget {
  const _QuickActions({required this.eventId});

  final String eventId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        ActionCircle(
          icon: Icons.receipt_long_rounded,
          label: 'Expense',
          highlighted: true,
          onTap: () => openExpenseForm(context, eventId: eventId),
        ),
        ActionCircle(
          icon: Icons.donut_small_rounded,
          label: 'Category',
          onTap: () => showCategoryForm(context, ref, eventId: eventId),
        ),
        ActionCircle(
          icon: Icons.add_task_rounded,
          label: 'Task',
          onTap: () => showTaskForm(context, ref, eventId: eventId),
        ),
        ActionCircle(
          icon: Icons.person_add_alt_1_rounded,
          label: 'Guest',
          onTap: () => showGuestForm(context, ref, eventId: eventId),
        ),
        ActionCircle(
          icon: Icons.edit_note_rounded,
          label: 'Note',
          onTap: () => openNoteEditor(context, eventId: eventId),
        ),
      ],
    );
  }
}

class _StatCards extends ConsumerWidget {
  const _StatCards({required this.o});

  final EventOverview o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final text = context.text;
    final paidShare = o.committed <= 0 ? 0.0 : o.paid / o.committed;
    final darkCard = context.isDark ? context.tokens.card : heroInk;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: context.highlight,
                borderRadius: BorderRadius.circular(Insets.smallRadius + 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _CardChip(
                    icon: Icons.trending_up_rounded,
                    label: 'Committed',
                    dark: false,
                  ),
                  const SizedBox(height: 14),
                  Text(
                    '${(o.usedFraction * 100).round()}%',
                    style: text.displaySmall?.copyWith(color: inkOnHighlight),
                  ),
                  Text(
                    'of the budget is spoken for',
                    style: text.bodySmall?.copyWith(
                      color: inkOnHighlight.withValues(alpha: 0.7),
                    ),
                  ),
                  const Spacer(),
                  const SizedBox(height: 14),
                  DotsProgress(value: o.usedFraction, count: 12),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: darkCard,
                borderRadius: BorderRadius.circular(Insets.smallRadius + 4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _CardChip(label: 'Paid', dark: true),
                  const SizedBox(height: 14),
                  BigAmount(
                    o.paid,
                    style: text.headlineSmall,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      SizedBox(
                        width: 44,
                        height: 44,
                        child: ProgressRing(
                          value: paidShare,
                          color: context.highlight,
                          size: 44,
                          strokeWidth: 6,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          '${(paidShare * 100).round()}% of what you owe is paid',
                          style: text.bodySmall?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardChip extends StatelessWidget {
  const _CardChip({this.icon, required this.label, required this.dark});

  /// Null shows the currency symbol instead.
  final IconData? icon;
  final String label;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final fg = dark ? Colors.white : inkOnHighlight;
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: fg.withValues(alpha: 0.5)),
          ),
          child: icon == null
              ? Center(child: CurrencyIcon(size: 18, color: fg))
              : Icon(icon, size: 16, color: fg),
        ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: context.text.labelLarge?.copyWith(color: fg),
          ),
        ),
      ],
    );
  }
}

class _Attention extends ConsumerWidget {
  const _Attention({required this.o, required this.onOpen});

  final EventOverview o;
  final OpenSection onOpen;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final items = <(IconData, Color, String, VoidCallback)>[
      if (o.isOverBudget)
        (
          Icons.warning_amber_rounded,
          StatusColors.danger,
          'Spending is ${money.short(-o.remaining)} over the total budget',
          () => onOpen(EventSection.money, money: MoneyView.budget),
        ),
      if (o.overBudgetCategories.isNotEmpty)
        (
          Icons.donut_small_rounded,
          StatusColors.warning,
          o.overBudgetCategories.length == 1
              ? '${o.overBudgetCategories.first.category.name} is over its allocation'
              : '${o.overBudgetCategories.length} categories are over their allocation',
          () => onOpen(EventSection.money, money: MoneyView.budget),
        ),
      if (o.overdueExpenses.isNotEmpty)
        (
          Icons.schedule_rounded,
          StatusColors.danger,
          o.overdueExpenses.length == 1
              ? '1 payment is overdue'
              : '${o.overdueExpenses.length} payments are overdue',
          () => onOpen(EventSection.money, money: MoneyView.expenses),
        ),
      if (o.overdueTasks.isNotEmpty)
        (
          Icons.assignment_late_outlined,
          StatusColors.warning,
          o.overdueTasks.length == 1
              ? '1 task is past its due date'
              : '${o.overdueTasks.length} tasks are past their due date',
          () => onOpen(EventSection.tasks),
        ),
    ];
    if (items.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SectionHeader('Needs attention'),
        Panel(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          child: Column(
            children: [
              for (final (icon, color, label, onTap) in items)
                Pressable(
                  onTap: onTap,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 10,
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: color.withValues(
                              alpha: context.isDark ? 0.25 : 0.14,
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            icon,
                            size: 20,
                            color: legibleStatus(color, context),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(label, style: context.text.bodyMedium),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          color: context.tokens.faint,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

Color legibleStatus(Color color, BuildContext context) =>
    context.isDark ? Color.lerp(color, Colors.white, 0.4)! : color;

class _Payments extends ConsumerWidget {
  const _Payments({required this.o});

  final EventOverview o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final upcoming = o.upcomingPayments.take(4).toList();
    final t = context.tokens;
    if (upcoming.isEmpty) {
      return Panel(
        child: Text(
          'Nothing due. Expenses with a due date and a balance left appear here.',
          style: context.text.bodyMedium?.copyWith(color: t.muted),
        ),
      );
    }
    final categories = {
      for (final c in o.categories) c.category.id: c.category,
    };
    return Panel(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Column(
        children: [
          for (var i = 0; i < upcoming.length; i++) ...[
            if (i > 0) Divider(color: t.border),
            Pressable(
              onTap: () => openExpenseDetail(context, upcoming[i].id),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Builder(
                  builder: (context) {
                    final e = upcoming[i];
                    final c = categories[e.categoryId];
                    final overdue = e.statusAt(o.now) == PaymentStatus.overdue;
                    return Row(
                      children: [
                        _DateBlock(date: e.dueDate!, overdue: overdue),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                e.title,
                                style: context.text.titleSmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Icon(
                                    categoryIcon(c?.iconKey),
                                    size: 13,
                                    color: t.muted,
                                  ),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(
                                      '${c?.name ?? 'Uncategorised'} · ${relativeDay(e.dueDate!, now: o.now)}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: context.text.bodySmall?.copyWith(
                                        color: overdue
                                            ? legibleStatus(
                                                StatusColors.danger,
                                                context,
                                              )
                                            : t.muted,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '–${money.format(e.outstanding)}',
                          style: context.text.titleSmall,
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// A calendar-leaf style date: day number over a short month.
class _DateBlock extends StatelessWidget {
  const _DateBlock({required this.date, required this.overdue});

  final DateTime date;
  final bool overdue;

  @override
  Widget build(BuildContext context) {
    const months = [
      'JAN',
      'FEB',
      'MAR',
      'APR',
      'MAY',
      'JUN',
      'JUL',
      'AUG',
      'SEP',
      'OCT',
      'NOV',
      'DEC',
    ];
    final bg = overdue
        ? StatusColors.danger.withValues(alpha: 0.15)
        : context.tokens.track;
    final fg = overdue
        ? legibleStatus(StatusColors.danger, context)
        : context.tokens.ink;
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '${date.day}',
            style: context.text.titleMedium?.copyWith(color: fg, height: 1.1),
          ),
          Text(
            months[date.month - 1],
            style: context.text.labelSmall?.copyWith(color: fg, fontSize: 9.5),
          ),
        ],
      ),
    );
  }
}

class _Tasks extends ConsumerWidget {
  const _Tasks({required this.o});

  final EventOverview o;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = context.tokens;
    if (o.taskCount == 0) {
      return Panel(
        child: Text(
          'No tasks yet. Build a checklist so nothing slips.',
          style: context.text.bodyMedium?.copyWith(color: t.muted),
        ),
      );
    }
    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('${o.tasksDone}', style: context.text.headlineSmall),
              Text(
                ' / ${o.taskCount} done',
                style: context.text.bodyMedium?.copyWith(color: t.muted),
              ),
              const Spacer(),
              StatusPill(
                label: '${(o.taskProgress * 100).round()}%',
                color: context.isDark ? context.highlight : inkOnHighlight,
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: o.taskProgress,
            color: context.isDark ? context.highlight : t.ink,
            height: 8,
          ),
          const SizedBox(height: 6),
          for (final task in o.nextTasks.take(3))
            Pressable(
              onTap: () {
                HapticFeedback.lightImpact();
                ref.read(taskDaoProvider).update(task.toggled(DateTime.now()));
              },
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Row(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: priorityColor(task.priority),
                          width: 2,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        task.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: context.text.bodyMedium,
                      ),
                    ),
                    if (task.dueDate != null)
                      Text(
                        relativeDay(task.dueDate!, now: o.now),
                        style: context.text.labelMedium?.copyWith(
                          color: task.isOverdue(o.now)
                              ? legibleStatus(StatusColors.danger, context)
                              : t.muted,
                        ),
                      ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _Guests extends StatelessWidget {
  const _Guests({required this.o, required this.onOpen});

  final EventOverview o;
  final OpenSection onOpen;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final attending = o.guests
        .where((g) => g.rsvp == RsvpStatus.attending)
        .toList();
    final shown = (attending.isNotEmpty ? attending : o.guests)
        .take(5)
        .toList();
    final awaiting =
        o.rsvpCount(RsvpStatus.pending) + o.rsvpCount(RsvpStatus.maybe);
    return Panel(
      onTap: () => onOpen(EventSection.people, people: PeopleView.guests),
      child: o.guests.isEmpty
          ? Text(
              'No guests yet. Add people to track RSVPs and headcount.',
              style: context.text.bodyMedium?.copyWith(color: t.muted),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 50,
                  child: Row(
                    children: [
                      for (final g in shown)
                        Align(
                          widthFactor: 0.78,
                          child: InitialsAvatar(
                            name: g.name,
                            size: 50,
                            ring: t.card,
                          ),
                        ),
                      if (o.guests.length > shown.length)
                        Align(
                          widthFactor: 0.78,
                          child: Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: t.track,
                              shape: BoxShape.circle,
                              border: Border.all(color: t.card, width: 2.5),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              '+${o.guests.length - shown.length}',
                              style: context.text.labelLarge,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _Count(value: o.headcount, label: 'Headcount'),
                    ),
                    Expanded(
                      child: _Count(
                        value: o.rsvpCount(RsvpStatus.attending),
                        label: 'Attending',
                      ),
                    ),
                    Expanded(
                      child: _Count(value: awaiting, label: 'Awaiting'),
                    ),
                    Expanded(
                      child: _Count(
                        value: o.vendorsBooked,
                        label: 'Vendors booked',
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }
}

class _Count extends StatelessWidget {
  const _Count({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('$value', style: context.text.titleLarge),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: context.text.labelSmall?.copyWith(color: context.tokens.muted),
        ),
      ],
    );
  }
}
