import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../../core/id.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'receipts.dart';

Future<void> openExpenseForm(
  BuildContext context, {
  required String eventId,
  Expense? expense,
  String? categoryId,
}) {
  return Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => ExpenseFormScreen(
        eventId: eventId,
        expense: expense,
        initialCategoryId: categoryId,
      ),
    ),
  );
}

class ExpenseFormScreen extends ConsumerStatefulWidget {
  const ExpenseFormScreen({
    super.key,
    required this.eventId,
    this.expense,
    this.initialCategoryId,
  });

  final String eventId;
  final Expense? expense;
  final String? initialCategoryId;

  @override
  ConsumerState<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends ConsumerState<ExpenseFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.expense?.title);
  late final _amount = TextEditingController(
    text: amountText(widget.expense?.amount),
  );
  late final _notes = TextEditingController(text: widget.expense?.notes);
  late String? _categoryId =
      widget.expense?.categoryId ?? widget.initialCategoryId;
  late String? _vendorId = widget.expense?.vendorId;
  late DateTime? _dueDate = widget.expense?.dueDate;
  late String? _receipt = widget.expense?.receiptPath;
  PaymentMethod _paidMethod = PaymentMethod.card;
  bool _paidInFull = false;
  bool _saving = false;
  bool _saved = false;

  bool get _isNew => widget.expense == null;

  @override
  void dispose() {
    // A receipt picked during an abandoned edit would otherwise be orphaned.
    if (!_saved && _receipt != widget.expense?.receiptPath) {
      deleteReceipt(_receipt);
    }
    _title.dispose();
    _amount.dispose();
    _notes.dispose();
    super.dispose();
  }

  Future<void> _pickReceipt() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.pop(context, ImageSource.camera),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.pop(context, ImageSource.gallery),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (source == null) return;
    try {
      final path = await pickReceipt(source);
      if (path == null) return;
      if (_receipt != widget.expense?.receiptPath) {
        await deleteReceipt(_receipt);
      }
      setState(() => _receipt = path);
    } catch (e) {
      if (mounted) showSnack(context, 'Couldn’t attach the receipt: $e');
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    final now = DateTime.now();
    final existing = widget.expense;
    final amount = parseAmount(_amount.text) ?? 0;
    final expense = Expense(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      categoryId: _categoryId,
      vendorId: _vendorId,
      title: _title.text.trim(),
      amount: amount,
      dueDate: _dueDate,
      notes: _notes.text.trim(),
      receiptPath: _receipt,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (existing == null) {
      await ref.read(expenseDaoProvider).insert(expense);
      if (_paidInFull && amount > 0) {
        await ref
            .read(paymentDaoProvider)
            .insert(
              Payment(
                id: newId(),
                expenseId: expense.id,
                amount: amount,
                date: now,
                method: _paidMethod,
              ),
            );
      }
    } else {
      await ref.read(expenseDaoProvider).update(expense);
      if (existing.receiptPath != _receipt) {
        await deleteReceipt(existing.receiptPath);
      }
    }
    _saved = true;
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    final categories =
        ref.watch(categoriesProvider(widget.eventId)).value ?? const [];
    final vendors =
        ref.watch(vendorsProvider(widget.eventId)).value ?? const [];
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final receipt = _receipt;

    // Keep the selection valid if the linked row was deleted meanwhile.
    final categoryId = categories.any((c) => c.category.id == _categoryId)
        ? _categoryId
        : null;
    final vendorId = vendors.any((v) => v.vendor.id == _vendorId)
        ? _vendorId
        : null;

    return Scaffold(
      appBar: pageBar(
        context,
        title: _isNew ? 'New expense' : 'Edit expense',
        actions: [BarButton(label: 'Save', onPressed: _saving ? null : _save)],
        close: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            TextFormField(
              controller: _title,
              autofocus: _isNew,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(labelText: 'What is it for?'),
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Enter a title' : null,
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _amount,
              label: 'Total amount',
              prefix: money.currency.symbol,
              helperText:
                  'The full cost, even if you’ll pay it in instalments.',
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: categoryId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Category'),
              items: [
                const DropdownMenuItem(
                  value: null,
                  child: Text('Uncategorised'),
                ),
                for (final c in categories)
                  DropdownMenuItem(
                    value: c.category.id,
                    child: Row(
                      children: [
                        IconBadge(
                          icon: categoryIcon(c.category.iconKey),
                          color: Color(c.category.colorValue),
                          size: 30,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            c.category.name,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _categoryId = v),
            ),
            const SizedBox(height: 12),
            DropdownButtonFormField<String?>(
              initialValue: vendorId,
              isExpanded: true,
              decoration: const InputDecoration(labelText: 'Vendor'),
              items: [
                const DropdownMenuItem(value: null, child: Text('None')),
                for (final v in vendors)
                  DropdownMenuItem(
                    value: v.vendor.id,
                    child: Text(
                      v.vendor.service.isEmpty
                          ? v.vendor.name
                          : '${v.vendor.name} · ${v.vendor.service}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
              onChanged: (v) => setState(() => _vendorId = v),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'Due date',
              value: _dueDate,
              icon: Icons.schedule_rounded,
              onChanged: (d) => setState(() => _dueDate = d),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _notes,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes',
                alignLabelWithHint: true,
              ),
            ),
            if (_isNew) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                title: const Text('Already paid in full'),
                subtitle: const Text(
                  'Records a payment for the whole amount today.',
                ),
                value: _paidInFull,
                onChanged: (v) => setState(() => _paidInFull = v),
              ),
              if (_paidInFull)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final m in PaymentMethod.values)
                      ChoiceChip(
                        avatar: Icon(paymentMethodIcon(m), size: 18),
                        label: Text(m.label),
                        selected: _paidMethod == m,
                        showCheckmark: false,
                        onSelected: (_) => setState(() => _paidMethod = m),
                      ),
                  ],
                ),
            ],
            const SizedBox(height: 20),
            Text('Receipt', style: text.titleSmall),
            const SizedBox(height: 8),
            if (receipt == null)
              OutlinedButton.icon(
                onPressed: _pickReceipt,
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Attach a receipt photo'),
              )
            else
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Stack(
                  children: [
                    Image.file(
                      File(receipt),
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => Container(
                        height: 120,
                        color: scheme.surfaceContainerHighest,
                        alignment: Alignment.center,
                        child: const Text('Receipt image is missing'),
                      ),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Row(
                        children: [
                          IconButton.filledTonal(
                            tooltip: 'Replace',
                            onPressed: _pickReceipt,
                            icon: const Icon(Icons.swap_horiz_rounded),
                          ),
                          const SizedBox(width: 4),
                          IconButton.filledTonal(
                            tooltip: 'Remove',
                            onPressed: () async {
                              if (_receipt != widget.expense?.receiptPath) {
                                await deleteReceipt(_receipt);
                              }
                              setState(() => _receipt = null);
                            },
                            icon: const Icon(Icons.delete_outline_rounded),
                          ),
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
