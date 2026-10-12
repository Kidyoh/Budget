import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'expense_detail_screen.dart';

class ExpenseTile extends ConsumerWidget {
  const ExpenseTile({super.key, required this.expense});

  final Expense expense;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final categories =
        ref.watch(categoriesProvider(expense.eventId)).value ?? const [];
    final category = categories
        .where((c) => c.category.id == expense.categoryId)
        .firstOrNull
        ?.category;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final status = expense.statusAt(now);

    final details = [
      category?.name ?? 'Uncategorised',
      if (expense.dueDate != null && status != PaymentStatus.paid)
        'due ${relativeDay(expense.dueDate!, now: now).toLowerCase()}',
    ].join(' · ');

    return Pressable(
      onTap: () => openExpenseDetail(context, expense.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            IconBadge(
              icon: category == null
                  ? Icons.receipt_long_rounded
                  : categoryIcon(category.iconKey),
              color: category == null
                  ? StatusColors.neutral
                  : Color(category.colorValue),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          expense.title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleSmall,
                        ),
                      ),
                      if (expense.receiptPath != null) ...[
                        const SizedBox(width: 4),
                        Icon(
                          Icons.attach_file_rounded,
                          size: 14,
                          color: scheme.onSurfaceVariant,
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    details,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: text.bodySmall?.copyWith(
                      color: status == PaymentStatus.overdue
                          ? StatusColors.danger
                          : scheme.onSurfaceVariant,
                    ),
                  ),
                  if (status == PaymentStatus.partial ||
                      (status == PaymentStatus.overdue &&
                          expense.paidAmount > 0)) ...[
                    const SizedBox(height: 6),
                    ProgressBar(
                      value: expense.amount <= 0
                          ? 1
                          : expense.paidAmount / expense.amount,
                      color: paymentStatusColor(status),
                      height: 4,
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('–${money.short(expense.amount)}', style: text.titleSmall),
                const SizedBox(height: 4),
                StatusPill(
                  label: status.label,
                  color: paymentStatusColor(status),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
