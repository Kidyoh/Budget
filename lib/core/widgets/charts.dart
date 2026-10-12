import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// A circular progress ring with content in the middle.
class ProgressRing extends StatelessWidget {
  const ProgressRing({
    super.key,
    required this.value,
    required this.color,
    this.size = 140,
    this.strokeWidth = 14,
    this.child,
  });

  /// 0 to 1; values above 1 draw a full ring.
  final double value;
  final Color color;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.clamp(0.0, 1.0)),
      duration: const Duration(milliseconds: 700),
      curve: Curves.easeOutCubic,
      builder: (context, animated, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            segments: [_Segment(animated, color)],
            track: track,
            strokeWidth: strokeWidth,
            gap: 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class DonutSlice {
  const DonutSlice({required this.value, required this.color});

  final double value;
  final Color color;
}

/// A donut chart. Slices are drawn in order, clockwise from the top.
class DonutChart extends StatelessWidget {
  const DonutChart({
    super.key,
    required this.slices,
    this.size = 150,
    this.strokeWidth = 22,
    this.child,
  });

  final List<DonutSlice> slices;
  final double size;
  final double strokeWidth;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    final total = slices.fold<double>(
      0,
      (sum, s) => sum + math.max(0, s.value),
    );
    final track = Theme.of(context).colorScheme.surfaceContainerHighest;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _RingPainter(
            segments: [
              if (total > 0)
                for (final s in slices)
                  if (s.value > 0) _Segment(s.value / total * t, s.color),
            ],
            track: track,
            strokeWidth: strokeWidth,
            gap: slices.where((s) => s.value > 0).length > 1 ? 0.012 : 0,
          ),
          child: Center(child: child),
        ),
      ),
    );
  }
}

class _Segment {
  const _Segment(this.fraction, this.color);

  final double fraction;
  final Color color;
}

class _RingPainter extends CustomPainter {
  _RingPainter({
    required this.segments,
    required this.track,
    required this.strokeWidth,
    required this.gap,
  });

  final List<_Segment> segments;
  final Color track;
  final double strokeWidth;

  /// Gap between segments as a fraction of the full circle.
  final double gap;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: size.center(Offset.zero),
      radius: (size.shortestSide - strokeWidth) / 2,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(rect, 0, math.pi * 2, false, paint..color = track);

    var start = -math.pi / 2;
    for (final s in segments) {
      final sweep = s.fraction * math.pi * 2;
      final gapAngle = math.min(gap * math.pi * 2, sweep / 2);
      final drawn = sweep - gapAngle;
      if (drawn > 0.001) {
        // Round caps extend past the arc ends; trim them back when slices
        // sit side by side so neighbours don't overlap.
        final capAngle = segments.length > 1
            ? strokeWidth / 2 / rect.width * 2
            : 0.0;
        final adjustedStart =
            start + gapAngle / 2 + math.min(capAngle, drawn / 2);
        final adjustedSweep = math.max(
          0.001,
          drawn - 2 * math.min(capAngle, drawn / 2),
        );
        canvas.drawArc(
          rect,
          adjustedStart,
          adjustedSweep,
          false,
          paint..color = s.color,
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_RingPainter old) =>
      old.segments != segments ||
      old.track != track ||
      old.strokeWidth != strokeWidth;
}

/// Diagonal stripes, used for budget that's allocated but not yet spent.
class HatchPainter extends CustomPainter {
  HatchPainter({required this.color, this.gap = 7, this.stroke = 2});

  final Color color;
  final double gap;
  final double stroke;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = stroke;
    canvas.save();
    canvas.clipRect(Offset.zero & size);
    for (var x = -size.height; x < size.width; x += gap) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        paint,
      );
    }
    canvas.restore();
  }

  @override
  bool shouldRepaint(HatchPainter old) => old.color != color || old.gap != gap;
}

class BarDatum {
  const BarDatum({
    required this.label,
    required this.icon,
    required this.paid,
    required this.unpaid,
    required this.allocated,
  });

  final String label;
  final IconData icon;
  final double paid;
  final double unpaid;
  final double allocated;

  double get committed => paid + unpaid;
  double get height => math.max(committed, allocated);
}

/// Vertical stacked bars: paid at the bottom, unpaid above it, and any
/// allocation not yet committed shown as a hatched cap. Tapping a bar
/// shows its committed amount in a pill above it.
class StackedBarChart extends StatefulWidget {
  const StackedBarChart({
    super.key,
    required this.bars,
    required this.format,
    required this.paidColor,
    required this.unpaidColor,
    required this.hatchColor,
    this.height = 190,
  });

  final List<BarDatum> bars;
  final String Function(double) format;
  final Color paidColor;
  final Color unpaidColor;
  final Color hatchColor;
  final double height;

  @override
  State<StackedBarChart> createState() => _StackedBarChartState();
}

class _StackedBarChartState extends State<StackedBarChart> {
  int? _selected;

  int get _defaultSelected {
    var best = 0;
    for (var i = 1; i < widget.bars.length; i++) {
      if (widget.bars[i].committed > widget.bars[best].committed) best = i;
    }
    return best;
  }

