import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/common.dart';
import '../../data/models/models.dart';
import '../../data/sample_data.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../settings/settings_screen.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

enum _EventFilter { upcoming, past, all }

class EventsScreen extends ConsumerStatefulWidget {
  const EventsScreen({super.key});

  @override
  ConsumerState<EventsScreen> createState() => _EventsScreenState();
}

class _EventsScreenState extends ConsumerState<EventsScreen> {
  _EventFilter _filter = _EventFilter.upcoming;

  Future<void> _createEvent() async {
    final id = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => const EventFormScreen()),
    );
    if (id != null && mounted) openEvent(context, id);
  }

  Future<void> _loadSample() async {
    final id = await insertSampleEvent(ref.read(databaseProvider));
    ref.read(dataRevisionProvider.notifier).bump();
    if (mounted) openEvent(context, id);
  }

  @override
  Widget build(BuildContext context) {
    final events = ref.watch(eventsProvider);
    final now = DateTime.now();

    return Scaffold(
      // The empty state has its own buttons, which the FAB would cover.
      floatingActionButton: (events.value?.isEmpty ?? true)
          ? null
          : FloatingActionButton.extended(
              onPressed: _createEvent,
              icon: const Icon(Icons.add_rounded),
              label: const Text('New event'),
            ),
      body: AsyncView(
        value: events,
        data: (all) {
          final visible = switch (_filter) {
            _EventFilter.upcoming =>
              all.where((e) => !e.event.isPast(now)).toList(),
            _EventFilter.past =>
              all.where((e) => e.event.isPast(now)).toList().reversed.toList(),
            _EventFilter.all => all,
          };
          return CustomScrollView(
            slivers: [
              SliverAppBar.large(
                title: const Text('Your events'),
                actions: [
                  IconButton(
                    tooltip: 'Settings',
                    icon: const Icon(Icons.settings_outlined),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    ),
                  ),
                ],
              ),
              if (all.isEmpty)
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: EmptyState(
                    icon: Icons.celebration_rounded,
                    title: 'Plan your first event',
                    message: 'Set a budget, split it into categories, and track every expense, task, guest and vendor in one place.',
                    action: Column(
                      children: [
                        FilledButton.icon(
                          onPressed: _createEvent,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Create an event'),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: _loadSample,
                          icon: const Icon(Icons.auto_awesome_rounded),
                          label: const Text('Explore a sample event'),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  sliver: SliverToBoxAdapter(
                    child: _PortfolioCard(events: all, now: now),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                  sliver: SliverToBoxAdapter(
                    child: SegmentedButton<_EventFilter>(
                      showSelectedIcon: false,
                      segments: const [
                        ButtonSegment(
                          value: _EventFilter.upcoming,
                          label: Text('Upcoming'),
                        ),
                        ButtonSegment(
                          value: _EventFilter.past,
                          label: Text('Past'),
                        ),
                        ButtonSegment(
                          value: _EventFilter.all,
                          label: Text('All'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (s) =>
                          setState(() => _filter = s.first),
                    ),
                  ),
                ),
                if (visible.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: _filter == _EventFilter.past
                          ? 'No past events'
                          : 'Nothing coming up',
                      message: _filter == _EventFilter.past
                          ? 'Events move here once their last day has passed.'
                          : 'Create an event to start planning.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 104),
                    sliver: SliverList.separated(
                      itemCount: visible.length,
                      separatorBuilder: (_, _) => const SizedBox(height: 12),
                      itemBuilder: (context, i) =>
                          EventCard(data: visible[i], now: now),
                    ),
                  ),
              ],
            ],
          );
        },
      ),
    );
  }
}

void openEvent(BuildContext context, String id) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: id)),
  );
}

/// Totals across the events that are still being planned.
class _PortfolioCard extends ConsumerWidget {
  const _PortfolioCard({required this.events, required this.now});

  final List<EventWithTotals> events;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;

