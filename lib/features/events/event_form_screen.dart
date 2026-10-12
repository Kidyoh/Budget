import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/palette.dart';
import '../../core/visuals.dart';
import '../../core/widgets/fields.dart';
import '../../data/budget_templates.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';

/// Creates or edits an event. Pops with the event id when saved.
class EventFormScreen extends ConsumerStatefulWidget {
  const EventFormScreen({super.key, this.event});

  final Event? event;

  @override
  ConsumerState<EventFormScreen> createState() => _EventFormScreenState();
}

class _EventFormScreenState extends ConsumerState<EventFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.event?.name);
  late final _location = TextEditingController(text: widget.event?.location);
  late final _description = TextEditingController(
    text: widget.event?.description,
  );
  late final _budget = TextEditingController(
    text: amountText(widget.event?.totalBudget),
  );

  late EventType _type = widget.event?.type ?? EventType.wedding;
  late EventStatus _status = widget.event?.status ?? EventStatus.planning;
  late DateTime? _start = widget.event?.startDate;
  late DateTime? _end = widget.event?.endDate;
  late int _color = widget.event?.colorValue ?? accentPalette.first;
  bool _useTemplate = true;
  bool _saving = false;
  String? _dateError;

  bool get _isNew => widget.event == null;

  @override
  void dispose() {
    _name.dispose();
    _location.dispose();
    _description.dispose();
    _budget.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final start = _start;
    setState(() => _dateError = start == null ? 'Pick a start date' : null);
    if (!_formKey.currentState!.validate() || start == null) return;
    final end = _end;
    if (end != null && end.isBefore(start)) {
      setState(() => _dateError = 'The end date is before the start date');
      return;
    }

    setState(() => _saving = true);
    final now = DateTime.now();
    final budget = parseAmount(_budget.text) ?? 0;
    final dao = ref.read(eventDaoProvider);
    final existing = widget.event;
    final event = Event(
      id: existing?.id ?? newId(),
      name: _name.text.trim(),
      type: _type,
      status: _status,
      startDate: start,
      endDate: end,
      location: _location.text.trim(),
      description: _description.text.trim(),
      totalBudget: budget,
      colorValue: _color,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
    if (existing == null) {
      await dao.insert(
        event,
        categories: _useTemplate
            ? categoriesFromTemplate(
                eventId: event.id,
                type: _type,
                totalBudget: budget,
              )
            : const [],
      );
    } else {
      await dao.update(event);
    }
    if (mounted) Navigator.pop(context, event.id);
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
    final text = Theme.of(context).textTheme;
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isNew ? 'New event' : 'Edit event'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton(
              onPressed: _saving ? null : _save,
              child: const Text('Save'),
            ),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
          children: [
            TextFormField(
              controller: _name,
              autofocus: _isNew,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(labelText: 'Event name'),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Give the event a name'
                  : null,
            ),
            const SizedBox(height: 20),
            Text('Type', style: text.titleSmall),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final type in EventType.values)
                  ChoiceChip(
                    avatar: Icon(eventTypeIcon(type), size: 18),
                    label: Text(type.label),
                    selected: _type == type,
                    showCheckmark: false,
                    onSelected: (_) => setState(() => _type = type),
                  ),
              ],
            ),
            const SizedBox(height: 20),
            DateField(
              label: 'Start date',
              value: _start,
              clearable: false,
              onChanged: (d) => setState(() {
                _start = d;
                _dateError = null;
              }),
            ),
            const SizedBox(height: 12),
            DateField(
              label: 'End date (optional)',
              value: _end,
              icon: Icons.event_available_rounded,
              onChanged: (d) => setState(() {
                _end = d;
                _dateError = null;
              }),
            ),
            if (_dateError != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 0),
                child: Text(
                  _dateError!,
                  style: text.bodySmall?.copyWith(color: scheme.error),
                ),
              ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _location,
              textCapitalization: TextCapitalization.words,
              decoration: const InputDecoration(
                labelText: 'Location',
                prefixIcon: Icon(Icons.place_outlined),
              ),
            ),
            const SizedBox(height: 12),
            AmountField(
              controller: _budget,
              label: 'Total budget',
              prefix: money.currency.symbol,
              allowZero: true,
            ),
            if (_isNew) ...[
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: const EdgeInsets.symmetric(horizontal: 4),
                value: _useTemplate,
                onChanged: (v) => setState(() => _useTemplate = v),
                title: const Text('Start with suggested categories'),
                subtitle: Text(
                  'Splits the budget across typical ${_type.label.toLowerCase()} costs. You can change them later.',
                ),
              ),
            ],
            const SizedBox(height: 12),
            DropdownButtonFormField<EventStatus>(
              initialValue: _status,
              decoration: const InputDecoration(labelText: 'Status'),
              items: [
                for (final s in EventStatus.values)
                  DropdownMenuItem(value: s, child: Text(s.label)),
              ],
              onChanged: (s) => setState(() => _status = s ?? _status),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _description,
              minLines: 2,
              maxLines: 5,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description',
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 20),
            Text('Colour', style: text.titleSmall),
            const SizedBox(height: 10),
            ColorSwatchPicker(
              colors: accentPalette,
              selected: _color,
              onChanged: (c) => setState(() => _color = c ?? _color),
            ),
          ],
        ),
      ),
    );
  }
}
