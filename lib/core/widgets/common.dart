import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../design.dart';
import '../formatters.dart';
import '../palette.dart';
import '../theme.dart' show fontFamily;
import '../../state/settings.dart';

/// Shows loading and error states for an [AsyncValue] and builds [data]
/// once a value is available. Previous data stays visible while refreshing.
class AsyncView<T> extends StatelessWidget {
  const AsyncView({super.key, required this.value, required this.data});

  final AsyncValue<T> value;
  final Widget Function(T data) data;

  @override
  Widget build(BuildContext context) {
    return value.when(
      data: data,
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Something went wrong.\n$error',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

/// Staggered entrance for list and dashboard items.
extension EnterAnimation on Widget {
  Widget enter([int index = 0]) => animate()
      .fadeIn(
        duration: 380.ms,
        delay: (40 * index.clamp(0, 10)).ms,
        curve: Curves.easeOut,
      )
      .slideY(
        begin: 0.08,
        end: 0,
        duration: 420.ms,
        curve: Curves.easeOutCubic,
      );
}

/// Shrinks slightly while pressed and gives a light haptic tick.
class Pressable extends StatefulWidget {
  const Pressable({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
  });

  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  @override
  State<Pressable> createState() => _PressableState();
}

class _PressableState extends State<Pressable> {
  bool _down = false;

  void _set(bool v) {
    if (_down != v) setState(() => _down = v);
  }

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onTap != null || widget.onLongPress != null;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTapDown: enabled ? (_) => _set(true) : null,
      onTapUp: enabled ? (_) => _set(false) : null,
      onTapCancel: enabled ? () => _set(false) : null,
      onTap: widget.onTap == null
          ? null
          : () {
              HapticFeedback.selectionClick();
              widget.onTap!();
            },
      onLongPress: widget.onLongPress,
      child: AnimatedScale(
        scale: _down ? 0.97 : 1,
        duration: const Duration(milliseconds: 120),
        curve: Curves.easeOut,
        child: widget.child,
      ),
    );
  }
}

/// The rounded white (or dark) card everything sits on.
class Panel extends StatelessWidget {
  const Panel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.color,
    this.onTap,
    this.radius = Insets.radius,
    this.border = false,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;
  final VoidCallback? onTap;
  final double radius;
  final bool border;

  @override
  Widget build(BuildContext context) {
    // A Material (not a decorated box) so list tiles inside keep their
    // ink ripples.
    final box = SizedBox(
      width: double.infinity,
      child: Material(
        color: color ?? context.tokens.card,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radius),
          side: border
              ? BorderSide(color: context.tokens.border)
              : BorderSide.none,
        ),
        child: Padding(padding: padding, child: child),
      ),
    );
    return onTap == null ? box : Pressable(onTap: onTap, child: box);
  }
}

class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(32, 24, 32, Insets.navClearance),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 150,
              height: 130,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 112,
                    height: 112,
                    decoration: BoxDecoration(
                      color: context.highlight,
                      shape: BoxShape.circle,
                    ),
                  ),
                  Icon(icon, size: 46, color: inkOnHighlight),
                  Positioned(
                    left: 0,
                    top: 8,
                    child: _Orbit(
                      t: t,
                      child: CurrencyIcon(size: 20, color: t.ink),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 6,
                    child: _Orbit(
                      t: t,
                      child: Icon(
                        Icons.auto_awesome_rounded,
                        size: 18,
                        color: t.ink,
                      ),
                    ),
                  ),
                ],
              ),
            ).animate().scale(
              begin: const Offset(0.85, 0.85),
              duration: 500.ms,
              curve: Curves.easeOutBack,
            ),
            const SizedBox(height: 22),
            Text(
              title,
              style: context.text.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: context.text.bodyMedium?.copyWith(color: t.muted),
              textAlign: TextAlign.center,
            ),
            if (action != null) ...[const SizedBox(height: 26), action!],
          ],
        ).animate().fadeIn(duration: 400.ms),
      ),
    );
  }
}

class _Orbit extends StatelessWidget {
  const _Orbit({required this.child, required this.t});

