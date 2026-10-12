import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/palette.dart';
import '../../core/visuals.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';

Future<void> showCategoryForm(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  BudgetCategory? category,
}) {
  return showFormSheet(
    context,
    child: _CategoryForm(eventId: eventId, category: category),
  );
}

class _CategoryForm extends ConsumerStatefulWidget {
  const _CategoryForm({required this.eventId, this.category});

  final String eventId;
  final BudgetCategory? category;

  @override
  ConsumerState<_CategoryForm> createState() => _CategoryFormState();
}

class _CategoryFormState extends ConsumerState<_CategoryForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.category?.name);
  late final _allocated = TextEditingController(
    text: amountText(widget.category?.allocated),
  );
  late String _icon = widget.category?.iconKey ?? 'misc';
  late int _color = widget.category?.colorValue ?? accentPalette[2];

  @override
  void dispose() {
    _name.dispose();
    _allocated.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final dao = ref.read(categoryDaoProvider);
    final existing = widget.category;
    final category = BudgetCategory(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      name: _name.text.trim(),
      iconKey: _icon,
      colorValue: _color,
      allocated: parseAmount(_allocated.text) ?? 0,
      sortOrder: existing?.sortOrder ?? await dao.nextSortOrder(widget.eventId),
    );
    if (existing == null) {
      await dao.insert(category);
    } else {
      await dao.update(category);
    }
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            widget.category == null ? 'New category' : 'Edit category',
            style: text.titleLarge,
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            autofocus: widget.category == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          AmountField(
            controller: _allocated,
            label: 'Allocated amount',
            prefix: money.currency.symbol,
            allowZero: true,
          ),
          const SizedBox(height: 16),
          Text('Icon', style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final entry in categoryIcons.entries)
                InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => setState(() => _icon = entry.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: _icon == entry.key
                          ? Color(_color).withValues(alpha: 0.2)
                          : scheme.surfaceContainerHighest.withValues(
                              alpha: 0.6,
                            ),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _icon == entry.key
                            ? Color(_color)
                            : Colors.transparent,
                        width: 2,
                      ),
                    ),
                    child: Icon(entry.value, size: 22),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text('Colour', style: text.titleSmall),
          const SizedBox(height: 8),
          ColorSwatchPicker(
            colors: accentPalette,
            selected: _color,
            onChanged: (c) => setState(() => _color = c ?? _color),
          ),
          const SizedBox(height: 24),
          FilledButton(onPressed: _save, child: const Text('Save category')),
        ],
      ),
    );
  }
}
