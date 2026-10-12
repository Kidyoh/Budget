import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

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

class EventDetailScreen extends ConsumerStatefulWidget {
  const EventDetailScreen({super.key, required this.eventId});

  final String eventId;

  @override
  ConsumerState<EventDetailScreen> createState() => _EventDetailScreenState();
}

class _Tab {
  const _Tab(this.label, this.icon, this.fabLabel, this.fabIcon);

  final String label;
  final IconData icon;
  final String fabLabel;
  final IconData fabIcon;
}

const _tabs = [
  _Tab('Overview', Icons.dashboard_outlined, 'Expense', Icons.add_rounded),
  _Tab(
    'Budget',
    Icons.pie_chart_outline_rounded,
    'Category',
    Icons.add_rounded,
  ),
  _Tab('Expenses', Icons.receipt_long_outlined, 'Expense', Icons.add_rounded),
  _Tab('Tasks', Icons.checklist_rounded, 'Task', Icons.add_task_rounded),
  _Tab('Notes', Icons.sticky_note_2_outlined, 'Note', Icons.edit_note_rounded),
  _Tab(
    'Guests',
    Icons.people_outline_rounded,
    'Guest',
    Icons.person_add_alt_rounded,
  ),
  _Tab(
    'Vendors',
    Icons.storefront_outlined,
    'Vendor',
    Icons.add_business_outlined,
  ),
];

class _EventDetailScreenState extends ConsumerState<EventDetailScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _controller =
      TabController(length: _tabs.length, vsync: this)..addListener(() {
        if (!_controller.indexIsChanging) setState(() {});
      });

  String get _eventId => widget.eventId;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onFab() {
    switch (_controller.index) {
      case 0 || 2:
        openExpenseForm(context, eventId: _eventId);
      case 1:
        showCategoryForm(context, ref, eventId: _eventId);
      case 3:
        showTaskForm(context, ref, eventId: _eventId);
      case 4:
        openNoteEditor(context, eventId: _eventId);
      case 5:
        showGuestForm(context, ref, eventId: _eventId);
      case 6:
        showVendorForm(context, ref, eventId: _eventId);
    }
  }

  Future<void> _edit(Event event) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => EventFormScreen(event: event)),
    );
  }

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

  @override
  Widget build(BuildContext context) {
    final eventValue = ref.watch(eventProvider(_eventId));
    final event = eventValue.value;
    final tab = _tabs[_controller.index];

    return Scaffold(
      appBar: AppBar(
        title: Text(event?.name ?? ''),
        actions: [
          if (event != null) ...[
            IconButton(
              tooltip: 'Edit event',
              icon: const Icon(Icons.edit_outlined),
              onPressed: () => _edit(event),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => switch (value) {
                'export' => _export(event),
                'delete' => _delete(event),
                _ => null,
              },
              itemBuilder: (_) => const [
                PopupMenuItem(
                  value: 'export',
                  child: ListTile(
                    leading: Icon(Icons.ios_share_rounded),
                    title: Text('Export expenses (CSV)'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: ListTile(
                    leading: Icon(Icons.delete_outline_rounded),
                    title: Text('Delete event'),
                    contentPadding: EdgeInsets.zero,
                  ),
                ),
              ],
            ),
          ],
        ],
        bottom: TabBar(
          controller: _controller,
          isScrollable: true,
          tabs: [
            for (final t in _tabs)
              Tab(icon: Icon(t.icon, size: 20), text: t.label, height: 60),
          ],
        ),
      ),
      floatingActionButton: event == null
          ? null
          : FloatingActionButton.extended(
              onPressed: _onFab,
              icon: Icon(tab.fabIcon),
              label: Text(tab.fabLabel),
            ),
      body: eventValue.isLoading && event == null
          ? const Center(child: CircularProgressIndicator())
          : event == null
          ? const EmptyState(
              icon: Icons.event_busy_rounded,
              title: 'Event not found',
              message: 'It may have been deleted.',
            )
          : TabBarView(
              controller: _controller,
              children: [
                OverviewTab(
                  eventId: _eventId,
                  onOpenTab: (i) => _controller.animateTo(i),
                ),
                BudgetTab(eventId: _eventId),
                ExpensesTab(eventId: _eventId),
                TasksTab(eventId: _eventId),
                NotesTab(eventId: _eventId),
                GuestsTab(eventId: _eventId),
                VendorsTab(eventId: _eventId),
              ],
            ),
    );
  }
}

/// Tab indices, for links from the overview.
abstract final class EventTabs {
  static const budget = 1;
  static const expenses = 2;
  static const tasks = 3;
  static const guests = 5;
  static const vendors = 6;
}