  final Widget child;
  final AppTokens t;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: t.card,
        shape: BoxShape.circle,
        border: Border.all(color: t.ink, width: 1.5),
      ),
      child: Center(child: child),
    );
  }
}

class SectionHeader extends StatelessWidget {
  const SectionHeader(
    this.title, {
    super.key,
    this.trailing,
    this.padding,
    this.onSeeAll,
  });

  final String title;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  /// Shows a "See all" link when set.
  final VoidCallback? onSeeAll;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(2, 26, 2, 12),
      child: Row(
        children: [
          Expanded(child: Text(title, style: context.text.titleMedium)),
          ?trailing,
          if (onSeeAll != null) SeeAllLink(onTap: onSeeAll!),
        ],
      ),
    );
  }
}

class SeeAllLink extends StatelessWidget {
  const SeeAllLink({super.key, required this.onTap, this.label = 'See all'});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Pressable(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 2),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: context.text.labelMedium),
            const SizedBox(width: 2),
            const Icon(Icons.chevron_right_rounded, size: 18),
          ],
        ),
      ),
    );
  }
}

/// A small rounded label in a status colour.
class StatusPill extends StatelessWidget {
  const StatusPill({
    super.key,
    required this.label,
    required this.color,
    this.icon,
  });

  final String label;
  final Color color;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final fg = context.isDark ? Color.lerp(color, Colors.white, 0.45)! : color;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.22 : 0.13),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(label, style: context.text.labelSmall?.copyWith(color: fg)),
        ],
      ),
    );
  }
}

/// A tinted circle holding an icon, used as a list leading.
class IconBadge extends StatelessWidget {
  const IconBadge({
    super.key,
    required this.icon,
    required this.color,
    this.size = 46,
  });

  final IconData icon;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    final dark = color.computeLuminance() < 0.05;
    final bg = dark
        ? context.tokens.track
        : color.withValues(alpha: context.isDark ? 0.3 : 0.45);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      child: Icon(icon, size: size * 0.46, color: context.tokens.ink),
    );
  }
}

/// A white circular icon button with a hairline border.
class CircleButton extends StatelessWidget {
  const CircleButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.tooltip,
    this.size = 46,
    this.color,
    this.iconColor,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final String? tooltip;
  final double size;
  final Color? color;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final button = Pressable(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: color ?? t.card,
          shape: BoxShape.circle,
          border: color == null ? Border.all(color: t.border) : null,
        ),
        child: Icon(icon, size: size * 0.44, color: iconColor ?? t.ink),
      ),
    );
    return tooltip == null
        ? button
        : Semantics(
            button: true,
            label: tooltip,
            child: Tooltip(message: tooltip!, child: button),
          );
  }
}

/// A round quick-action with a caption underneath.
class ActionCircle extends StatelessWidget {
  const ActionCircle({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
    this.highlighted = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return Pressable(
      onTap: onTap,
      child: SizedBox(
        width: 64,
        child: Column(
          children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(
                color: highlighted ? context.highlight : t.card,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                size: 24,
                color: highlighted ? inkOnHighlight : t.ink,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: context.text.labelMedium,
            ),
          ],
        ),
      ),
    );
  }
}

/// Pill-shaped segmented tabs with a sliding highlight.
class PillTabs<T> extends StatelessWidget {
  const PillTabs({
    super.key,
    required this.values,
    required this.labelOf,
    required this.selected,
    required this.onChanged,
  });

