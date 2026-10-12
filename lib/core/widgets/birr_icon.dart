import 'package:flutter/material.dart';

/// The Ethiopian birr symbol: the Ethiopic letter ብ (the first letter of
/// ብር, "birr") with two currency bars, drawn as vector strokes so it stays
/// crisp at any size. The short stroke on the left leg makes በ into ብ; the
/// bars sit on the right. Same geometry as `assets/brand/birr_icon.svg`.
class BirrIcon extends StatelessWidget {
  const BirrIcon({super.key, this.size = 24, this.color});

  final double size;

  /// Defaults to the surrounding icon colour.
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    return Semantics(
      label: 'Birr',
      child: SizedBox.square(
        dimension: size,
        child: CustomPaint(
          painter: _BirrPainter(color ?? iconTheme.color ?? Colors.black),
        ),
      ),
    );
  }
}

class _BirrPainter extends CustomPainter {
  _BirrPainter(this.color);

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    // Drawn in a 100x100 box, scaled to fit.
    canvas.scale(size.shortestSide / 100);
    final heavy = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 11.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    final light = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round;

    // The arch of በ: two legs joined by a round top.
    canvas.drawPath(
      Path()
        ..moveTo(30, 83)
        ..lineTo(30, 37)
        ..arcToPoint(const Offset(70, 37), radius: const Radius.circular(20))
        ..lineTo(70, 83),
      heavy,
    );
    // The stroke on the left leg that makes በ into ብ.
    canvas.drawLine(const Offset(30, 55), const Offset(10, 55), heavy);
    // Currency bars across the right leg.
    canvas.drawLine(const Offset(56, 47), const Offset(88, 47), light);
    canvas.drawLine(const Offset(56, 61), const Offset(88, 61), light);
  }

  @override
  bool shouldRepaint(_BirrPainter old) => old.color != color;
}
