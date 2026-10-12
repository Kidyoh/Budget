import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/design.dart';
import '../../core/money.dart';
import '../../core/palette.dart';
import '../../core/widgets/common.dart';
import '../../core/widgets/fields.dart';
import '../../data/sample_data.dart';
import '../../state/providers.dart';
import '../../state/settings.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  Future<void> _pickCurrency(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final code = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.6,
        maxChildSize: 0.9,
        builder: (context, controller) => RadioGroup<String>(
          groupValue: current,
          onChanged: (v) => Navigator.pop(context, v),
          child: ListView(
            controller: controller,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            children: [
              for (final c in supportedCurrencies)
                RadioListTile<String>(
                  value: c.code,
                  title: Text(c.name),
                  secondary: Text(
                    c.symbol.trim(),
                    style: context.text.titleMedium,
                  ),
                  subtitle: Text(c.code),
                ),
            ],
          ),
        ),
      ),
    );
    if (code != null) {
      await ref.read(settingsProvider.notifier).setCurrency(code);
    }
  }

  Future<void> _editName(
    BuildContext context,
    WidgetRef ref,
    String current,
  ) async {
    final controller = TextEditingController(text: current);
    final name = await showFormSheet<String>(
      context,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text('Your name', style: context.text.titleLarge),
          const SizedBox(height: 6),
          Text(
            'Used to greet you on the home screen. Stays on this device.',
            style: context.text.bodyMedium?.copyWith(
              color: context.tokens.muted,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: controller,
            autofocus: true,
            textCapitalization: TextCapitalization.words,
            decoration: const InputDecoration(labelText: 'First name'),
            onSubmitted: (v) => Navigator.pop(context, v),
          ),
          const SizedBox(height: 20),
          Builder(
            builder: (context) => FilledButton(
              onPressed: () => Navigator.pop(context, controller.text),
              child: const Text('Save'),
            ),
          ),
        ],
      ),
    );
    if (name != null) await ref.read(settingsProvider.notifier).setName(name);
  }

  Future<void> _deleteAll(BuildContext context, WidgetRef ref) async {
    final ok = await confirmDialog(
      context,
      title: 'Delete all data?',
      message: 'Every event and everything in it will be permanently deleted. This can’t be undone.',
      confirmLabel: 'Delete everything',
    );
    if (!ok) return;
    await ref.read(databaseProvider).clearAll();
    ref.read(dataRevisionProvider.notifier).bump();
    if (context.mounted) showSnack(context, 'All data deleted');
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final t = context.tokens;

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
        title: const Text('Settings'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(Insets.page, 8, Insets.page, 40),
        children: [
          Panel(
            onTap: () => _editName(context, ref, settings.name),
            child: Row(
              children: [
                settings.name.isEmpty
                    ? Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          color: context.highlight,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.person_rounded,
                          color: inkOnHighlight,
                        ),
                      )
                    : InitialsAvatar(name: settings.name, size: 56),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        settings.name.isEmpty ? 'Add your name' : settings.name,
                        style: context.text.titleMedium,
                      ),
                      Text(
                        'Shown in the home screen greeting',
                        style: context.text.bodySmall?.copyWith(color: t.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.edit_outlined, color: t.muted, size: 20),
              ],
            ),
          ).enter(),
          const SectionHeader('Appearance'),
          Panel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Theme', style: context.text.titleSmall),
                const SizedBox(height: 12),
                PillTabs<ThemeMode>(
                  values: const [
                    ThemeMode.system,
                    ThemeMode.light,
                    ThemeMode.dark,
                  ],
                  labelOf: (m) => switch (m) {
                    ThemeMode.system => 'System',
                    ThemeMode.light => 'Light',
                    ThemeMode.dark => 'Dark',
                  },
                  selected: settings.themeMode,
                  onChanged: controller.setThemeMode,
                ),
                const SizedBox(height: 22),
                Text('Highlight colour', style: context.text.titleSmall),
                const SizedBox(height: 12),
                ColorSwatchPicker(
                  colors: highlightPalette,
                  selected: settings.highlight,
                  onChanged: (c) {
                    if (c != null) controller.setHighlight(c);
                  },
                ),
              ],
            ),
          ).enter(1),
          const SectionHeader('Money'),
          Panel(
            onTap: () => _pickCurrency(context, ref, settings.currencyCode),
            child: Row(
              children: [
                IconBadge(
                  icon: Icons.payments_outlined,
                  color: context.highlight,
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Currency', style: context.text.titleSmall),
                      Text(
                        '${settings.currency.name} (${settings.currency.code})',
                        style: context.text.bodySmall?.copyWith(color: t.muted),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: t.faint),
              ],
            ),
          ).enter(2),
          const SectionHeader('Data'),
          Panel(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.auto_awesome_outlined),
                  title: const Text('Add a sample event'),
                  subtitle: const Text(
                    'A filled-in wedding to explore the app with.',
                  ),
                  onTap: () async {
                    await insertSampleEvent(ref.read(databaseProvider));
                    ref.read(dataRevisionProvider.notifier).bump();
                    if (context.mounted) {
                      showSnack(context, 'Sample event added');
                    }
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.slideshow_outlined),
                  title: const Text('Show the welcome screens'),
                  onTap: () {
                    controller.setOnboarded(false);
                    Navigator.popUntil(context, (r) => r.isFirst);
                  },
                ),
                ListTile(
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: context.colors.error,
                  ),
                  title: Text(
                    'Delete all data',
                    style: TextStyle(color: context.colors.error),
                  ),
                  subtitle: const Text(
                    'Everything is stored only on this device.',
                  ),
                  onTap: () => _deleteAll(context, ref),
                ),
              ],
            ),
          ).enter(3),
          const SizedBox(height: 28),
          Center(
            child: Text(
              'Event Budget · v1.1.0',
              style: context.text.bodySmall?.copyWith(color: t.faint),
            ),
          ),
        ],
      ),
    );
  }
}
