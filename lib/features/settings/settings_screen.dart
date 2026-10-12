import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
            children: [
              for (final c in supportedCurrencies)
                RadioListTile<String>(
                  value: c.code,
                  title: Text(c.name),
                  secondary: Text(
                    c.symbol.trim(),
                    style: Theme.of(context).textTheme.titleMedium,
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
    final text = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        children: [
          const SectionHeader('Appearance'),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Theme', style: text.titleSmall),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: SegmentedButton<ThemeMode>(
                      segments: const [
                        ButtonSegment(
                          value: ThemeMode.system,
                          label: Text('System'),
                          icon: Icon(Icons.brightness_auto_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.light,
                          label: Text('Light'),
                          icon: Icon(Icons.light_mode_outlined),
                        ),
                        ButtonSegment(
                          value: ThemeMode.dark,
                          label: Text('Dark'),
                          icon: Icon(Icons.dark_mode_outlined),
                        ),
                      ],
                      selected: {settings.themeMode},
                      showSelectedIcon: false,
                      onSelectionChanged: (s) =>
                          controller.setThemeMode(s.first),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text('Accent colour', style: text.titleSmall),
                  const SizedBox(height: 10),
                  ColorSwatchPicker(
                    colors: accentPalette,
                    selected: settings.seedColor,
                    onChanged: (c) {
                      if (c != null) controller.setSeedColor(c);
                    },
                  ),
                ],
              ),
            ),
          ),
          const SectionHeader('Money'),
          Card(
            child: ListTile(
              leading: const Icon(Icons.payments_outlined),
              title: const Text('Currency'),
              subtitle: Text(
                '${settings.currency.name} (${settings.currency.code})',
              ),
              trailing: const Icon(Icons.chevron_right_rounded),
              onTap: () => _pickCurrency(context, ref, settings.currencyCode),
            ),
          ),
          const SectionHeader('Data'),
          Card(
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
                  leading: Icon(
                    Icons.delete_forever_outlined,
                    color: Theme.of(context).colorScheme.error,
                  ),
                  title: Text(
                    'Delete all data',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.error,
                    ),
                  ),
                  subtitle: const Text(
                    'Everything is stored only on this device.',
                  ),
                  onTap: () => _deleteAll(context, ref),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Text(
              'Event Budget · v1.0.0',
              style: text.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
