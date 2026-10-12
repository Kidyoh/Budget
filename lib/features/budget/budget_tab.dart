import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/visuals.dart';
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
            icon: Icons.pie_chart_outline_rounded,
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
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            _AllocationCard(event: event, categories: categories),
            const SectionHeader('Categories'),
            for (final c in categories) ...[
              _CategoryCard(data: c),
              const SizedBox(height: 10),
            ],
            if (uncategorised.isNotEmpty)
              _UncategorisedCard(expenses: uncategorised),
          ],
        );
      },
    );
  }
}

class _AllocationCard extends ConsumerWidget {
  const _AllocationCard({required this.event, required this.categories});

  final Event event;
  final List<CategoryWithSpend> categories;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final allocated = categories.fold<double>(
      0,
      (s, c) => s + c.category.allocated,
    );
    final unallocated = event.totalBudget - allocated;
    final scale = allocated > event.totalBudget ? allocated : event.totalBudget;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Allocation', style: text.titleMedium),
            const SizedBox(height: 4),
            Text(
              '${money.short(allocated)} of ${money.short(event.totalBudget)} assigned to categories',
              style: text.bodyMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 14),
            // Stacked bar: one segment per category, sized by allocation.
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: SizedBox(
                height: 14,
                child: scale <= 0
                    ? ColoredBox(color: scheme.surfaceContainerHighest)
                    : Row(
                        children: [
                          for (final c in categories)
                            if (c.category.allocated > 0)
                              Expanded(
                                flex: (c.category.allocated / scale * 1000)
                                    .round()
                                    .clamp(1, 1000),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 2),
                                  color: Color(c.category.colorValue),
                                ),
                              ),
                          if (unallocated > 0)
                            Expanded(
                              flex: (unallocated / scale * 1000).round().clamp(
                                1,
                                1000,
                              ),
                              child: ColoredBox(
                                color: scheme.surfaceContainerHighest,
                              ),
                            ),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 12),
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
      ),
    );
  }
}

class _CategoryCard extends ConsumerWidget {
  const _CategoryCard({required this.data});

  final CategoryWithSpend data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final c = data.category;
    final color = Color(c.colorValue);

    return Card(
      child: InkWell(
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                CategoryDetailScreen(eventId: c.eventId, categoryId: c.id),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: [
              Row(
                children: [
                  IconBadge(icon: categoryIcon(c.iconKey), color: color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.name, style: text.titleSmall),
                        Text(
                          data.expenseCount == 1
                              ? '1 expense'
                              : '${data.expenseCount} expenses',
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(money.short(data.committed), style: text.titleSmall),
                      Text(
                        'of ${money.short(c.allocated)}',
                        style: text.bodySmall?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ProgressBar(
                value: data.usedFraction,
                color: data.isOverBudget ? StatusColors.danger : color,
              ),
              const SizedBox(height: 6),
              Row(
                children: [
                  Text(
                    'Paid ${money.short(data.paid)}',
                    style: text.labelSmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    data.isOverBudget
                        ? '${money.short(-data.remaining)} over'
                        : '${money.short(data.remaining)} left',
                    style: text.labelSmall?.copyWith(
                      color: data.isOverBudget
                          ? StatusColors.danger
                          : scheme.onSurfaceVariant,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _UncategorisedCard extends ConsumerWidget {
  const _UncategorisedCard({required this.expenses});

  final List<Expense> expenses;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final total = expenses.fold<double>(0, (s, e) => s + e.amount);
    return Card(
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: const IconBadge(
          icon: Icons.help_outline_rounded,
          color: StatusColors.neutral,
        ),
        title: const Text('Uncategorised'),
        subtitle: Text(
          expenses.length == 1 ? '1 expense' : '${expenses.length} expenses',
        ),
        trailing: Text(
          money.short(total),
          style: Theme.of(context).textTheme.titleSmall,
        ),
      ),
    );
  }
}
