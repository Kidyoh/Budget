import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'state/providers.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final results = await Future.wait([
    AppDatabase.open(),
    SharedPreferences.getInstance(),
  ]);
  runApp(
    ProviderScope(
      overrides: [
        databaseProvider.overrideWithValue(results[0] as AppDatabase),
        sharedPreferencesProvider.overrideWithValue(
          results[1] as SharedPreferences,
        ),
      ],
      child: const EventBudgetApp(),
    ),
  );
}
