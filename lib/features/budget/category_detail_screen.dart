import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../expenses/expense_form_screen.dart';
import '../expenses/expense_tile.dart';
import 'category_form.dart';

class CategoryDetailScreen extends ConsumerWidget {
  const CategoryDetailScreen({
    super.key,
    required this.eventId,
    required this.categoryId,
  });

  final String eventId;
  final String categoryId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    CategoryWithSpend data,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete category?',
      message: data.expenseCount == 0
          ? '"${data.category.name}" will be deleted.'
          : '"${data.category.name}" will be deleted. Its ${data.expenseCount} expenses are kept and become uncategorised.',
    );
    if (!ok) return;
    await ref.read(categoryDaoProvider).delete(data.category.id);
    if (context.mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider(eventId)).value;
    final data = categories
        ?.where((c) => c.category.id == categoryId)
        .firstOrNull;
    final expenses =
        (ref.watch(expensesProvider(eventId)).value ?? const <Expense>[])
            .where((e) => e.categoryId == categoryId)
            .toList();
    final money = ref.watch(moneyProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    if (data == null) {
      return Scaffold(
        appBar: pageBar(context, title: ''),
        body: categories == null
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.category_outlined,
                title: 'Category not found',
                message: 'It may have been deleted.',
              ),
      );
    }
    final c = data.category;
    final color = Color(c.colorValue);

    return Scaffold(
      appBar: pageBar(
        context,
        title: c.name,
        actions: [
          CircleButton(
            tooltip: 'Edit category',
            icon: Icons.edit_outlined,
            onTap: () =>
                showCategoryForm(context, ref, eventId: eventId, category: c),
          ),
          CircleButton(
            tooltip: 'Delete category',
            icon: Icons.delete_outline_rounded,
            onTap: () => _delete(context, ref, data),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () =>
            openExpenseForm(context, eventId: eventId, categoryId: categoryId),
        icon: const Icon(Icons.add_rounded),
        label: const Text('Expense'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    children: [
                      IconBadge(
                        icon: categoryIcon(c.iconKey),
                        color: color,
                        size: 52,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              money.short(data.committed),
                              style: text.headlineSmall,
                            ),
                            Text(
                              'committed of ${money.short(c.allocated)} allocated',
                              style: text.bodyMedium?.copyWith(
                                color: scheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  ProgressBar(
                    value: data.usedFraction,
                    color: data.isOverBudget ? StatusColors.danger : color,
                    height: 10,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: StatTile(
                          label: 'Paid',
                          value: money.compact(data.paid),
                          color: StatusColors.success,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: 'To pay',
                          value: money.compact(data.committed - data.paid),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: StatTile(
                          label: data.isOverBudget ? 'Over' : 'Left',
                          value: money.compact(data.remaining.abs()),
                          color: data.isOverBudget ? StatusColors.danger : null,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Expenses'),
          if (expenses.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('No expenses in this category yet.')),
            )
          else
            Card(
              child: Column(
                children: [for (final e in expenses) ExpenseTile(expense: e)],
              ),
            ),
        ],
      ),
    );
  }
}
