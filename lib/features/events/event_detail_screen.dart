import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../core/design.dart';
import '../../core/widgets/common.dart';
import '../../data/csv_export.dart';
import '../../data/models/models.dart';
import '../../state/providers.dart';
import '../budget/budget_tab.dart';
import '../budget/category_form.dart';
import '../expenses/expense_form_screen.dart';
import '../expenses/expenses_tab.dart';
import '../guests/guest_form.dart';
import '../guests/guests_tab.dart';
import '../notes/note_editor_screen.dart';
import '../notes/notes_tab.dart';
import '../overview/overview_tab.dart';
import '../tasks/task_form.dart';
import '../tasks/tasks_tab.dart';
import '../vendors/vendor_form.dart';
import '../vendors/vendors_tab.dart';
import 'event_form_screen.dart';

enum EventSection {
  overview(
    'Overview',
    Icons.space_dashboard_outlined,
    Icons.space_dashboard_rounded,
  ),
  money(
    'Money',
    Icons.account_balance_wallet_outlined,
    Icons.account_balance_wallet_rounded,
  ),
  tasks(
    'Tasks',
    Icons.check_circle_outline_rounded,
    Icons.check_circle_rounded,
  ),
  people('People', Icons.people_outline_rounded, Icons.people_rounded),
  notes('Notes', Icons.sticky_note_2_outlined, Icons.sticky_note_2_rounded);

  const EventSection(this.label, this.icon, this.selectedIcon);
  final String label;
  final IconData icon;
  final IconData selectedIcon;
}

enum MoneyView { budget, expenses }

enum PeopleView { guests, vendors }

