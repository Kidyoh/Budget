import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../core/money.dart';
import '../core/palette.dart';

class AppSettings {
  const AppSettings({
    this.themeMode = ThemeMode.system,
    this.highlight = defaultHighlight,
    this.currencyCode = 'USD',
    this.name = '',
    this.onboarded = false,
  });

  final ThemeMode themeMode;

  /// The accent fill colour (lime by default).
  final int highlight;
  final String currencyCode;

  /// What the home screen greets the user by; may be empty.
  final String name;

  /// Whether the welcome screens have been shown.
  final bool onboarded;

  Currency get currency => currencyByCode(currencyCode);

  AppSettings copyWith({
    ThemeMode? themeMode,
    int? highlight,
    String? currencyCode,
    String? name,
    bool? onboarded,
  }) => AppSettings(
    themeMode: themeMode ?? this.themeMode,
    highlight: highlight ?? this.highlight,
    currencyCode: currencyCode ?? this.currencyCode,
    name: name ?? this.name,
    onboarded: onboarded ?? this.onboarded,
  );
}

/// Overridden in `main()` with the loaded instance.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('sharedPreferencesProvider not overridden'),
);

final settingsProvider = NotifierProvider<SettingsController, AppSettings>(
  SettingsController.new,
);

class SettingsController extends Notifier<AppSettings> {
  static const themeKey = 'theme_mode';
  static const highlightKey = 'highlight';
  static const currencyKey = 'currency';
  static const nameKey = 'name';
  static const onboardedKey = 'onboarded';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AppSettings build() {
    final prefs = ref.watch(sharedPreferencesProvider);
    final themeName = prefs.getString(themeKey);
    final highlight = prefs.getInt(highlightKey);
    return AppSettings(
      themeMode: ThemeMode.values.firstWhere(
        (m) => m.name == themeName,
        orElse: () => ThemeMode.system,
      ),
      highlight: highlightPalette.contains(highlight)
          ? highlight!
          : defaultHighlight,
      currencyCode: prefs.getString(currencyKey) ?? 'USD',
      name: prefs.getString(nameKey) ?? '',
      onboarded: prefs.getBool(onboardedKey) ?? false,
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = state.copyWith(themeMode: mode);
    await _prefs.setString(themeKey, mode.name);
  }

  Future<void> setHighlight(int color) async {
    state = state.copyWith(highlight: color);
    await _prefs.setInt(highlightKey, color);
  }

  Future<void> setCurrency(String code) async {
    state = state.copyWith(currencyCode: code);
    await _prefs.setString(currencyKey, code);
  }

  Future<void> setName(String name) async {
    state = state.copyWith(name: name.trim());
    await _prefs.setString(nameKey, name.trim());
  }

  Future<void> setOnboarded(bool value) async {
    state = state.copyWith(onboarded: value);
    await _prefs.setBool(onboardedKey, value);
  }
}

final moneyProvider = Provider<Money>(
  (ref) => Money(ref.watch(settingsProvider.select((s) => s.currency))),
);