  final List<T> values;
  final String Function(T) labelOf;
  final T selected;
  final ValueChanged<T> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final index = values.indexOf(selected);
    return Container(
      height: 52,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(999),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final width = constraints.maxWidth / values.length;
          return Stack(
            children: [
              AnimatedPositioned(
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
                left: width * index,
                top: 0,
                bottom: 0,
                width: width,
                child: Container(
                  decoration: BoxDecoration(
                    color: context.highlight,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Row(
                children: [
                  for (final v in values)
                    Expanded(
                      child: Semantics(
                        button: true,
                        selected: v == selected,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: () {
                            if (v == selected) return;
                            HapticFeedback.selectionClick();
                            onChanged(v);
                          },
                          child: Center(
                            child: AnimatedDefaultTextStyle(
                              duration: const Duration(milliseconds: 200),
                              style: context.text.labelLarge!.copyWith(
                                color: v == selected ? inkOnHighlight : t.muted,
                              ),
                              child: Text(labelOf(v)),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

/// A horizontally scrolling row of pill filters.
class PillFilters<T> extends StatelessWidget {
  const PillFilters({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  /// Value (null for "all") and label pairs.
  final List<(T?, String)> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      clipBehavior: Clip.none,
      child: Row(
        children: [
          for (final (value, label) in options)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Pressable(
                onTap: () => onChanged(value),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 11,
                  ),
                  decoration: BoxDecoration(
                    color: value == selected ? context.highlight : t.card,
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    label,
                    style: context.text.labelLarge?.copyWith(
                      color: value == selected ? inkOnHighlight : t.ink,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A money amount with the decimals set smaller, e.g. "$25,453" + ".00".
/// Counts up from its previous value when the amount changes.
class BigAmount extends ConsumerWidget {
  const BigAmount(
    this.value, {
    super.key,
    this.style,
    this.color,
    this.animate = true,
  });

  final double value;
  final TextStyle? style;
  final Color? color;
  final bool animate;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final money = ref.watch(moneyProvider);
    final base = (style ?? context.text.displaySmall!).copyWith(color: color);
    Widget render(double v) {
      final text = money.format(v);
      final dot = text.lastIndexOf('.');
      final hasDecimals = money.currency.decimals > 0 && dot > 0;
      return Text.rich(
        TextSpan(
          children: [
            TextSpan(text: hasDecimals ? text.substring(0, dot) : text),
            if (hasDecimals)
              TextSpan(
                text: text.substring(dot),
                style: base.copyWith(
                  fontSize: (base.fontSize ?? 36) * 0.6,
                  color: (color ?? base.color ?? context.tokens.ink).withValues(
                    alpha: 0.55,
                  ),
                  letterSpacing: 0,
                ),
              ),
          ],
        ),
        style: base,
        maxLines: 1,
      );
    }

    if (!animate) {
      return FittedBox(
        fit: BoxFit.scaleDown,
        alignment: Alignment.centerLeft,
        child: render(value),
      );
    }
    return FittedBox(
      fit: BoxFit.scaleDown,
      alignment: Alignment.centerLeft,
      child: TweenAnimationBuilder<double>(
        tween: Tween(end: value),
        duration: const Duration(milliseconds: 900),
        curve: Curves.easeOutExpo,
        builder: (context, v, _) => render(v),
      ),
    );
  }
}

/// A row of dots filled in proportion to [value], like a goal tracker.
class DotsProgress extends StatelessWidget {
  const DotsProgress({
    super.key,
    required this.value,
    this.count = 14,
    this.color,
    this.emptyColor,
    this.size = 7,
  });

  final double value;
  final int count;
  final Color? color;
  final Color? emptyColor;
  final double size;

  @override
  Widget build(BuildContext context) {
    final filled = (value.clamp(0.0, 1.0) * count).round();
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        for (var i = 0; i < count; i++)
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: i < filled ? (color ?? inkOnHighlight) : null,
              border: i < filled
                  ? null
                  : Border.all(
                      color:
                          emptyColor ?? inkOnHighlight.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
            ),
          ).animate().fadeIn(delay: (30 * i).ms, duration: 200.ms),
      ],
    );
  }
}

/// A coloured circle with someone's initials.
class InitialsAvatar extends StatelessWidget {
  const InitialsAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.ring,
  });

  final String name;
  final double size;

  /// Optional border colour, used when avatars overlap.
  final Color? ring;

  @override
  Widget build(BuildContext context) {
    final color = Color(notePalette[name.hashCode.abs() % notePalette.length]);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: ring == null ? null : Border.all(color: ring!, width: 2.5),
      ),
      alignment: Alignment.center,
      child: Text(
        initials(name),
        style: context.text.labelLarge?.copyWith(
          color: inkOnHighlight,
          fontSize: size * 0.34,
        ),
      ),
    );
  }
}

/// A compact label/value tile for dashboards.
class StatTile extends StatelessWidget {
  const StatTile({
    super.key,
    required this.label,
    required this.value,
    this.icon,
    this.color,
  });

  final String label;
  final String value;
  final IconData? icon;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final t = context.tokens;
    final accent = color == null
        ? null
        : (context.isDark ? Color.lerp(color, Colors.white, 0.35) : color);
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 16),
      decoration: BoxDecoration(
        color: t.card,
        borderRadius: BorderRadius.circular(Insets.smallRadius),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: accent ?? t.muted),
                const SizedBox(width: 5),
              ],
              Expanded(
                child: Text(
                  label,
                  style: context.text.labelMedium?.copyWith(color: t.muted),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: context.text.titleLarge?.copyWith(color: accent),
            ),
          ),
        ],
      ),
    );
  }
}

/// A rounded, animated linear progress bar.
class ProgressBar extends StatelessWidget {
  const ProgressBar({
    super.key,
    required this.value,
    required this.color,
    this.height = 8,
    this.trackColor,
  });

  final double value;
  final Color color;
  final double height;
  final Color? trackColor;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, v, _) => Container(
        height: height,
        decoration: BoxDecoration(
          color: trackColor ?? context.tokens.track,
          borderRadius: BorderRadius.circular(height),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: v,
          child: Container(
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(height),
            ),
          ),
        ),
      ),
    );
  }
}

Future<bool> confirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String confirmLabel = 'Delete',
  bool destructive = true,
}) async {
  final scheme = Theme.of(context).colorScheme;
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: destructive
              ? FilledButton.styleFrom(
                  backgroundColor: scheme.error,
                  foregroundColor: scheme.onError,
                  minimumSize: const Size(64, 44),
                )
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(context, true),
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result ?? false;
}