/// Lets pages inside the event screen switch section, e.g. the overview's
/// "See all" links.
typedef OpenSection = void Function(
  EventSection section, {
  MoneyView? money,
  PeopleView? people,
});

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _EventDetailScreenState extends ConsumerState<EventDetailScreen> {
  EventSection _section = EventSection.overview;
  MoneyView _money = MoneyView.budget;
  PeopleView _people = PeopleView.guests;

  String get _eventId => widget.eventId;

  void _open(EventSection section, {MoneyView? money, PeopleView? people}) {
    HapticFeedback.selectionClick();
    setState(() {
      _section = section;
      _money = money ?? _money;
      _people = people ?? _people;
    });
  }

  (String, IconData) get _addAction => switch (_section) {
    EventSection.overview => ('Add expense', Icons.add_rounded),
    EventSection.money =>
      _money == MoneyView.budget
          ? ('Add category', Icons.add_rounded)
          : ('Add expense', Icons.add_rounded),
    EventSection.tasks => ('Add task', Icons.add_task_rounded),
    EventSection.people =>
      _people == PeopleView.guests
          ? ('Add guest', Icons.person_add_alt_1_rounded)
          : ('Add vendor', Icons.add_business_rounded),
    EventSection.notes => ('New note', Icons.edit_rounded),
  };

  void _onAdd() {
    HapticFeedback.lightImpact();
    switch (_section) {
      case EventSection.overview:
        openExpenseForm(context, eventId: _eventId);
      case EventSection.money:
        if (_money == MoneyView.budget) {
          showCategoryForm(context, ref, eventId: _eventId);
        } else {
          openExpenseForm(context, eventId: _eventId);
        }
      case EventSection.tasks:
        showTaskForm(context, ref, eventId: _eventId);
      case EventSection.people:
        if (_people == PeopleView.guests) {
          showGuestForm(context, ref, eventId: _eventId);
        } else {
          showVendorForm(context, ref, eventId: _eventId);
        }
      case EventSection.notes:
        openNoteEditor(context, eventId: _eventId);
    }
  }

  Future<void> _edit(Event event) => Navigator.push(
    context,
    MaterialPageRoute(
      fullscreenDialog: true,
      builder: (_) => EventFormScreen(event: event),
    ),
  );

  Future<void> _delete(Event event) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete event?',
      message:
          '"${event.name}" and all of its categories, expenses, payments, tasks, notes, guests and vendors will be permanently deleted.',
    );
    if (!ok || !mounted) return;
    await ref.read(eventDaoProvider).delete(event.id);
    if (mounted) Navigator.pop(context);
  }

  Future<void> _export(Event event) async {
    final box = context.findRenderObject() as RenderBox?;
    final csv = expensesCsv(
      expenses: await ref.read(expensesProvider(_eventId).future),
      categories: await ref.read(categoriesProvider(_eventId).future),
      vendors: await ref.read(vendorsProvider(_eventId).future),
      now: DateTime.now(),
    );
    final safeName = event.name
        .replaceAll(RegExp(r'[^\w\- ]'), '')
        .trim()
        .replaceAll(' ', '_');
    final dir = await getTemporaryDirectory();
    final file = File(
      p.join(dir.path, '${safeName.isEmpty ? 'event' : safeName}_expenses.csv'),
    );
    await file.writeAsString(csv);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: 'text/csv')],
        subject: '${event.name} – expenses',
        sharePositionOrigin: box == null
            ? null
            : box.localToGlobal(Offset.zero) & box.size,
      ),
    );
  }

  Future<void> _more(Event event) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _SheetAction(
                icon: Icons.edit_outlined,
                label: 'Edit event',
                value: 'edit',
              ),
              _SheetAction(
                icon: Icons.ios_share_rounded,
                label: 'Export expenses (CSV)',
                value: 'export',
              ),
              _SheetAction(
                icon: Icons.delete_outline_rounded,
                label: 'Delete event',
                value: 'delete',
                destructive: true,
              ),
            ],
          ),
        ),
      ),
    );
    switch (action) {
      case 'edit':
        await _edit(event);
      case 'export':
        await _export(event);
      case 'delete':
        await _delete(event);
    }
  }

  Widget _page() => switch (_section) {
    EventSection.overview => OverviewTab(eventId: _eventId, onOpen: _open),
    EventSection.money => _SubSections<MoneyView>(
      values: MoneyView.values,
      labelOf: (v) => v == MoneyView.budget ? 'Budget' : 'Expenses',
      selected: _money,
      onChanged: (v) => setState(() => _money = v),
      builder: (v) => v == MoneyView.budget
          ? BudgetTab(eventId: _eventId)
          : ExpensesTab(eventId: _eventId),
    ),
    EventSection.tasks => TasksTab(eventId: _eventId),
    EventSection.people => _SubSections<PeopleView>(
      values: PeopleView.values,
      labelOf: (v) => v == PeopleView.guests ? 'Guests' : 'Vendors',
      selected: _people,
      onChanged: (v) => setState(() => _people = v),
      builder: (v) => v == PeopleView.guests
          ? GuestsTab(eventId: _eventId)
          : VendorsTab(eventId: _eventId),
    ),
    EventSection.notes => NotesTab(eventId: _eventId),
  };

  @override
  Widget build(BuildContext context) {
    final eventValue = ref.watch(eventProvider(_eventId));
    final event = eventValue.value;
    final overview = ref.watch(overviewProvider(_eventId)).value;

    return Scaffold(
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
              child: Row(
                children: [
                  CircleButton(
                    icon: Icons.arrow_back_rounded,
                    tooltip: 'Back',
                    onTap: () => Navigator.maybePop(context),
                  ),
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        _section.label,
                        key: ValueKey(_section),
                        textAlign: TextAlign.center,
                        style: context.text.titleMedium,
                      ),
                    ),
                  ),
                  CircleButton(
                    icon: Icons.more_horiz_rounded,
                    tooltip: 'More',
                    onTap: event == null ? null : () => _more(event),
                  ),
                ],
              ),
            ),
            Expanded(
              child: eventValue.isLoading && event == null
                  ? const Center(child: CircularProgressIndicator())
                  : event == null
                  ? const EmptyState(
                      icon: Icons.event_busy_rounded,
                      title: 'Event not found',
                      message: 'It may have been deleted.',
                    )
                  : AnimatedSwitcher(
                      duration: const Duration(milliseconds: 260),
                      switchInCurve: Curves.easeOutCubic,
                      switchOutCurve: Curves.easeInCubic,
                      transitionBuilder: (child, animation) => FadeTransition(
                        opacity: animation,
                        child: ScaleTransition(
                          scale: Tween(
                            begin: 0.985,
                            end: 1.0,
                          ).animate(animation),
                          child: child,
                        ),
                      ),
                      child: KeyedSubtree(
                        key: ValueKey(_section),
                        child: _page(),
                      ),
                    ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: event == null
          ? null
          : _FloatingNav(
              selected: _section,
              onSelect: _open,
              addLabel: _addAction.$1,
              addIcon: _addAction.$2,
              onAdd: _onAdd,
              badges: {
                if ((overview?.overdueExpenses.length ?? 0) > 0)
                  EventSection.money,
                if ((overview?.overdueTasks.length ?? 0) > 0)
                  EventSection.tasks,
              },
            ),
    );
  }
}

