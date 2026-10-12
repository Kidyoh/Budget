import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/common.dart';
import '../../data/event_overview.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../events/event_detail_screen.dart';
import '../expenses/expense_detail_screen.dart';

class OverviewTab extends ConsumerWidget {
  const OverviewTab({
    super.key,
    required this.eventId,
    required this.onOpenTab,
  });

  final String eventId;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AsyncView(
      value: ref.watch(overviewProvider(eventId)),
      data: (overview) {
        if (overview == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            _HeroCard(overview: overview),
            const SizedBox(height: 12),
            _BudgetCard(overview: overview, onOpenTab: onOpenTab),
            _Alerts(overview: overview, onOpenTab: onOpenTab),
            SectionHeader(
              'Spending by category',
              trailing: TextButton(
                onPressed: () => onOpenTab(EventTabs.budget),
                child: const Text('Budget'),
              ),
            ),
            _CategoryBreakdown(overview: overview),
            SectionHeader(
              'Upcoming payments',
              trailing: TextButton(
                onPressed: () => onOpenTab(EventTabs.expenses),
                child: const Text('All expenses'),
              ),
            ),
            _UpcomingPayments(overview: overview),
            SectionHeader(
              'Tasks',
              trailing: TextButton(
                onPressed: () => onOpenTab(EventTabs.tasks),
                child: const Text('All tasks'),
              ),
            ),
            _TaskSummary(overview: overview),
            SectionHeader(
              'Guests & vendors',
              trailing: TextButton(
                onPressed: () => onOpenTab(EventTabs.guests),
                child: const Text('Guest list'),
              ),
            ),
            _PeopleSummary(overview: overview, onOpenTab: onOpenTab),
          ],
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.overview});

  final EventOverview overview;

