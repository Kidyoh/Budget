import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/formatters.dart';
import '../../core/visuals.dart';
import '../../core/widgets/charts.dart';
import '../../core/widgets/common.dart';
import '../../data/daos.dart';
import '../../data/models/models.dart';
import '../../data/sample_data.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';
import '../expenses/expense_detail_screen.dart';
import '../settings/settings_screen.dart';
import 'event_detail_screen.dart';
import 'event_form_screen.dart';

void openEvent(BuildContext context, String id) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => EventDetailScreen(eventId: id)),
  );
}

Future<void> createEvent(BuildContext context) async {
  final id = await Navigator.push<String>(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => const EventFormScreen(),
    ),
  );
  if (id != null && context.mounted) openEvent(context, id);
}

void openSettings(BuildContext context) {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (_) => const SettingsScreen()),
  );
}

String _greeting(DateTime now) {
  final h = now.hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

/// Events that are still ahead (or happening) and not cancelled.
List<EventWithTotals> activeEvents(List<EventWithTotals> all, DateTime now) =>
    all
        .where(
          (e) =>
              !e.event.isPast(now) &&
              e.event.status != EventStatus.cancelled &&
              e.event.status != EventStatus.completed,
        )
        .toList();

class EventsScreen extends ConsumerWidget {
  const EventsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final events = ref.watch(eventsProvider);
    return Scaffold(
      body: AsyncView(
        value: events,
        data: (all) => all.isEmpty ? const _Welcome() : _Home(events: all),
      ),
    );
  }
}

class _Header extends ConsumerWidget {
  const _Header();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final name = ref.watch(settingsProvider.select((s) => s.name));
    final t = context.tokens;
    return Padding(
      padding: const EdgeInsets.fromLTRB(Insets.page, 12, Insets.page, 0),
      child: Row(
        children: [
          Pressable(
            onTap: () => openSettings(context),
            child: name.isEmpty
                ? Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: context.highlight,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.person_rounded,
                      color: inkOnHighlight,
                    ),
                  )
                : InitialsAvatar(name: name, size: 48),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_greeting(DateTime.now())},',
                  style: context.text.bodyMedium?.copyWith(color: t.muted),
                ),
                Text(
                  name.isEmpty ? 'Welcome back 👋' : '$name 👋',
                  style: context.text.titleLarge,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          CircleButton(
            icon: Icons.tune_rounded,
            tooltip: 'Settings',
            onTap: () => openSettings(context),
          ),
        ],
      ),
    );
  }
}

class _Home extends ConsumerWidget {
  const _Home({required this.events});

  final List<EventWithTotals> events;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final active = activeEvents(events, now);
    final shown = active.isNotEmpty ? active : events.reversed.take(5).toList();
    final budget = active.fold<double>(0, (s, e) => s + e.event.totalBudget);
    final committed = active.fold<double>(0, (s, e) => s + e.committed);
    final paid = active.fold<double>(0, (s, e) => s + e.paid);
    final t = context.tokens;

