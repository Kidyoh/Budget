import 'package:flutter/material.dart';

/// Design tokens for the lime-and-ink look.
///
/// The colour scheme's `primary` is the highlight colour (lime by default).
/// It is always used as a *fill* with ink text on top, never as text on a
/// light background. These tokens carry the surfaces, text colours and the
/// "hero" card colours that flip between light and dark mode.
@immutable
class AppTokens extends ThemeExtension<AppTokens> {
  const AppTokens({
    required this.canvas,
    required this.card,
    required this.border,
    required this.ink,
    required this.muted,
    required this.faint,
    required this.track,
    required this.navBar,
    required this.raised,
  });

  /// Page background.
  final Color canvas;

  /// Card and sheet surface.
  final Color card;

  /// Hairline borders and dividers.
  final Color border;

  /// Primary text.
  final Color ink;

  /// Secondary text.
  final Color muted;

  /// Tertiary text and placeholder icons.
  final Color faint;

  /// Progress tracks and subtle fills.
  final Color track;

  /// The floating navigation pill.
  final Color navBar;

  /// Soft shadow for floating elements; empty in dark mode.
  final List<BoxShadow> raised;

  static const light = AppTokens(
    canvas: Color(0xFFF1F2EE),
    card: Color(0xFFFFFFFF),
    border: Color(0xFFE4E5E0),
    ink: Color(0xFF141414),
    muted: Color(0xFF6B6D70),
    faint: Color(0xFFA3A5A8),
    track: Color(0xFFEBECE7),
    navBar: Color(0xFF161616),
    raised: [
      BoxShadow(
        color: Color(0x1A000000),
        blurRadius: 30,
        offset: Offset(0, 12),
      ),
    ],
  );

  static const dark = AppTokens(
    canvas: Color(0xFF0A0A0B),
    card: Color(0xFF1B1B1D),
    border: Color(0xFF2A2A2D),
    ink: Color(0xFFF5F5F4),
    muted: Color(0xFFA1A1A6),
    faint: Color(0xFF6B6B70),
    track: Color(0xFF2A2A2D),
    navBar: Color(0xFF242426),
    raised: [],
  );

  @override
  AppTokens copyWith() => this;

  @override
  AppTokens lerp(AppTokens? other, double t) {
    if (other == null) return this;
    return AppTokens(
      canvas: Color.lerp(canvas, other.canvas, t)!,
      card: Color.lerp(card, other.card, t)!,
      border: Color.lerp(border, other.border, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      track: Color.lerp(track, other.track, t)!,
      navBar: Color.lerp(navBar, other.navBar, t)!,
      raised: t < 0.5 ? raised : other.raised,
    );
  }
}

/// Fixed ink used for text on highlight fills in both themes.
const inkOnHighlight = Color(0xFF141414);

/// The near-black used for "bank card" heroes in light mode.
const heroInk = Color(0xFF161616);

extension DesignContext on BuildContext {
  AppTokens get tokens => Theme.of(this).extension<AppTokens>()!;
  ColorScheme get colors => Theme.of(this).colorScheme;
  TextTheme get text => Theme.of(this).textTheme;
  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  /// The highlight colour (lime by default).
  Color get highlight => Theme.of(this).colorScheme.primary;

  /// Background of hero cards: ink in light mode, the highlight in dark.
  Color get heroBg => isDark ? highlight : heroInk;

  /// Text on hero cards.
  Color get onHero => isDark ? inkOnHighlight : Colors.white;
}

abstract final class Insets {
  static const page = 20.0;
  static const gap = 12.0;
  static const radius = 28.0;
  static const smallRadius = 20.0;

  /// Space to leave under scrolling content for the floating nav bar.
  static const navClearance = 120.0;
}

/// Black or white, whichever reads better on [background].
Color onColor(Color background) =>
    ThemeData.estimateBrightnessForColor(background) == Brightness.dark
    ? Colors.white
    : inkOnHighlight;

/// Makes a stored colour visible on the current surface: very dark swatches
/// are lightened in dark mode so they don't vanish.
Color visible(Color color, BuildContext context) {
  if (!context.isDark) return color;
  return color.computeLuminance() < 0.05 ? const Color(0xFFE4E4E7) : color;
}

/// A soft wash of [color] for tinted backgrounds.
Color wash(Color color, BuildContext context, [double strength = 1]) =>
    color.withValues(alpha: (context.isDark ? 0.22 : 0.16) * strength);
