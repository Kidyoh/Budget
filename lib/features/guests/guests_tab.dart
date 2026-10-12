import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/contact_actions.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import 'guest_form.dart';

class GuestsTab extends ConsumerStatefulWidget {
  const GuestsTab({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<GuestsTab> createState() => _GuestsTabState();
}

class _GuestsTabState extends ConsumerState<GuestsTab> {
  RsvpStatus? _filter;
  String _query = '';

  @override
  Widget build(BuildContext context) {
    return AsyncView(
      value: ref.watch(guestsProvider(widget.eventId)),
      data: (guests) {
        if (guests.isEmpty) {
          return EmptyState(
            icon: Icons.people_outline_rounded,
            title: 'No guests yet',
            message: 'Build the guest list, track RSVPs, plus-ones, dietary needs and seating.',
            action: FilledButton.icon(
              onPressed: () =>
                  showGuestForm(context, ref, eventId: widget.eventId),
              icon: const Icon(Icons.person_add_alt_rounded),
              label: const Text('Add a guest'),
            ),
          );
        }
        int count(RsvpStatus s) => guests.where((g) => g.rsvp == s).length;
        final headcount = guests
            .where((g) => g.rsvp == RsvpStatus.attending)
            .fold<int>(0, (s, g) => s + g.partySize);
        final invited = guests.fold<int>(0, (s, g) => s + g.partySize);
        final query = _query.trim().toLowerCase();
        final visible = guests.where((g) {
          if (_filter != null && g.rsvp != _filter) return false;
          if (query.isEmpty) return true;
          return g.name.toLowerCase().contains(query) ||
              g.groupName.toLowerCase().contains(query) ||
              g.tableName.toLowerCase().contains(query);
        }).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          children: [
            Row(
              children: [
                Expanded(
                  child: StatTile(
                    label: 'Invited',
                    value: '$invited',
                    icon: Icons.mail_outline,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Going',
                    value: '$headcount',
                    icon: Icons.groups_rounded,
                    color: StatusColors.success,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: StatTile(
                    label: 'Awaiting',
                    value:
                        '${count(RsvpStatus.pending) + count(RsvpStatus.maybe)}',
                    icon: Icons.hourglass_bottom_rounded,
                    color: StatusColors.warning,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                hintText: 'Search by name, group or table',
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
                    label: Text('All ${guests.length}'),
                    selected: _filter == null,
                    onSelected: (_) => setState(() => _filter = null),
                  ),
                  for (final s in RsvpStatus.values)
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
            if (visible.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 40),
                child: Center(child: Text('No guests match.')),
              )
            else
              Card(
                child: Column(
                  children: [
                    for (var i = 0; i < visible.length; i++) ...[
                      if (i > 0) const Divider(height: 1, indent: 72),
                      _GuestTile(guest: visible[i]),
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

class _GuestTile extends ConsumerWidget {
  const _GuestTile({required this.guest});

  final Guest guest;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final details = [
      if (guest.groupName.isNotEmpty) guest.groupName,
      if (guest.plusOnes > 0) '+${guest.plusOnes}',
      if (guest.tableName.isNotEmpty) 'Table ${guest.tableName}',
      if (guest.dietary.isNotEmpty) guest.dietary,
    ].join(' · ');
    final color = rsvpColor(guest.rsvp);

    return ListTile(
      contentPadding: const EdgeInsets.fromLTRB(14, 4, 4, 4),
      onTap: () =>
          showGuestForm(context, ref, eventId: guest.eventId, guest: guest),
      leading: InitialsAvatar(name: guest.name, size: 46),
      title: Text(guest.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: details.isEmpty
          ? null
          : Text(details, maxLines: 1, overflow: TextOverflow.ellipsis),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tapping the RSVP pill changes it without opening the form.
          PopupMenuButton<RsvpStatus>(
            tooltip: 'Change RSVP',
            initialValue: guest.rsvp,
            onSelected: (s) =>
                ref.read(guestDaoProvider).update(guest.withRsvp(s)),
            itemBuilder: (_) => [
              for (final s in RsvpStatus.values)
                PopupMenuItem(
                  value: s,
                  child: Row(
                    children: [
                      Icon(Icons.circle, size: 12, color: rsvpColor(s)),
                      const SizedBox(width: 10),
                      Text(s.label),
                    ],
                  ),
                ),
            ],
            child: StatusPill(label: guest.rsvp.label, color: color),
          ),
          if (guest.phone.isNotEmpty || guest.email.isNotEmpty)
            PopupMenuButton<Uri>(
              tooltip: 'Contact',
              icon: const Icon(Icons.more_vert_rounded),
              onSelected: (uri) => launchContact(context, uri),
              itemBuilder: (_) => [
                if (guest.phone.isNotEmpty)
                  PopupMenuItem(
                    value: phoneUri(guest.phone),
                    child: const ListTile(
                      leading: Icon(Icons.call_outlined),
                      title: Text('Call'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (guest.phone.isNotEmpty)
                  PopupMenuItem(
                    value: Uri(scheme: 'sms', path: phoneUri(guest.phone).path),
                    child: const ListTile(
                      leading: Icon(Icons.sms_outlined),
                      title: Text('Message'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                if (guest.email.isNotEmpty)
                  PopupMenuItem(
                    value: emailUri(guest.email),
                    child: const ListTile(
                      leading: Icon(Icons.mail_outline),
                      title: Text('Email'),
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
              ],
            )
          else
            const SizedBox(width: 12),
        ],
      ),
    );
  }
}