    return CustomScrollView(
      slivers: [
        SliverSafeArea(
          bottom: false,
          sliver: const SliverToBoxAdapter(child: _Header()),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(Insets.page, 28, Insets.page, 0),
          sliver: SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Budget left to spend',
                  style: context.text.bodyMedium?.copyWith(color: t.muted),
                ),
                const SizedBox(height: 4),
                BigAmount(
                  budget - committed,
                  style: context.text.displayMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  active.length == 1
                      ? 'Across 1 active event · ${_paidLine(ref, paid, committed)}'
                      : 'Across ${active.length} active events · ${_paidLine(ref, paid, committed)}',
                  style: context.text.bodySmall?.copyWith(color: t.muted),
                ),
                const SizedBox(height: 18),
                Row(
                  children: [
                    Flexible(
                      child: _ActionPill(
                        icon: Icons.add_rounded,
                        label: 'New event',
                        onTap: () => createEvent(context),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: _ActionPill(
                        icon: Icons.calendar_month_outlined,
                        label: 'All events',
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const AllEventsScreen(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ).enter(),
          ),
        ),
        SliverToBoxAdapter(
          child: SectionHeader(
            'My events',
            padding: const EdgeInsets.fromLTRB(
              Insets.page + 2,
              30,
              Insets.page,
              14,
            ),
            trailing: Pressable(
              onTap: () => createEvent(context),
              child: Row(
                children: [
                  Icon(
                    Icons.add_circle_outline_rounded,
                    size: 18,
                    color: t.muted,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add',
                    style: context.text.labelMedium?.copyWith(color: t.muted),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverToBoxAdapter(
          child: SizedBox(
            height: 206,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: Insets.page),
              itemCount: shown.length,
              separatorBuilder: (_, _) => const SizedBox(width: 14),
              itemBuilder: (context, i) =>
                  EventCard(
                        data: shown[i],
                        now: now,
                        width: shown.length == 1 ? null : 300,
                      )
                      .animate()
                      .fadeIn(delay: (80 * i).ms, duration: 400.ms)
                      .slideX(begin: 0.12, curve: Curves.easeOutCubic),
            ),
          ),
        ),
        const SliverPadding(padding: EdgeInsets.only(top: 26)),
        const SliverFillRemaining(
          hasScrollBody: false,
          child: _PaymentsSheet(),
        ),
      ],
    );
  }

  String _paidLine(WidgetRef ref, double paid, double committed) {
    final money = ref.read(moneyProvider);
    return '${money.compact(paid)} paid of ${money.compact(committed)}';
  }
}

class _ActionPill extends StatelessWidget {
  const _ActionPill({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: Container(
        height: 50,
        padding: const EdgeInsets.only(left: 6, right: 16),
        constraints: const BoxConstraints(minWidth: 0),
        decoration: BoxDecoration(
          color: t.card,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: t.ink, width: 1.4),
              ),
              child: Icon(icon, size: 19, color: t.ink),
            ),
            const SizedBox(width: 9),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.text.labelLarge,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// An event shown like a bank card: its colour as the background, the
/// remaining budget as the balance and a countdown in the corner.
class EventCard extends ConsumerWidget {
  const EventCard({
    super.key,
    required this.data,
    required this.now,
    this.width,
  });

  final EventWithTotals data;
  final DateTime now;
  final double? width;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final event = data.event;
    final bg = Color(event.colorValue);
    final fg = onColor(bg);
    final days = daysBetween(now, event.startDate);
    final past = event.isPast(now);
    final text = context.text;
    final screen = MediaQuery.sizeOf(context).width - Insets.page * 2;

    return Pressable(
      onTap: () => openEvent(context, event.id),
      child: Hero(
        tag: 'event-card-${event.id}',
        flightShuttleBuilder: (_, _, _, _, _) => _CardBackground(color: bg),
        child: SizedBox(
          width: width ?? screen,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(Insets.radius),
            child: Stack(
              children: [
                Positioned.fill(child: _CardBackground(color: bg)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 18, 18, 18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: fg.withValues(alpha: 0.8),
                                width: 1.4,
                              ),
                            ),
                            child: Icon(
                              eventTypeIcon(event.type),
                              color: fg,
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              event.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: text.titleSmall?.copyWith(color: fg),
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(
                        data.remaining >= 0 ? 'Remaining' : 'Over budget',
                        style: text.labelMedium?.copyWith(
                          color: fg.withValues(alpha: 0.7),
                        ),
                      ),
                      BigAmount(
                        data.remaining.abs(),
                        style: text.headlineLarge?.copyWith(fontSize: 30),
                        color: fg,
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_rounded,
                            size: 14,
                            color: fg.withValues(alpha: 0.7),
                          ),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              formatShortDate(event.startDate),
                              style: text.labelMedium?.copyWith(
                                color: fg.withValues(alpha: 0.75),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: fg,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              past
                                  ? 'Done'
                                  : days <= 0
                                  ? 'Today'
                                  : days == 1
                                  ? '1 day'
                                  : '$days days',
                              style: text.labelMedium?.copyWith(color: bg),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The card colour with two soft rings for depth, like a bank card.
class _CardBackground extends StatelessWidget {
  const _CardBackground({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    final ring = onColor(color).withValues(alpha: 0.08);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(Insets.radius),
      ),
      child: CustomPaint(painter: _RingsPainter(ring)),
    );
  }
}

class _RingsPainter extends CustomPainter {
  _RingsPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 26;
    final center = Offset(size.width * 0.95, size.height * 0.15);
    canvas.drawCircle(center, size.height * 0.55, paint);
    canvas.drawCircle(center, size.height * 1.05, paint..strokeWidth = 18);
  }

  @override
  bool shouldRepaint(_RingsPainter old) => old.color != color;
}

/// The white bottom sheet with payments due across events.
class _PaymentsSheet extends ConsumerWidget {
  const _PaymentsSheet();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upcoming =
        ref.watch(upcomingPaymentsProvider).value ?? const <ExpenseWithEvent>[];
    final t = context.tokens;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(
        Insets.page,
        12,
        Insets.page,
        24 + MediaQuery.paddingOf(context).bottom,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: t.border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SectionHeader(
            'Upcoming payments',
            padding: EdgeInsets.fromLTRB(0, 18, 0, 6),
          ),
          if (upcoming.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Row(
                children: [
                  const IconBadge(
                    icon: Icons.check_rounded,
                    color: StatusColors.success,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      'You’re all caught up. Expenses with a due date show up here.',
                      style: context.text.bodyMedium?.copyWith(color: t.muted),
                    ),
                  ),
                ],
              ),
            )
          else
            for (var i = 0; i < upcoming.length; i++) ...[
              if (i > 0) Divider(height: 1, color: t.border),
              _PaymentRow(item: upcoming[i]).enter(i),
            ],
        ],
      ),
    );
  }
}

class _PaymentRow extends ConsumerWidget {
  const _PaymentRow({required this.item});

  final ExpenseWithEvent item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final e = item.expense;
    final now = DateTime.now();
    final overdue = e.statusAt(now) == PaymentStatus.overdue;
    final t = context.tokens;
    return Pressable(
      onTap: () => openExpenseDetail(context, e.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          children: [
            IconBadge(
              icon: Icons.receipt_long_rounded,
              color: Color(item.eventColor),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.title,
                    style: context.text.titleSmall,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${formatShortDate(e.dueDate!)} · ${item.eventName}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: context.text.bodySmall?.copyWith(color: t.muted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '–${money.format(e.outstanding)}',
                  style: context.text.titleSmall,
                ),
                const SizedBox(height: 2),
                Text(
                  relativeDay(e.dueDate!, now: now),
                  style: context.text.labelSmall?.copyWith(
                    color: overdue ? StatusColors.danger : t.muted,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// First-run home: a big highlight card inviting the first event.
class _Welcome extends ConsumerWidget {
  const _Welcome();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const _Header(),
          Padding(
            padding: const EdgeInsets.fromLTRB(
              Insets.page,
              28,
              Insets.page,
              24,
            ),
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
              decoration: BoxDecoration(
                color: context.highlight,
                borderRadius: BorderRadius.circular(32),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 150,
                    child: Stack(
                      children: [
                        const Positioned(
                          right: 0,
                          top: 0,
                          child: DonutChart(
                            size: 140,
                            strokeWidth: 22,
                            slices: [
                              DonutSlice(value: 45, color: inkOnHighlight),
                              DonutSlice(value: 30, color: Colors.white),
                              DonutSlice(value: 25, color: Color(0xFFB8B5FA)),
                            ],
                          ),
                        ),
                        Positioned(
                          left: 0,
                          top: 6,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 9,
                            ),
                            decoration: BoxDecoration(
                              color: inkOnHighlight,
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              'Budget · Guests · Tasks',
                              style: context.text.labelMedium?.copyWith(
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Plan your\nfirst event',
                    style: context.text.displaySmall?.copyWith(
                      color: inkOnHighlight,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Set a budget, split it into categories and track every payment, task and guest.',
                    style: context.text.bodyMedium?.copyWith(
                      color: inkOnHighlight.withValues(alpha: 0.7),
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                        backgroundColor: inkOnHighlight,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () => createEvent(context),
                      icon: const Icon(Icons.add_rounded),
                      label: const Text('Create an event'),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Center(
                    child: TextButton.icon(
                      style: TextButton.styleFrom(
                        foregroundColor: inkOnHighlight,
                      ),
                      onPressed: () async {
                        final id = await insertSampleEvent(
                          ref.read(databaseProvider),
                        );
                        ref.read(dataRevisionProvider.notifier).bump();
                        if (context.mounted) openEvent(context, id);
                      },
                      icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                      label: const Text('Explore a sample event'),
                    ),
                  ),
                ],
              ),
            ).enter(),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

enum _Filter { upcoming, past, all }

/// Every event, filterable by upcoming or past.
class AllEventsScreen extends ConsumerStatefulWidget {
  const AllEventsScreen({super.key});

  @override
  ConsumerState<AllEventsScreen> createState() => _AllEventsScreenState();
}

class _AllEventsScreenState extends ConsumerState<AllEventsScreen> {
  _Filter _filter = _Filter.upcoming;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: Center(
            child: CircleButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => Navigator.maybePop(context),
            ),
          ),
        ),
        leadingWidth: 64,
        title: const Text('All events'),
      ),
      floatingActionButton: FloatingActionButton.large(
        onPressed: () => createEvent(context),
        tooltip: 'New event',
        child: const Icon(Icons.add_rounded),
      ),
      body: AsyncView(
        value: ref.watch(eventsProvider),
        data: (all) {
          final visible = switch (_filter) {
            _Filter.upcoming => all.where((e) => !e.event.isPast(now)).toList(),
            _Filter.past =>
              all.where((e) => e.event.isPast(now)).toList().reversed.toList(),
            _Filter.all => all,
          };
          return ListView(
            padding: const EdgeInsets.fromLTRB(
              Insets.page,
              8,
              Insets.page,
              140,
            ),
            children: [
              PillFilters<_Filter>(
                options: const [
                  (_Filter.upcoming, 'Upcoming'),
                  (_Filter.past, 'Past'),
                  (_Filter.all, 'All'),
                ],
                selected: _filter,
                onChanged: (f) => setState(() => _filter = f ?? _Filter.all),
              ),
              const SizedBox(height: 16),
              if (visible.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 60),
                  child: Text(
                    _filter == _Filter.past
                        ? 'No past events yet.'
                        : 'Nothing coming up.',
                    textAlign: TextAlign.center,
                    style: context.text.bodyMedium?.copyWith(
                      color: context.tokens.muted,
                    ),
                  ),
                )
              else
                for (var i = 0; i < visible.length; i++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _EventRow(data: visible[i], now: now).enter(i),
                  ),
            ],
          );
        },
      ),
    );
  }
}

class _EventRow extends ConsumerWidget {
  const _EventRow({required this.data, required this.now});

  final EventWithTotals data;
  final DateTime now;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final e = data.event;
    final money = ref.watch(moneyProvider);
    final t = context.tokens;
    final color = Color(e.colorValue);
    final fraction = data.usedFraction;
    return Panel(
      onTap: () => openEvent(context, e.id),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            child: Icon(eventTypeIcon(e.type), color: onColor(color)),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  e.name,
                  style: context.text.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 3),
                Text(
                  '${formatDate(e.startDate)} · ${money.compact(e.totalBudget)}',
                  style: context.text.bodySmall?.copyWith(color: t.muted),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                ProgressRing(
                  value: fraction,
                  color: fraction > 1 ? StatusColors.danger : t.ink,
                  size: 48,
                  strokeWidth: 5,
                ),
                Text(
                  e.totalBudget <= 0
                      ? '–'
                      : '${math.min(999, (fraction * 100).round())}%',
                  style: context.text.labelSmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
