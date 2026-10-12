import 'package:flutter/material.dart';

/// The Ethiopian birr symbol: the Ethiopic letter ብ (the first letter of
/// ብር, "birr") crossed by two short currency bars, drawn as vector strokes
/// so it stays crisp at any size. Same geometry as
/// `assets/brand/birr_icon.svg`.
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
    final k = size.shortestSide / 100;
    canvas.scale(k);
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

    // The arch of ብ: two legs joined by a round top.
    final arch = Path()
      ..moveTo(30, 83)
      ..lineTo(30, 37)
      ..arcToPoint(const Offset(70, 37), radius: const Radius.circular(20))
      ..lineTo(70, 83);
    canvas.drawPath(arch, heavy);
    // The stroke on the right leg that makes በ into ብ.
    canvas.drawLine(const Offset(70, 55), const Offset(90, 55), heavy);
    // Currency bars.
    canvas.drawLine(const Offset(12, 47), const Offset(44, 47), light);
    canvas.drawLine(const Offset(12, 61), const Offset(44, 61), light);
  }

  @override
  bool shouldRepaint(_BirrPainter old) => old.color != color;
}
