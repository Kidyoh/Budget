import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/events/events_screen.dart';
import 'state/settings.dart';

class EventBudgetApp extends ConsumerWidget {
  const EventBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final seed = Color(settings.seedColor);
    return MaterialApp(
      title: 'Event Budget',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildTheme(seed, Brightness.light),
      darkTheme: buildTheme(seed, Brightness.dark),
      home: const EventsScreen(),
    );
  }
}