    final active = events
        .where(
          (e) =>
              !e.event.isPast(now) &&
              e.event.status != EventStatus.cancelled &&
              e.event.status != EventStatus.completed,
        )
        .toList();
    final budget = active.fold<double>(0, (s, e) => s + e.event.totalBudget);
    final committed = active.fold<double>(0, (s, e) => s + e.committed);
    final paid = active.fold<double>(0, (s, e) => s + e.paid);
    final fraction = budget <= 0 ? 0.0 : committed / budget;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            scheme.primary,
            Color.lerp(scheme.primary, scheme.tertiary, 0.6)!,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            active.length == 1
                ? '1 active event'
                : '${active.length} active events',
            style: text.labelLarge?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            money.short(budget - committed),
            style: text.displaySmall?.copyWith(color: scheme.onPrimary),
          ),
          Text(
            'left of ${money.short(budget)} total budget',
            style: text.bodyMedium?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: fraction.clamp(0.0, 1.0),
              minHeight: 8,
              color: fraction > 1 ? const Color(0xFFFFB4AB) : scheme.onPrimary,
              backgroundColor: scheme.onPrimary.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _PortfolioFigure(
                label: 'Committed',
                value: money.compact(committed),
              ),
              _PortfolioFigure(label: 'Paid', value: money.compact(paid)),
              _PortfolioFigure(
                label: 'Still to pay',
                value: money.compact(committed - paid),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PortfolioFigure extends StatelessWidget {
  const _PortfolioFigure({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: text.labelSmall?.copyWith(
              color: scheme.onPrimary.withValues(alpha: 0.8),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: text.titleSmall?.copyWith(color: scheme.onPrimary),
          ),
        ],
      ),
    );
  }
}

class EventCard extends ConsumerWidget {
  const EventCard({super.key, required this.data, required this.now});

  final EventWithTotals data;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = data.event;
    final money = ref.watch(moneyProvider);
    final scheme = Theme.of(context).colorScheme;
    final text = Theme.of(context).textTheme;
    final color = Color(event.colorValue);
    final days = daysBetween(now, event.startDate);
    final isPast = event.isPast(now);

    return Card(
      child: InkWell(
        onTap: () => openEvent(context, event.id),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [color, Color.lerp(color, Colors.black, 0.25)!],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: Colors.white.withValues(alpha: 0.2),
                    child: Icon(
                      eventTypeIcon(event.type),
                      color: Colors.white,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          event.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: text.titleMedium?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${event.type.label} · ${event.status.label}',
                          style: text.labelMedium?.copyWith(
                            color: Colors.white70,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isPast && days >= 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          Text(
                            days == 0 ? 'Today' : '$days',
                            style: text.titleMedium?.copyWith(
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          if (days > 0)
                            Text(
                              days == 1 ? 'day' : 'days',
                              style: text.labelSmall?.copyWith(
                                color: Colors.white70,
                              ),
                            ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _IconLine(
                    icon: Icons.calendar_today_rounded,
                    text: formatDateRange(event.startDate, event.endDate),
                  ),
                  if (event.location.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    _IconLine(icon: Icons.place_outlined, text: event.location),
                  ],
                  const SizedBox(height: 14),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Expanded(
                        child: Text.rich(
                          TextSpan(
                            children: [
                              TextSpan(
                                text: money.short(data.committed),
                                style: text.titleMedium,
                              ),
                              TextSpan(
                                text: '  of ${money.short(event.totalBudget)}',
                                style: text.bodySmall?.copyWith(
                                  color: scheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      Text(
                        data.remaining >= 0
                            ? '${money.compact(data.remaining)} left'
                            : '${money.compact(-data.remaining)} over',
                        style: text.labelMedium?.copyWith(
                          color: data.remaining >= 0
                              ? scheme.onSurfaceVariant
                              : StatusColors.danger,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  ProgressBar(
                    value: data.usedFraction,
                    color: usageColor(data.usedFraction, scheme),
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

class _IconLine extends StatelessWidget {
  const _IconLine({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium
                ?.copyWith(color: scheme.onSurfaceVariant),
          ),
        ),
      ],
    );
  }
}