  @override
  Widget build(BuildContext context) {
    final event = overview.event;
    final color = Color(event.colorValue);
    final text = Theme.of(context).textTheme;
    final days = overview.daysUntil;
    final ongoing = days <= 0 && !event.isPast(overview.now);

    final (big, small) = event.isPast(overview.now)
        ? ('Done', 'event finished')
        : ongoing
        ? ('Today', 'it’s happening')
        : ('$days', days == 1 ? 'day to go' : 'days to go');

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [color, Color.lerp(color, Colors.black, 0.35)!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      eventTypeIcon(event.type),
                      color: Colors.white70,
                      size: 18,
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        '${event.type.label} · ${event.status.label}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: text.labelLarge?.copyWith(color: Colors.white70),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  formatDateRange(event.startDate, event.endDate),
                  style: text.titleMedium?.copyWith(color: Colors.white),
                ),
                if (event.location.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.place_outlined,
                        color: Colors.white70,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          event.location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
                if (event.description.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    event.description,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(color: Colors.white),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 92,
            padding: const EdgeInsets.symmetric(vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              children: [
                FittedBox(
                  child: Text(
                    big,
                    style: text.headlineMedium?.copyWith(color: Colors.white),
                  ),
                ),
                Text(
                  small,
                  textAlign: TextAlign.center,
                  style: text.labelSmall?.copyWith(color: Colors.white70),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BudgetCard extends ConsumerWidget {
  const _BudgetCard({required this.overview, required this.onOpenTab});

  final EventOverview overview;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final fraction = overview.usedFraction;
    final ringColor = usageColor(fraction, scheme);

    return Card(
      child: InkWell(
        onTap: () => onOpenTab(EventTabs.budget),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              ProgressRing(
                value: fraction,
                color: ringColor,
                size: 128,
                strokeWidth: 13,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      overview.budget <= 0
                          ? '—'
                          : '${(fraction * 100).round()}%',
                      style: text.headlineSmall?.copyWith(color: ringColor),
                    ),
                    Text(
                      'used',
                      style: text.labelSmall?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _Figure(
                      label: 'Budget',
                      value: money.short(overview.budget),
                    ),
                    _Figure(
                      label: 'Committed',
                      value: money.short(overview.committed),
                    ),
                    _Figure(
                      label: 'Paid',
                      value: money.short(overview.paid),
                      color: StatusColors.success,
                    ),
                    _Figure(
                      label: overview.remaining >= 0
                          ? 'Remaining'
                          : 'Over budget',
                      value: money.short(overview.remaining.abs()),
                      color: overview.remaining >= 0
                          ? scheme.primary
                          : StatusColors.danger,
                      emphasise: true,
                    ),
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

class _Figure extends StatelessWidget {
  const _Figure({
    required this.label,
    required this.value,
    this.color,
    this.emphasise = false,
  });

  final String label;
  final String value;
  final Color? color;
  final bool emphasise;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
          ),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                style: (emphasise ? text.titleMedium : text.bodyLarge)
                    ?.copyWith(
                      color: color,
                      fontWeight: emphasise ? FontWeight.w700 : FontWeight.w600,
                    ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Alerts extends ConsumerWidget {
  const _Alerts({required this.overview, required this.onOpenTab});

  final EventOverview overview;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final alerts = <Widget>[
      if (overview.isOverBudget)
        _AlertTile(
          icon: Icons.warning_amber_rounded,
          color: StatusColors.danger,
          text:
              'Committed spending is ${money.short(-overview.remaining)} over the total budget.',
          onTap: () => onOpenTab(EventTabs.budget),
        ),
      if (overview.overBudgetCategories.isNotEmpty)
        _AlertTile(
          icon: Icons.pie_chart_rounded,
          color: StatusColors.warning,
          text: overview.overBudgetCategories.length == 1
              ? '${overview.overBudgetCategories.first.category.name} is over its allocation.'
              : '${overview.overBudgetCategories.length} categories are over their allocation.',
          onTap: () => onOpenTab(EventTabs.budget),
        ),
      if (overview.overdueExpenses.isNotEmpty)
        _AlertTile(
          icon: Icons.schedule_rounded,
          color: StatusColors.danger,
          text: overview.overdueExpenses.length == 1
              ? '1 payment is overdue.'
              : '${overview.overdueExpenses.length} payments are overdue.',
          onTap: () => onOpenTab(EventTabs.expenses),
        ),
      if (overview.overdueTasks.isNotEmpty)
        _AlertTile(
          icon: Icons.assignment_late_outlined,
          color: StatusColors.warning,
          text: overview.overdueTasks.length == 1
              ? '1 task is past its due date.'
              : '${overview.overdueTasks.length} tasks are past their due date.',
          onTap: () => onOpenTab(EventTabs.tasks),
        ),
    ];
    if (alerts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Column(
        children: [
          for (final a in alerts)
            Padding(padding: const EdgeInsets.only(bottom: 8), child: a),
        ],
      ),
    );
  }
}

class _AlertTile extends StatelessWidget {
  const _AlertTile({
    required this.icon,
    required this.color,
    required this.text,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: color.withValues(alpha: isDark ? 0.2 : 0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          child: Row(
            children: [
              Icon(
                icon,
                color: isDark ? Color.lerp(color, Colors.white, 0.4) : color,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text)),
              const Icon(Icons.chevron_right_rounded),
            ],
          ),
        ),
      ),
    );
  }
}

class _CategoryBreakdown extends ConsumerWidget {
  const _CategoryBreakdown({required this.overview});

  final EventOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final spent = overview.categories.where((c) => c.committed > 0).toList()
      ..sort((a, b) => b.committed.compareTo(a.committed));
    final top = spent.take(5).toList();
    final rest =
        spent.skip(5).fold<double>(0, (s, c) => s + c.committed) +
        overview.uncategorised;

    final legend = <(String, double, Color)>[
      for (final c in top)
        (c.category.name, c.committed, Color(c.category.colorValue)),
      if (rest > 0) ('Other', rest, scheme.outline),
    ];

    if (legend.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'No expenses yet. Add one and it will show up here by category.',
          ),
        ),
      );
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            DonutChart(
              size: 132,
              strokeWidth: 20,
              slices: [
                for (final l in legend) DonutSlice(value: l.$2, color: l.$3),
              ],
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Total',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 26),
                    child: FittedBox(
                      child: Text(
                        money.compact(overview.committed),
                        style: text.titleMedium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Expanded(
              child: Column(
                children: [
                  for (final (name, value, color) in legend)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.bodySmall,
                            ),
                          ),
                          Text(money.compact(value), style: text.labelMedium),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _UpcomingPayments extends ConsumerWidget {
  const _UpcomingPayments({required this.overview});

  final EventOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final upcoming = overview.upcomingPayments.take(4).toList();
    if (upcoming.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text(
            'Nothing due. Expenses with a due date and a balance left to pay appear here.',
          ),
        ),
      );
    }
    return Card(
      child: Column(
        children: [
          for (final e in upcoming)
            ListTile(
              onTap: () => openExpenseDetail(context, e.id),
              leading: IconBadge(
                icon: Icons.event_note_rounded,
                color: paymentStatusColor(e.statusAt(overview.now)),
                size: 40,
              ),
              title: Text(
                e.title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Text(
                '${formatShortDate(e.dueDate!)} · ${relativeDay(e.dueDate!, now: overview.now)}',
                style: TextStyle(
                  color: e.statusAt(overview.now) == PaymentStatus.overdue
                      ? StatusColors.danger
                      : scheme.onSurfaceVariant,
                ),
              ),
              trailing: Text(
                money.short(e.outstanding),
                style: Theme.of(context).textTheme.titleSmall,
              ),
            ),
        ],
      ),
    );
  }
}

class _TaskSummary extends ConsumerWidget {
  const _TaskSummary({required this.overview});

  final EventOverview overview;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    if (overview.taskCount == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Text('No tasks yet. Build a checklist so nothing slips.'),
        ),
      );
    }
    return Card(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${overview.tasksDone} of ${overview.taskCount} done',
                    style: text.titleSmall,
                  ),
                ),
                Text(
                  '${(overview.taskProgress * 100).round()}%',
                  style: text.titleSmall?.copyWith(color: scheme.primary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ProgressBar(value: overview.taskProgress, color: scheme.primary),
            const SizedBox(height: 4),
            for (final t in overview.nextTasks.take(3))
              ListTile(
                contentPadding: EdgeInsets.zero,
                dense: true,
                leading: Icon(
                  Icons.radio_button_unchecked_rounded,
                  color: priorityColor(t.priority),
                ),
                title: Text(
                  t.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                trailing: t.dueDate == null
                    ? null
                    : Text(
                        relativeDay(t.dueDate!, now: overview.now),
                        style: text.labelMedium?.copyWith(
                          color: t.isOverdue(overview.now)
                              ? StatusColors.danger
                              : scheme.onSurfaceVariant,
                        ),
                      ),
              ),
          ],
        ),
      ),
    );
  }
}

class _PeopleSummary extends StatelessWidget {
  const _PeopleSummary({required this.overview, required this.onOpenTab});

  final EventOverview overview;
  final ValueChanged<int> onOpenTab;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: StatTile(
                label: 'Headcount',
                value: '${overview.headcount}',
                icon: Icons.groups_rounded,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                label: 'Attending',
                value: '${overview.rsvpCount(RsvpStatus.attending)}',
                icon: Icons.check_circle_outline_rounded,
                color: StatusColors.success,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: StatTile(
                label: 'Awaiting',
                value:
                    '${overview.rsvpCount(RsvpStatus.pending) + overview.rsvpCount(RsvpStatus.maybe)}',
                icon: Icons.hourglass_bottom_rounded,
                color: StatusColors.warning,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Card(
          child: ListTile(
            onTap: () => onOpenTab(EventTabs.vendors),
            leading: const Icon(Icons.storefront_outlined),
            title: Text(
              '${overview.vendorsBooked} of ${overview.vendors.length} vendors booked',
            ),
            trailing: const Icon(Icons.chevron_right_rounded),
          ),
        ),
      ],
    );
  }
}
