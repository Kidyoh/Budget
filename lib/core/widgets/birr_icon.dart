import 'package:flutter/material.dart';

/// The Ethiopian birr symbol: the Ethiopic letter ብ (the first letter of
/// ብር, "birr"), drawn as vector strokes so it stays crisp at any size.
/// ብ is the arch of በ with a short stroke on the *left* leg; the same
/// stroke on the right leg would make ቡ. Same geometry as
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
    canvas.scale(size.shortestSide / 100);
    final pen = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 12
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    // The arch of በ: two legs joined by a round top.
    canvas.drawPath(
      Path()
        ..moveTo(42, 84)
        ..lineTo(42, 38)
        ..arcToPoint(const Offset(78, 38), radius: const Radius.circular(18))
        ..lineTo(78, 84),
      pen,
    );
    // The stroke on the left leg that makes በ into ብ, with its small
    // downward flick.
    canvas.drawPath(
      Path()
        ..moveTo(42, 59)
        ..lineTo(27, 59)
        ..quadraticBezierTo(22, 59, 20, 66),
      pen,
    );
  }

  @override
  bool shouldRepaint(_BirrPainter old) => old.color != color;
}
