import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/id.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'expense_form_screen.dart';
import 'receipts.dart';

void openExpenseDetail(BuildContext context, String expenseId) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => ExpenseDetailScreen(expenseId: expenseId),
    ),
  );
}

class ExpenseDetailScreen extends ConsumerWidget {
  const ExpenseDetailScreen({super.key, required this.expenseId});

  final String expenseId;

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    Expense expense,
  ) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete expense?',
      message:
          '"${expense.title}" and its payment history will be permanently deleted.',
    );
    if (!ok) return;
    await ref.read(expenseDaoProvider).delete(expense.id);
    await deleteReceipt(expense.receiptPath);
    if (context.mounted) Navigator.pop(context);
  }

  Future<void> _markPaid(WidgetRef ref, Expense expense) {
    return ref
        .read(paymentDaoProvider)
        .insert(
          Payment(
            id: newId(),
            expenseId: expense.id,
            amount: expense.outstanding,
            date: DateTime.now(),
            method: PaymentMethod.other,
            note: 'Marked as paid',
          ),
        );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final expenseValue = ref.watch(expenseProvider(expenseId));
    final expense = expenseValue.value;
    if (expense == null) {
      return Scaffold(
        appBar: AppBar(),
        body: expenseValue.isLoading
            ? const Center(child: CircularProgressIndicator())
            : const EmptyState(
                icon: Icons.receipt_long_outlined,
                title: 'Expense not found',
                message: 'It may have been deleted.',
              ),
      );
    }

    final money = ref.watch(moneyProvider);
    final payments =
        ref.watch(paymentsProvider(expenseId)).value ?? const <Payment>[];
    final categories =
        ref.watch(categoriesProvider(expense.eventId)).value ?? const [];
    final vendors =
        ref.watch(vendorsProvider(expense.eventId)).value ?? const [];
    final category = categories
        .where((c) => c.category.id == expense.categoryId)
        .firstOrNull
        ?.category;
    final vendor = vendors
        .where((v) => v.vendor.id == expense.vendorId)
        .firstOrNull
        ?.vendor;
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final now = DateTime.now();
    final status = expense.statusAt(now);
    final paidFraction = expense.amount <= 0
        ? 1.0
        : expense.paidAmount / expense.amount;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Expense'),
        actions: [
          IconButton(
            tooltip: 'Edit',
            icon: const Icon(Icons.edit_outlined),
            onPressed: () => openExpenseForm(
              context,
              eventId: expense.eventId,
              expense: expense,
            ),
          ),
          IconButton(
            tooltip: 'Delete',
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => _delete(context, ref, expense),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(expense.title, style: text.titleLarge),
                      ),
                      StatusPill(
                        label: status.label,
                        color: paymentStatusColor(status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(money.format(expense.amount), style: text.displaySmall),
                  const SizedBox(height: 14),
                  ProgressBar(
                    value: paidFraction,
                    color: paymentStatusColor(status),
                    height: 10,
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Text(
                        'Paid ${money.format(expense.paidAmount)}',
                        style: text.bodyMedium?.copyWith(
                          color: StatusColors.success,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        '${money.format(expense.outstanding)} to pay',
                        style: text.bodyMedium?.copyWith(
                          color: scheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  if (expense.outstanding > 0) ...[
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: FilledButton.icon(
                            onPressed: () =>
                                showPaymentSheet(context, ref, expense),
                            icon: const Icon(Icons.add_card_rounded),
                            label: const Text('Record payment'),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => _markPaid(ref, expense),
                            icon: const Icon(Icons.done_all_rounded),
                            label: const Text('Mark paid'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                _DetailRow(
                  icon: category == null
                      ? Icons.category_outlined
                      : categoryIcon(category.iconKey),
                  label: 'Category',
                  value: category?.name ?? 'Uncategorised',
                ),
                if (vendor != null)
                  _DetailRow(
                    icon: Icons.storefront_outlined,
                    label: 'Vendor',
                    value: vendor.name,
                  ),
                if (expense.dueDate != null)
                  _DetailRow(
                    icon: Icons.schedule_rounded,
                    label: 'Due',
                    value:
                        '${formatLongDate(expense.dueDate!)} (${relativeDay(expense.dueDate!, now: now).toLowerCase()})',
                    valueColor: status == PaymentStatus.overdue
                        ? StatusColors.danger
                        : null,
                  ),
                _DetailRow(
                  icon: Icons.history_rounded,
                  label: 'Added',
                  value: formatDate(expense.createdAt),
                ),
              ],
            ),
          ),
          if (expense.notes.isNotEmpty) ...[
            const SectionHeader('Notes'),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SelectableText(expense.notes),
              ),
            ),
          ],
          if (expense.receiptPath != null) ...[
            const SectionHeader('Receipt'),
            GestureDetector(
              onTap: () => _showReceipt(context, expense.receiptPath!),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.file(
                  File(expense.receiptPath!),
                  height: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, _, _) => Container(
                    height: 100,
                    color: scheme.surfaceContainerHighest,
                    alignment: Alignment.center,
                    child: const Text('Receipt image is missing'),
                  ),
                ),
              ),
            ),
          ],
          SectionHeader('Payments (${payments.length})'),
          if (payments.isEmpty)
            const Card(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Text(
                  'No payments recorded yet. Deposits and instalments go here.',
                ),
              ),
            )
          else
            Card(
              child: Column(
                children: [
                  for (final payment in payments)
                    ListTile(
                      leading: IconBadge(
                        icon: paymentMethodIcon(payment.method),
                        color: StatusColors.success,
                        size: 40,
                      ),
                      title: Text(money.format(payment.amount)),
                      subtitle: Text(
                        [
                          formatDate(payment.date),
                          payment.method.label,
                          if (payment.note.isNotEmpty) payment.note,
                        ].join(' · '),
                      ),
                      trailing: IconButton(
                        tooltip: 'Remove payment',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: () async {
                          final ok = await confirmDialog(
                            context,
                            title: 'Remove payment?',
                            message:
                                'This ${money.format(payment.amount)} payment will be removed.',
                            confirmLabel: 'Remove',
                          );
                          if (ok) {
                            await ref
                                .read(paymentDaoProvider)
                                .delete(payment.id);
                          }
                        },
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  void _showReceipt(BuildContext context, String path) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            foregroundColor: Colors.white,
            title: const Text('Receipt'),
          ),
          body: InteractiveViewer(
            maxScale: 5,
            child: Center(child: Image.file(File(path))),
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListTile(
      leading: Icon(icon, color: scheme.onSurfaceVariant),
      title: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: scheme.onSurfaceVariant),
      ),
      subtitle: Text(
        value,
        style: Theme.of(context).textTheme.bodyLarge
            ?.copyWith(color: valueColor),
      ),
    );
  }
}

Future<void> showPaymentSheet(
  BuildContext context,
  WidgetRef ref,
  Expense expense,
) {
  return showFormSheet(context, child: _PaymentForm(expense: expense));
}

class _PaymentForm extends ConsumerStatefulWidget {
  const _PaymentForm({required this.expense});

  final Expense expense;

  @override
  ConsumerState<_PaymentForm> createState() => _PaymentFormState();
}

class _PaymentFormState extends ConsumerState<_PaymentForm> {
  final _formKey = GlobalKey<FormState>();
  late final _amount = TextEditingController(
    text: amountText(widget.expense.outstanding),
  );
  final _note = TextEditingController();
  DateTime _date = DateTime.now();
  PaymentMethod _method = PaymentMethod.card;

  @override
  void dispose() {
    _amount.dispose();
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    await ref
        .read(paymentDaoProvider)
        .insert(
          Payment(
            id: newId(),
            expenseId: widget.expense.id,
            amount: parseAmount(_amount.text)!,
            date: _date,
            method: _method,
            note: _note.text.trim(),
          ),
        );
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Record payment', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 4),
          Text(
            '${money.format(widget.expense.outstanding)} left to pay on ${widget.expense.title}',
          ),
          const SizedBox(height: 16),
          AmountField(
            controller: _amount,
            label: 'Amount',
            prefix: money.currency.symbol,
            autofocus: true,
            max: (
              widget.expense.outstanding,
              'That’s more than the ${money.format(widget.expense.outstanding)} left to pay',
            ),
          ),
          const SizedBox(height: 12),
          DateField(
            label: 'Paid on',
            value: _date,
            clearable: false,
            onChanged: (d) => setState(() => _date = d ?? _date),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final m in PaymentMethod.values)
                ChoiceChip(
                  avatar: Icon(paymentMethodIcon(m), size: 18),
                  label: Text(m.label),
                  selected: _method == m,
                  showCheckmark: false,
                  onSelected: (_) => setState(() => _method = m),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _note,
            decoration: const InputDecoration(
              labelText: 'Note (optional)',
              hintText: 'e.g. Deposit',
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save payment')),
        ],
      ),
    );
  }
}
