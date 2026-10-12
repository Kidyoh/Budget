import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'data/database.dart';
import 'state/providers.dart';
import 'state/settings.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  LicenseRegistry.addLicense(() async* {
    final ofl = await rootBundle.loadString('assets/fonts/OFL.txt');
    yield LicenseEntryWithLineBreaks(['Plus Jakarta Sans'], ofl);
  });
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
