import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';

import 'design.dart';

const fontFamily = 'PlusJakartaSans';

/// Builds the lime-and-ink theme around [highlight].
ThemeData buildTheme(Color highlight, Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final t = dark ? AppTokens.dark : AppTokens.light;

  final scheme = ColorScheme(
    brightness: brightness,
    primary: highlight,
    onPrimary: inkOnHighlight,
    primaryContainer: highlight,
    onPrimaryContainer: inkOnHighlight,
    secondary: t.ink,
    onSecondary: t.canvas,
    secondaryContainer: t.track,
    onSecondaryContainer: t.ink,
    tertiary: const Color(0xFFB8B5FA),
    onTertiary: inkOnHighlight,
    error: const Color(0xFFE5484D),
    onError: Colors.white,
    surface: t.canvas,
    onSurface: t.ink,
    onSurfaceVariant: t.muted,
    surfaceContainerLowest: t.card,
    surfaceContainerLow: t.card,
    surfaceContainer: t.card,
    surfaceContainerHigh: dark
        ? const Color(0xFF222225)
        : const Color(0xFFF7F7F4),
    surfaceContainerHighest: t.track,
    outline: t.faint,
    outlineVariant: t.border,
    inverseSurface: t.ink,
    onInverseSurface: t.canvas,
    inversePrimary: highlight,
    shadow: Colors.black,
    scrim: Colors.black,
    surfaceTint: Colors.transparent,
  );

  final base = ThemeData(
    useMaterial3: true,
    brightness: brightness,
    colorScheme: scheme,
    fontFamily: fontFamily,
    extensions: [t],
  );
  final text = _textTheme(base.textTheme, t);

  const pill = StadiumBorder();
  final heroBg = dark ? highlight : heroInk;
  final onHero = dark ? inkOnHighlight : Colors.white;

  return base.copyWith(
    scaffoldBackgroundColor: t.canvas,
    canvasColor: t.canvas,
    textTheme: text,
    splashFactory: InkSparkle.splashFactory,
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: _SoftSlideTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
    appBarTheme: AppBarTheme(
      backgroundColor: t.canvas,
      foregroundColor: t.ink,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      centerTitle: true,
      titleTextStyle: text.titleMedium?.copyWith(fontWeight: FontWeight.w700),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      margin: EdgeInsets.zero,
      color: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Insets.smallRadius)),
      ),
      clipBehavior: Clip.antiAlias,
    ),
    dividerTheme: DividerThemeData(color: t.border, thickness: 1, space: 1),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      // Filled style with the label inside the field; focus tints the
      // field with the highlight colour instead of drawing an outline.
      fillColor: WidgetStateColor.resolveWith(
        (states) => states.contains(WidgetState.focused)
            ? Color.alphaBlend(
                highlight.withValues(alpha: dark ? 0.16 : 0.22),
                t.card,
              )
            : t.card,
      ),
      contentPadding: const EdgeInsets.fromLTRB(18, 14, 18, 14),
      labelStyle: TextStyle(color: t.muted, fontWeight: FontWeight.w500),
      floatingLabelStyle: TextStyle(
        color: t.muted,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: TextStyle(color: t.faint),
      prefixIconColor: t.muted,
      suffixIconColor: t.muted,
      helperStyle: TextStyle(color: t.muted),
      border: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide.none,
      ),
      enabledBorder: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide.none,
      ),
      focusedBorder: const UnderlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide.none,
      ),
      errorBorder: UnderlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
      focusedErrorBorder: UnderlineInputBorder(
        borderRadius: const BorderRadius.all(Radius.circular(18)),
        borderSide: BorderSide(color: scheme.error, width: 2),
      ),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: heroBg,
        foregroundColor: onHero,
        minimumSize: const Size(64, 54),
        shape: pill,
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: t.ink,
        backgroundColor: t.card,
        minimumSize: const Size(64, 54),
        shape: pill,
        side: BorderSide(color: t.border),
        textStyle: text.labelLarge?.copyWith(fontSize: 15),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: t.ink,
        textStyle: text.labelLarge,
        shape: pill,
      ),
    ),
    iconButtonTheme: IconButtonThemeData(
      style: IconButton.styleFrom(foregroundColor: t.ink),
    ),
    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: highlight,
      foregroundColor: inkOnHighlight,
      elevation: 0,
      highlightElevation: 0,
      shape: const CircleBorder(),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: t.card,
      selectedColor: highlight,
      disabledColor: t.track,
      side: BorderSide.none,
      shape: pill,
      labelStyle: text.labelLarge?.copyWith(color: t.ink),
      secondaryLabelStyle: text.labelLarge?.copyWith(color: inkOnHighlight),
      checkmarkColor: inkOnHighlight,
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
      showCheckmark: false,
    ),
    segmentedButtonTheme: SegmentedButtonThemeData(
      style: SegmentedButton.styleFrom(
        backgroundColor: t.card,
        foregroundColor: t.ink,
        selectedBackgroundColor: highlight,
        selectedForegroundColor: inkOnHighlight,
        side: BorderSide(color: t.border),
        shape: pill,
        textStyle: text.labelLarge,
      ),
    ),
    checkboxTheme: CheckboxThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) =>
            s.contains(WidgetState.selected) ? highlight : Colors.transparent,
      ),
      checkColor: const WidgetStatePropertyAll(inkOnHighlight),
      side: BorderSide(color: t.faint, width: 1.6),
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? inkOnHighlight : t.faint,
      ),
      trackColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? highlight : t.track,
      ),
      trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
    ),
    radioTheme: RadioThemeData(
      fillColor: WidgetStateProperty.resolveWith(
        (s) => s.contains(WidgetState.selected) ? t.ink : t.faint,
      ),
    ),
    listTileTheme: ListTileThemeData(
      iconColor: t.muted,
      titleTextStyle: text.titleSmall,
      subtitleTextStyle: text.bodySmall?.copyWith(color: t.muted),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(16)),
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: t.canvas,
      modalBackgroundColor: t.canvas,
      showDragHandle: true,
      dragHandleColor: t.faint,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: t.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
      titleTextStyle: text.titleLarge,
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: t.card,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
      textStyle: text.bodyMedium,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: heroInk,
      contentTextStyle: text.bodyMedium?.copyWith(color: Colors.white),
      actionTextColor: highlight,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(18)),
      ),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(
      color: t.ink,
      linearTrackColor: t.track,
      circularTrackColor: t.track,
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: t.card,
      surfaceTintColor: Colors.transparent,
      headerBackgroundColor: heroBg,
      headerForegroundColor: onHero,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(28)),
      ),
    ),
    tooltipTheme: TooltipThemeData(
      decoration: BoxDecoration(
        color: heroInk,
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: text.labelMedium?.copyWith(color: Colors.white),
    ),
  );
}

