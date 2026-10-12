import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contact_actions.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import 'vendor_form.dart';

class VendorsTab extends ConsumerStatefulWidget {
  const VendorsTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<VendorsTab> createState() => _VendorsTabState();
}

class _VendorsTabState extends ConsumerState<VendorsTab> {
  VendorStatus? _filter;

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(vendorsProvider(widget.eventId)),
      data: (vendors) {
        if (vendors.isEmpty) {
          return EmptyState(
            icon: Icons.storefront_outlined,
            title: 'No vendors yet',
            message: 'Keep every supplier’s contacts, quotes and booking status together.',
            action: FilledButton.icon(
              onPressed: () =>
                  showVendorForm(context, ref, eventId: widget.eventId),
              icon: const Icon(Icons.add_business_outlined),
              label: const Text('Add a vendor'),
            ),
          );
        }
        int count(VendorStatus s) =>
            vendors.where((v) => v.vendor.status == s).length;
        final visible = _filter == null
            ? vendors
            : vendors.where((v) => v.vendor.status == _filter).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  ChoiceChip(
                    label: Text('All ${vendors.length}'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final s in VendorStatus.values)
                    if (count(s) > 0)
                      Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: ChoiceChip(
                          label: Text('${s.label} ${count(s)}'),
                          selected: _filter == s,
                          onSelected: (sel) =>
                              setState(() => _filter = sel ? s : null),
                        ),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final v in visible) ...[
              _VendorCard(data: v),
              const SizedBox(height: 10),
            ],
          ],
        );
      },
    );
  }
}

class _VendorCard extends ConsumerWidget {
  const _VendorCard({required this.data});

  final VendorWithSpend data;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final v = data.vendor;
    final statusColor = vendorStatusColor(v.status);

    return Card(
      child: InkWell(
        onTap: () =>
            showVendorForm(context, ref, eventId: v.eventId, vendor: v),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  InitialsAvatar(name: v.name, size: 46),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          v.name,
                          style: text.titleSmall,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          [
                            if (v.service.isNotEmpty) v.service,
                            if (v.contactName.isNotEmpty) v.contactName,
                          ].join(' · '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.bodySmall?.copyWith(
                            color: scheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  StatusPill(label: v.status.label, color: statusColor),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (v.quote != null)
                    _Figure(label: 'Quote', value: money.short(v.quote!)),
                  _Figure(
                    label: 'Committed',
                    value: money.short(data.committed),
                  ),
                  if (v.rating > 0)
                    Expanded(
                      child: Row(
                        children: [
                          for (var i = 1; i <= 5; i++)
                            Icon(
                              i <= v.rating
                                  ? Icons.star_rounded
                                  : Icons.star_outline_rounded,
                              size: 16,
                              color: const Color(0xFFF9A825),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
              if (v.phone.isNotEmpty ||
                  v.email.isNotEmpty ||
                  v.website.isNotEmpty) ...[
                const SizedBox(height: 12),
                Row(
                  children: [
                    if (v.phone.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleButton(
                          tooltip: 'Call',
                          size: 40,
                          icon: Icons.call_outlined,
                          onTap: () =>
                              launchContact(context, phoneUri(v.phone)),
                        ),
                      ),
                    if (v.email.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleButton(
                          tooltip: 'Email',
                          size: 40,
                          icon: Icons.mail_outline,
                          onTap: () =>
                              launchContact(context, emailUri(v.email)),
                        ),
                      ),
                    if (v.website.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CircleButton(
                          tooltip: 'Website',
                          size: 40,
                          icon: Icons.language,
                          onTap: () =>
                              launchContact(context, webUri(v.website)),
                        ),
                      ),
                  ],
                ),
              ] else
                const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}

class _Figure extends StatelessWidget {
  const _Figure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          Text(value, style: text.titleSmall),
        ],
      ),
    );
  }
}
