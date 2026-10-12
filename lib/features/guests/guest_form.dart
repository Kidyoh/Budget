import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';

Future<void> showGuestForm(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  Guest? guest,
}) {
  return showFormSheet(
    context,
    child: _GuestForm(eventId: eventId, guest: guest),
  );
}

class _GuestForm extends ConsumerStatefulWidget {
  const _GuestForm({required this.eventId, this.guest});

  final String eventId;
  final Guest? guest;

  @override
  ConsumerState<_GuestForm> createState() => _GuestFormState();
}

class _GuestFormState extends ConsumerState<_GuestForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.guest?.name);
  late final _email = TextEditingController(text: widget.guest?.email);
  late final _phone = TextEditingController(text: widget.guest?.phone);
  late final _group = TextEditingController(text: widget.guest?.groupName);
  late final _dietary = TextEditingController(text: widget.guest?.dietary);
  late final _table = TextEditingController(text: widget.guest?.tableName);
  late final _notes = TextEditingController(text: widget.guest?.notes);
  late RsvpStatus _rsvp = widget.guest?.rsvp ?? RsvpStatus.pending;
  late int _plusOnes = widget.guest?.plusOnes ?? 0;

  @override
  void dispose() {
    for (final c in [_name, _email, _phone, _group, _dietary, _table, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.guest;
    final guest = Guest(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      name: _name.text.trim(),
      email: _email.text.trim(),
      phone: _phone.text.trim(),
      groupName: _group.text.trim(),
      rsvp: _rsvp,
      plusOnes: _plusOnes,
      dietary: _dietary.text.trim(),
      tableName: _table.text.trim(),
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final dao = ref.read(guestDaoProvider);
    if (existing == null) {
      await dao.insert(guest);
    } else {
      await dao.update(guest);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final guest = widget.guest!;
    final ok = await confirmDialog(
      context,
      title: 'Remove guest?',
      message: '${guest.name} will be removed from the guest list.',
      confirmLabel: 'Remove',
    );
    if (!ok) return;
    await ref.read(guestDaoProvider).delete(guest.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  widget.guest == null ? 'Add guest' : 'Edit guest',
                  style: text.titleLarge,
                ),
              ),
              if (widget.guest != null)
                IconButton(
                  tooltip: 'Remove guest',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            autofocus: widget.guest == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 16),
          Text('RSVP', style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in RsvpStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _rsvp == s,
                  selectedColor: rsvpColor(s).withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _rsvp = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Plus-ones', style: text.titleSmall)),
              IconButton.outlined(
                tooltip: 'Fewer',
                onPressed: _plusOnes == 0
                    ? null
                    : () => setState(() => _plusOnes--),
                icon: const Icon(Icons.remove_rounded),
              ),
              SizedBox(
                width: 40,
                child: Text(
                  '$_plusOnes',
                  textAlign: TextAlign.center,
                  style: text.titleMedium,
                ),
              ),
              IconButton.outlined(
                tooltip: 'More',
                onPressed: _plusOnes >= 20
                    ? null
                    : () => setState(() => _plusOnes++),
                icon: const Icon(Icons.add_rounded),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _group,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Group',
              hintText: 'Family, Friends, Work…',
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _phone,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[\d+\-() ]')),
            ],
            decoration: const InputDecoration(
              labelText: 'Phone',
              prefixIcon: Icon(Icons.phone_outlined),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(
              labelText: 'Email',
              prefixIcon: Icon(Icons.mail_outline),
            ),
            validator: (v) {
              final value = v?.trim() ?? '';
              if (value.isEmpty) return null;
              return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)
                  ? null
                  : 'Check the email';
            },
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _table,
                  decoration: const InputDecoration(labelText: 'Table'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _dietary,
                  textCapitalization: TextCapitalization.sentences,
                  decoration: const InputDecoration(labelText: 'Dietary needs'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            minLines: 1,
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(labelText: 'Notes'),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save guest')),
        ],
      ),
    );
  }
}
