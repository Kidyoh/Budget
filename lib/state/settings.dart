import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/money.dart';
import '../core/palette.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.seedColor = 0xFF6750A4,
    this.currencyCode = 'USD',
  });

  final ThemeMode themeMode;
  final int seedColor;
  final String currencyCode;

  Currency get currency => currencyByCode(currencyCode);
}

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const _themeKey = 'theme_mode';
  static const _seedKey = 'seed_color';
  static const _currencyKey = 'currency';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeName = prefs.getString(_themeKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      seedColor: prefs.getInt(_seedKey) ?? accentPalette.first,
      currencyCode: prefs.getString(_currencyKey) ?? 'USD',
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = AppSettings(
      themeMode: mode,
      seedColor: state.seedColor,
      currencyCode: state.currencyCode,
    );
    await _prefs.setString(_themeKey, mode.name);
  }

  Future<void> setSeedColor(int color) async {
    state = AppSettings(
      themeMode: state.themeMode,
      seedColor: color,
      currencyCode: state.currencyCode,
    );
    await _prefs.setInt(_seedKey, color);
  }

  Future<void> setCurrency(String code) async {
    state = AppSettings(
      themeMode: state.themeMode,
      seedColor: state.seedColor,
      currencyCode: code,
    );
    await _prefs.setString(_currencyKey, code);
  }
}

final moneyProvider = Provider<Money>(
  (ref) => Money(ref.watch(settingsProvider.select((s) => s.currency))),
);
