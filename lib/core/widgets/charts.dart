import 'dart:math' as math;

import 'package:flutter/material.dart';

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
