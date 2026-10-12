import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'expense_form_screen.dart';
import 'expense_tile.dart';

class ExpensesTab extends ConsumerStatefulWidget {
  const ExpensesTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<ExpensesTab> createState() => _ExpensesTabState();
}

class _ExpensesTabState extends ConsumerState<ExpensesTab> {
  PaymentStatus? _status;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    return AsyncView(
      value: ref.watch(expensesProvider(widget.eventId)),
      data: (expenses) {
        if (expenses.isEmpty) {
          return EmptyState(
            icon: Icons.receipt_long_rounded,
            title: 'No expenses yet',
            message: 'Record quotes, deposits and bills. Add payments as you make them.',
            action: FilledButton.icon(
              onPressed: () =>
                  openExpenseForm(context, eventId: widget.eventId),
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add expense'),
            ),
          );
        }
        final now = DateTime.now();
        final query = _query.trim().toLowerCase();
        final visible = expenses.where((e) {
          if (_status != null && e.statusAt(now) != _status) return false;
          if (query.isNotEmpty && !e.title.toLowerCase().contains(query)) {
            return false;
          }
          return true;
        }).toList();

        final committed = expenses.fold<double>(0, (s, e) => s + e.amount);
        final paid = expenses.fold<double>(0, (s, e) => s + e.paidAmount);
        int count(PaymentStatus s) =>
            expenses.where((e) => e.statusAt(now) == s).length;

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 104),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Committed',
                    value: money.compact(committed),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Paid',
                    value: money.compact(paid),
                    color: StatusColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Outstanding',
                    value: money.compact(committed - paid),
                    color: committed - paid > 0 ? StatusColors.warning : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search expenses',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 8),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All ${expenses.length}'),
                    selected: _status == null,
                    onSelected: (_) => setState(() => _status = null),
                  ),
                  for (final s in [
                    PaymentStatus.overdue,
                    PaymentStatus.unpaid,
                    PaymentStatus.partial,
                    PaymentStatus.paid,
                  ])
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: ChoiceChip(
                        label: Text('${s.label} ${count(s)}'),
                        selected: _status == s,
                        onSelected: (sel) =>
                            setState(() => _status = sel ? s : null),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No expenses match.')),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 70),
                      ExpenseTile(expense: visible[i]),
                    ],
                  ],
                ),
              ),
          ],
        );
      },
    );
  }
}