void showSnack(BuildContext context, String message, {SnackBarAction? action}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(message), action: action));
}

/// The app bar for secondary screens: round back (or close) button,
/// centred title and round action buttons.
PreferredSizeWidget pageBar(
  BuildContext context, {
  String title = '',
  List<Widget> actions = const [],
  bool close = false,
  Color? background,
}) {
  return AppBar(
    toolbarHeight: 68,
    backgroundColor: background,
    automaticallyImplyLeading: false,
    leadingWidth: 72,
    leading: Padding(
      padding: const EdgeInsets.only(left: 16),
      child: Center(
        child: CircleButton(
          icon: close ? Icons.close_rounded : Icons.arrow_back_rounded,
          tooltip: close ? 'Close' : 'Back',
          onTap: () => Navigator.maybePop(context),
        ),
      ),
    ),
    title: Text(title),
    actions: [
      for (final a in actions)
        Padding(padding: const EdgeInsets.only(left: 8), child: a),
      const SizedBox(width: 16),
    ],
  );
}

/// A compact pill button for app bar actions such as "Save".
class BarButton extends StatelessWidget {
  const BarButton({super.key, required this.label, required this.onPressed});

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      style: FilledButton.styleFrom(
        minimumSize: const Size(72, 46),
        padding: const EdgeInsets.symmetric(horizontal: 20),
      ),
      onPressed: onPressed,
      child: Text(label),
    );
  }
}

/// The chosen currency's symbol drawn as an icon, e.g. "Br" for the
/// Ethiopian birr, so money visuals never default to a dollar sign.
class CurrencyIcon extends ConsumerWidget {
  const CurrencyIcon({super.key, this.size = 24, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final symbol = ref.watch(moneyProvider).currency.symbol.trim();
    return SizedBox.square(
      dimension: size,
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(size * 0.06),
          child: FittedBox(
            child: Text(
              symbol,
              maxLines: 1,
              style: TextStyle(
                fontFamily: fontFamily,
                fontWeight: FontWeight.w800,
                fontSize: size * 0.62,
                height: 1,
                letterSpacing: -size * 0.03,
                color: color ?? IconTheme.of(context).color,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
