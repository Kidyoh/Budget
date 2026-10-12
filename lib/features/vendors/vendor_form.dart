import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/id.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';

Future<void> showVendorForm(
  BuildContext context,
  WidgetRef ref, {
  required String eventId,
  Vendor? vendor,
}) {
  return showFormSheet(
    context,
    child: _VendorForm(eventId: eventId, vendor: vendor),
  );
}

class _VendorForm extends ConsumerStatefulWidget {
  const _VendorForm({required this.eventId, this.vendor});

  final String eventId;
  final Vendor? vendor;

  @override
  ConsumerState<_VendorForm> createState() => _VendorFormState();
}

class _VendorFormState extends ConsumerState<_VendorForm> {
  final _formKey = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.vendor?.name);
  late final _service = TextEditingController(text: widget.vendor?.service);
  late final _contact = TextEditingController(text: widget.vendor?.contactName);
  late final _phone = TextEditingController(text: widget.vendor?.phone);
  late final _email = TextEditingController(text: widget.vendor?.email);
  late final _website = TextEditingController(text: widget.vendor?.website);
  late final _quote = TextEditingController(
    text: amountText(widget.vendor?.quote),
  );
  late final _notes = TextEditingController(text: widget.vendor?.notes);
  late VendorStatus _status = widget.vendor?.status ?? VendorStatus.researching;
  late int _rating = widget.vendor?.rating ?? 0;

  @override
  void dispose() {
    for (final c in [
      _name,
      _service,
      _contact,
      _phone,
      _email,
      _website,
      _quote,
      _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final existing = widget.vendor;
    final vendor = Vendor(
      id: existing?.id ?? newId(),
      eventId: widget.eventId,
      name: _name.text.trim(),
      service: _service.text.trim(),
      contactName: _contact.text.trim(),
      phone: _phone.text.trim(),
      email: _email.text.trim(),
      website: _website.text.trim(),
      quote: parseAmount(_quote.text),
      status: _status,
      rating: _rating,
      notes: _notes.text.trim(),
      createdAt: existing?.createdAt ?? DateTime.now(),
    );
    final dao = ref.read(vendorDaoProvider);
    if (existing == null) {
      await dao.insert(vendor);
    } else {
      await dao.update(vendor);
    }
    if (mounted) Navigator.pop(context);
  }

  Future<void> _delete() async {
    final vendor = widget.vendor!;
    final ok = await confirmDialog(
      context,
      title: 'Delete vendor?',
      message:
          '${vendor.name} will be deleted. Expenses linked to it are kept.',
    );
    if (!ok) return;
    await ref.read(vendorDaoProvider).delete(vendor.id);
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final money = ref.watch(moneyProvider);
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
                  widget.vendor == null ? 'Add vendor' : 'Edit vendor',
                  style: text.titleLarge,
                ),
              ),
              if (widget.vendor != null)
                IconButton(
                  tooltip: 'Delete vendor',
                  onPressed: _delete,
                  icon: const Icon(Icons.delete_outline_rounded),
                ),
            ],
          ),
          const SizedBox(height: 16),
          TextFormField(
            controller: _name,
            autofocus: widget.vendor == null,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'Business name'),
            validator: (v) =>
                (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _service,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Service',
              hintText: 'Catering, Photography, DJ…',
            ),
          ),
          const SizedBox(height: 16),
          Text('Status', style: text.titleSmall),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final s in VendorStatus.values)
                ChoiceChip(
                  label: Text(s.label),
                  selected: _status == s,
                  selectedColor: vendorStatusColor(s).withValues(alpha: 0.2),
                  onSelected: (_) => setState(() => _status = s),
                ),
            ],
          ),
          const SizedBox(height: 12),
          AmountField(
            controller: _quote,
            label: 'Quote',
            prefix: money.currency.symbol,
            required: false,
            allowZero: true,
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: Text('Rating', style: text.titleSmall)),
              for (var i = 1; i <= 5; i++)
                IconButton(
                  tooltip: '$i star${i == 1 ? '' : 's'}',
                  visualDensity: VisualDensity.compact,
                  onPressed: () =>
                      setState(() => _rating = _rating == i ? 0 : i),
                  icon: Icon(
                    i <= _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: i <= _rating ? const Color(0xFFF9A825) : null,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _contact,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(
              labelText: 'Contact person',
              prefixIcon: Icon(Icons.person_outline),
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
          TextFormField(
            controller: _website,
            keyboardType: TextInputType.url,
            decoration: const InputDecoration(
              labelText: 'Website',
              prefixIcon: Icon(Icons.language),
            ),
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: _notes,
            minLines: 2,
            maxLines: 4,
            textCapitalization: TextCapitalization.sentences,
            decoration: const InputDecoration(
              labelText: 'Notes',
              alignLabelWithHint: true,
            ),
          ),
          const SizedBox(height: 20),
          FilledButton(onPressed: _save, child: const Text('Save vendor')),
        ],
      ),
    );
  }
}
