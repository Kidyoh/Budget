import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
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

        final filters = <(PaymentStatus?, String)>[
          (null, 'All ${expenses.length}'),
          for (final s in [
            PaymentStatus.overdue,
            PaymentStatus.unpaid,
            PaymentStatus.partial,
            PaymentStatus.paid,
          ])
            if (count(s) > 0) (s, '${s.label} ${count(s)}'),
        ];

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
                color: context.heroBg,
                borderRadius: BorderRadius.circular(Insets.radius),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Still to pay',
                    style: context.text.labelMedium?.copyWith(
                      color: context.onHero.withValues(alpha: 0.65),
                    ),
                  ),
                  const SizedBox(height: 4),
                  BigAmount(
                    committed - paid,
                    style: context.text.displaySmall,
                    color: context.onHero,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      _HeroFigure(
                        label: 'Committed',
                        value: money.compact(committed),
                      ),
                      _HeroFigure(label: 'Paid', value: money.compact(paid)),
                      _HeroFigure(
                        label: 'Overdue',
                        value: '${count(PaymentStatus.overdue)}',
                      ),
                    ],
                  ),
                ],
              ),
            ).enter(),
            const SizedBox(height: 16),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search expenses',
                prefixIcon: Icon(Icons.search_rounded),
              ),
              onChanged: (v) => setState(() => _query = v),
            ),
            const SizedBox(height: 12),
            PillFilters<PaymentStatus>(
              options: filters,
              selected: _status,
              onChanged: (s) => setState(() => _status = s),
            ),
            const SizedBox(height: 14),
            if (visible.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 40),
                child: Center(
                  child: Text(
                    'No expenses match.',
                    style: context.text.bodyMedium?.copyWith(
                      color: context.tokens.muted,
                    ),
                  ),
                ),
              )
            else
              Panel(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
                child: Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const Divider(indent: 74, endIndent: 16),
                      ExpenseTile(expense: visible[i]).enter(i),
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

class _HeroFigure extends StatelessWidget {
  const _HeroFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: context.text.labelSmall?.copyWith(
              color: context.onHero.withValues(alpha: 0.6),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: context.text.titleMedium?.copyWith(color: context.onHero),
          ),
        ],
      ),
    );
  }
}
