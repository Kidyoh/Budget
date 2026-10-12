import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/theme.dart';
import 'features/events/events_screen.dart';
import 'features/onboarding/onboarding_screen.dart';
import 'state/settings.dart';

class EventBudgetApp extends ConsumerWidget {
  const EventBudgetApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final highlight = Color(settings.highlight);
    return MaterialApp(
      title: 'Event Budget',
      debugShowCheckedModeBanner: false,
      themeMode: settings.themeMode,
      theme: buildTheme(highlight, Brightness.light),
      darkTheme: buildTheme(highlight, Brightness.dark),
      builder: (context, child) {
        // Status bar icons follow the theme on both platforms.
        final dark = Theme.of(context).brightness == Brightness.dark;
        return AnnotatedRegion<SystemUiOverlayStyle>(
          value: (dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark)
              .copyWith(
                statusBarColor: Colors.transparent,
                systemNavigationBarColor: Colors.transparent,
              ),
          child: child!,
        );
      },
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        child: settings.onboarded
            ? const EventsScreen()
            : const OnboardingScreen(),
      ),
    );
  }
}