class _SheetAction extends StatelessWidget {
  const _SheetAction({
    required this.icon,
    required this.label,
    required this.value,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive ? context.colors.error : context.tokens.ink;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Panel(
        onTap: () => Navigator.pop(context, value),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        radius: Insets.smallRadius,
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: 14),
            Text(label, style: context.text.titleSmall?.copyWith(color: color)),
          ],
        ),
      ),
    );
  }
}

/// Pill tabs above one of two sub-pages (Budget/Expenses, Guests/Vendors).
class _SubSections<T> extends StatelessWidget {
  const _SubSections({
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
    required this.builder,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;
  final Widget Function(T) builder;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(Insets.page, 4, Insets.page, 4),
          child: PillTabs<T>(
            values: values,
            labelOf: labelOf,
            selected: selected,
            onChanged: onChanged,
          ),
        ),
        Expanded(
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 220),
            child: KeyedSubtree(
              key: ValueKey(selected),
              child: builder(selected),
            ),
          ),
        ),
      ],
    );
  }
}

/// A dark floating pill of section icons with a highlight "+" button.
class _FloatingNav extends StatelessWidget {
  const _FloatingNav({
    required this.selected,
    required this.onSelect,
    required this.addLabel,
    required this.addIcon,
    required this.onAdd,
    required this.badges,
  });

  final EventSection selected;
  final OpenSection onSelect;
  final String addLabel;
  final IconData addIcon;
  final VoidCallback onAdd;
  final Set<EventSection> badges;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final bottom = MediaQuery.paddingOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(Insets.page, 0, Insets.page, 14 + bottom),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 66,
              padding: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: t.navBar,
                borderRadius: BorderRadius.circular(999),
                boxShadow: t.raised,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  for (final s in EventSection.values)
                    _NavItem(
                      section: s,
                      selected: s == selected,
                      badge: badges.contains(s),
                      onTap: () => onSelect(s),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          Semantics(
            button: true,
            label: addLabel,
            child: Tooltip(
              message: addLabel,
              child: Pressable(
                onTap: onAdd,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    color: context.highlight,
                    shape: BoxShape.circle,
                    boxShadow: t.raised,
                  ),
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 200),
                    transitionBuilder: (child, a) => RotationTransition(
                      turns: Tween(begin: 0.75, end: 1.0).animate(a),
                      child: FadeTransition(opacity: a, child: child),
                    ),
                    child: Icon(
                      addIcon,
                      key: ValueKey(addIcon),
                      color: inkOnHighlight,
                      size: 28,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.section,
    required this.selected,
    required this.badge,
    required this.onTap,
  });

  final EventSection section;
  final bool selected;
  final bool badge;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: section.label,
      child: Tooltip(
        message: section.label,
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: onTap,
          child: SizedBox(
            width: 46,
            height: 60,
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 260),
                    curve: Curves.easeOutBack,
                    width: selected ? 46 : 40,
                    height: selected ? 46 : 40,
                    decoration: BoxDecoration(
                      color: selected ? context.highlight : Colors.transparent,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      selected ? section.selectedIcon : section.icon,
                      size: 23,
                      color: selected
                          ? inkOnHighlight
                          : Colors.white.withValues(alpha: 0.6),
                    ),
                  ),
                  if (badge)
                    Positioned(
                      right: 2,
                      top: 2,
                      child: Container(
                        width: 9,
                        height: 9,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFF8E7F),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.tokens.navBar,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
