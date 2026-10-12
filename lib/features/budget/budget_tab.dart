import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/visuals.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/common.dart';
import '../../data/budget_templates.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'category_detail_screen.dart';
import 'category_form.dart';

class BudgetTab extends ConsumerWidget {
  const BudgetTab({super.key, required this.eventId});

  final String eventId;

  Future<void> _applyTemplate(WidgetRef ref, Event event) async {
    final dao = ref.read(categoryDaoProvider);
    await dao.insertAll(
      categoriesFromTemplate(
        eventId: event.id,
        type: event.type,
        totalBudget: event.totalBudget,
        startSortOrder: await dao.nextSortOrder(event.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = ref.watch(eventProvider(eventId)).value;
    final expenses =
        ref.watch(expensesProvider(eventId)).value ?? const <Expense>[];

    return AsyncView(
      value: ref.watch(categoriesProvider(eventId)),
      data: (categories) {
        if (event == null) return const SizedBox.shrink();
        if (categories.isEmpty) {
          return EmptyState(
            icon: Icons.donut_small_rounded,
            title: 'No budget categories',
            message:
                'Split your ${event.type.label.toLowerCase()} budget into categories to see where the money goes.',
            action: Column(
              children: [
                FilledButton.icon(
                  onPressed: () => _applyTemplate(ref, event),
                  icon: const Icon(Icons.auto_awesome_rounded),
                  label: const Text('Use suggested categories'),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: () =>
                      showCategoryForm(context, ref, eventId: eventId),
                  child: const Text('Add my own'),
                ),
              ],
            ),
          );
        }
        final uncategorised = expenses
            .where((e) => e.categoryId == null)
            .toList();
        return ListView(
          padding: const EdgeInsets.fromLTRB(
            Insets.page,
            12,
            Insets.page,
            Insets.navClearance,
          ),
          children: [
            _Summary(event: event, categories: categories).enter(),
            const SectionHeader('Categories'),
            for (var i = 0; i < categories.length; i++) ...[
              _CategoryRow(data: categories[i]).enter(i + 1),
              const SizedBox(height: 10),
            ],
            if (uncategorised.isNotEmpty)
              _UncategorisedRow(expenses: uncategorised),
          ],
        );
      },
    );
  }
}

class _Summary extends ConsumerWidget {
  const _Summary({required this.event, required this.categories});

  final Event event;
  final List<CategoryWithSpend> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final t = context.tokens;
    final allocated = categories.fold<double>(
      0,
      (s, c) => s + c.category.allocated,
    );
    final committed = categories.fold<double>(0, (s, c) => s + c.committed);
    final unallocated = event.totalBudget - allocated;
    final paidColor = context.isDark ? Colors.white : heroInk;

    return Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Committed so far',
            style: context.text.bodyMedium?.copyWith(color: t.muted),
          ),
          const SizedBox(height: 2),
          BigAmount(committed, style: context.text.displaySmall),
          const SizedBox(height: 4),
          Text(
            '${money.format(allocated)} allocated of ${money.format(event.totalBudget)}',
            style: context.text.bodySmall?.copyWith(color: t.muted),
          ),
          const SizedBox(height: 20),
          StackedBarChart(
            bars: [
              for (final c in categories)
                BarDatum(
                  label: c.category.name,
                  icon: categoryIcon(c.category.iconKey),
                  paid: c.paid,
                  unpaid: c.committed - c.paid,
                  allocated: c.category.allocated,
                ),
            ],
            format: money.compact,
            paidColor: paidColor,
            unpaidColor: context.highlight,
            hatchColor: t.faint.withValues(alpha: 0.6),
            height: 150,
          ),
          const SizedBox(height: 4),
          Wrap(
            spacing: 16,
            runSpacing: 6,
            children: [
              _Key(color: paidColor, label: 'Paid'),
              _Key(color: context.highlight, label: 'Unpaid'),
              _Key(color: t.faint, label: 'Unspent allocation', hatched: true),
            ],
          ),
          const SizedBox(height: 16),
          if (unallocated.abs() < 0.005)
            const StatusPill(
              label: 'Fully allocated',
              color: StatusColors.success,
              icon: Icons.check_rounded,
            )
          else if (unallocated > 0)
            StatusPill(
              label: '${money.short(unallocated)} not yet allocated',
              color: StatusColors.info,
            )
          else
            StatusPill(
              label:
                  'Allocations exceed the budget by ${money.short(-unallocated)}',
              color: StatusColors.danger,
              icon: Icons.warning_amber_rounded,
            ),
        ],
      ),
    );
  }
}

class _Key extends StatelessWidget {
  const _Key({required this.color, required this.label, this.hatched = false});

  final Color color;
  final String label;
  final bool hatched;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: hatched ? null : color,
            borderRadius: BorderRadius.circular(4),
            border: hatched ? Border.all(color: color) : null,
          ),
          child: hatched
              ? CustomPaint(
                  painter: HatchPainter(color: color, gap: 4, stroke: 1),
                )
              : null,
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: context.text.labelMedium?.copyWith(
            color: context.tokens.muted,
          ),
        ),
      ],
    );
  }
}

class _CategoryRow extends ConsumerWidget {
  const _CategoryRow({required this.data});

  final CategoryWithSpend data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final t = context.tokens;
    final c = data.category;
    final color = visible(Color(c.colorValue), context);

    return Panel(
      padding: const EdgeInsets.all(14),
      radius: Insets.smallRadius + 2,
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              CategoryDetailScreen(eventId: c.eventId, categoryId: c.id),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              IconBadge(
                icon: categoryIcon(c.iconKey),
                color: Color(c.colorValue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.name,
                      style: context.text.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      data.isOverBudget
                          ? '${money.short(-data.remaining)} over'
                          : '${money.short(data.remaining)} left',
                      style: context.text.bodySmall?.copyWith(
                        color: data.isOverBudget
                            ? StatusColors.danger
                            : t.muted,
                      ),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    money.short(data.committed),
                    style: context.text.titleSmall,
                  ),
                  Text(
                    'of ${money.short(c.allocated)}',
                    style: context.text.bodySmall?.copyWith(color: t.muted),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          ProgressBar(
            value: data.usedFraction,
            color: data.isOverBudget ? StatusColors.danger : color,
            height: 6,
          ),
        ],
      ),
    );
  }
}

class _UncategorisedRow extends ConsumerWidget {
  const _UncategorisedRow({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    return Panel(
      padding: const EdgeInsets.all(14),
      radius: Insets.smallRadius + 2,
      child: Row(
        children: [
          const IconBadge(
            icon: Icons.help_outline_rounded,
            color: StatusColors.neutral,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uncategorised', style: context.text.titleSmall),
                Text(
                  expenses.length == 1
                      ? '1 expense'
                      : '${expenses.length} expenses',
                  style: context.text.bodySmall?.copyWith(
                    color: context.tokens.muted,
                  ),
                ),
              ],
            ),
          ),
          Text(money.short(total), style: context.text.titleSmall),
        ],
      ),
    );
  }
}