TextTheme _textTheme(TextTheme base, AppTokens t) {
  TextStyle? s(
    TextStyle? style,
    double size,
    FontWeight weight, {
    double spacing = 0,
    double? height,
  }) => style?.copyWith(
    fontFamily: fontFamily,
    fontSize: size,
    fontWeight: weight,
    letterSpacing: spacing,
    height: height,
    color: t.ink,
  );
  return base.copyWith(
    displayLarge: s(
      base.displayLarge,
      52,
      FontWeight.w700,
      spacing: -2,
      height: 1.05,
    ),
    displayMedium: s(
      base.displayMedium,
      44,
      FontWeight.w700,
      spacing: -1.6,
      height: 1.05,
    ),
    displaySmall: s(
      base.displaySmall,
      36,
      FontWeight.w700,
      spacing: -1.2,
      height: 1.1,
    ),
    headlineLarge: s(
      base.headlineLarge,
      32,
      FontWeight.w700,
      spacing: -1,
      height: 1.15,
    ),
    headlineMedium: s(
      base.headlineMedium,
      26,
      FontWeight.w700,
      spacing: -0.7,
      height: 1.2,
    ),
    headlineSmall: s(
      base.headlineSmall,
      22,
      FontWeight.w700,
      spacing: -0.5,
      height: 1.25,
    ),
    titleLarge: s(base.titleLarge, 19, FontWeight.w700, spacing: -0.3),
    titleMedium: s(base.titleMedium, 16, FontWeight.w700, spacing: -0.2),
    titleSmall: s(base.titleSmall, 14.5, FontWeight.w600, spacing: -0.1),
    bodyLarge: s(base.bodyLarge, 15.5, FontWeight.w500, height: 1.45),
    bodyMedium: s(base.bodyMedium, 14, FontWeight.w500, height: 1.45),
    bodySmall: s(base.bodySmall, 12.5, FontWeight.w500, height: 1.4),
    labelLarge: s(base.labelLarge, 14, FontWeight.w700),
    labelMedium: s(base.labelMedium, 12.5, FontWeight.w600),
    labelSmall: s(base.labelSmall, 11, FontWeight.w700, spacing: 0.2),
  );
}

/// Android page transition: the new page fades in while rising slightly.
class _SoftSlideTransitionsBuilder extends PageTransitionsBuilder {
  const _SoftSlideTransitionsBuilder();

  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    final curved = CurvedAnimation(
      parent: animation,
      curve: Curves.easeOutCubic,
      reverseCurve: Curves.easeInCubic,
    );
    final behind = CurvedAnimation(
      parent: secondaryAnimation,
      curve: Curves.easeOutCubic,
    );
    return FadeTransition(
      opacity: Tween(begin: 1.0, end: 0.6).animate(behind),
      child: ScaleTransition(
        scale: Tween(begin: 1.0, end: 0.97).animate(behind),
        child: FadeTransition(
          opacity: curved,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(curved),
            child: child,
          ),
        ),
      ),
    );
  }
}