  @override
  Widget build(BuildContext context) {
    final bars = widget.bars;
    if (bars.isEmpty) return const SizedBox.shrink();
    final selected = (_selected ?? _defaultSelected).clamp(0, bars.length - 1);
    final maxValue = bars.fold<double>(0, (m, b) => math.max(m, b.height));
    final theme = Theme.of(context);
    const tooltipSpace = 36.0;
    const labelSpace = 40.0;

    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 750),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) {
        double h(double v) =>
            maxValue <= 0 ? 0 : v / maxValue * widget.height * t;
        final sel = bars[selected];
        final pillTop = tooltipSpace + widget.height - h(sel.height) - 30;

        return SizedBox(
          height: widget.height + tooltipSpace + labelSpace,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final slot = constraints.maxWidth / bars.length;
              final barWidth = math.min(34.0, slot * 0.62);
              return Stack(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      for (var i = 0; i < bars.length; i++)
                        SizedBox(
                          width: slot,
                          child: GestureDetector(
                            behavior: HitTestBehavior.opaque,
                            onTap: () {
                              HapticFeedback.selectionClick();
                              setState(() => _selected = i);
                            },
                            child: _Bar(
                              datum: bars[i],
                              width: barWidth,
                              h: h,
                              selected: i == selected,
                              paidColor: widget.paidColor,
                              unpaidColor: widget.unpaidColor,
                              hatchColor: widget.hatchColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  // The value pill floats above the selected bar and is kept
                  // inside the chart by aligning proportionally.
                  Positioned(
                    left: 0,
                    right: 0,
                    top: math.max(0, pillTop),
                    child: AnimatedAlign(
                      duration: const Duration(milliseconds: 250),
                      curve: Curves.easeOutCubic,
                      alignment: Alignment(
                        (selected + 0.5) / bars.length * 2 - 1,
                        0,
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF161616),
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.12),
                          ),
                        ),
                        child: Text(
                          '${sel.label} · ${widget.format(sel.committed)}',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.datum,
    required this.width,
    required this.h,
    required this.selected,
    required this.paidColor,
    required this.unpaidColor,
    required this.hatchColor,
  });

  final BarDatum datum;
  final double width;
  final double Function(double) h;
  final bool selected;
  final Color paidColor;
  final Color unpaidColor;
  final Color hatchColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final b = datum;
    final hatch = math.max(0.0, b.allocated - b.committed);
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        AnimatedOpacity(
          duration: const Duration(milliseconds: 200),
          opacity: selected ? 1 : 0.85,
          child: SizedBox(
            width: width,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (h(hatch) >= 1)
                    Container(
                      height: h(hatch),
                      decoration: BoxDecoration(
                        border: Border.all(color: hatchColor, width: 1.2),
                        borderRadius: BorderRadius.vertical(
                          top: const Radius.circular(10),
                          bottom: b.committed > 0
                              ? Radius.zero
                              : const Radius.circular(10),
                        ),
                      ),
                      child: CustomPaint(
                        painter: HatchPainter(
                          color: hatchColor,
                          gap: 6,
                          stroke: 1.4,
                        ),
                      ),
                    ),
                  Container(height: h(b.unpaid), color: unpaidColor),
                  if (h(b.paid) >= 1 && h(b.unpaid) >= 1)
                    const SizedBox(height: 3),
                  Container(height: h(b.paid), color: paidColor),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: selected ? theme.colorScheme.primary : Colors.transparent,
          ),
          child: Icon(
            b.icon,
            size: 16,
            color: selected
                ? const Color(0xFF141414)
                : theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 2),
      ],
    );
  }
}

/// A horizontal bar split into paid, committed-but-unpaid and remaining
/// (hatched) budget. Overspend fills the bar in [overColor].
class SpendBar extends StatelessWidget {
  const SpendBar({
    super.key,
    required this.paid,
    required this.unpaid,
    required this.budget,
    required this.paidColor,
    required this.unpaidColor,
    required this.hatchColor,
    this.overColor = const Color(0xFFEB5545),
    this.height = 14,
  });

  final double paid;
  final double unpaid;
  final double budget;
  final Color paidColor;
  final Color unpaidColor;
  final Color hatchColor;
  final Color overColor;
  final double height;

  @override
  Widget build(BuildContext context) {
    final committed = paid + unpaid;
    final scale = math.max(budget, committed);
    if (scale <= 0) {
      return Container(
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(height),
          border: Border.all(color: hatchColor),
        ),
      );
    }
    final over = committed > budget + 0.005;
    int flex(double v) => (v / scale * 1000).round();
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, t, _) => ClipRRect(
        borderRadius: BorderRadius.circular(height),
        child: SizedBox(
          height: height,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (flex(paid * t) > 0)
                Expanded(
                  flex: flex(paid * t),
                  child: ColoredBox(color: over ? overColor : paidColor),
                ),
              if (flex(paid * t) > 0 && flex(unpaid * t) > 0)
                const SizedBox(width: 3),
              if (flex(unpaid * t) > 0)
                Expanded(
                  flex: flex(unpaid * t),
                  child: ColoredBox(
                    color: over
                        ? overColor.withValues(alpha: 0.6)
                        : unpaidColor,
                  ),
                ),
              if (flex(scale - committed * t) > 0)
                Expanded(
                  flex: flex(scale - committed * t),
                  child: Container(
                    margin: const EdgeInsets.only(left: 3),
                    decoration: BoxDecoration(
                      border: Border.all(color: hatchColor, width: 1.2),
                      borderRadius: BorderRadius.horizontal(
                        right: Radius.circular(height),
                      ),
                    ),
                    child: CustomPaint(
                      painter: HatchPainter(
                        color: hatchColor,
                        gap: 6,
                        stroke: 1.5,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
