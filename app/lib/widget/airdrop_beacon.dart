import 'dart:math' as math;
import 'package:flutter/material.dart';

/// An AirDrop-style radar broadcast beacon painter and widget matching the exact
/// visual representation in 1791387024910.jpg.
/// It consists of 3 concentric broadcast wave arcs/rings and a center device pointer/dot.
class AirDropBeacon extends StatelessWidget {
  final double size;
  final Color? color;

  const AirDropBeacon({
    super.key,
    this.size = 200,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final beaconColor = color ?? const Color(0xFF357AF6);

    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _AirDropBeaconPainter(color: beaconColor),
      ),
    );
  }
}

class _AirDropBeaconPainter extends CustomPainter {
  final Color color;

  _AirDropBeaconPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.42);
    final baseRadius = size.width * 0.42;

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Line thickness proportional to size
    final strokeWidth = size.width * 0.052;
    strokePaint.strokeWidth = strokeWidth;

    // Three concentric broadcast wave arcs opening downwards
    final arcRadii = [
      baseRadius,
      baseRadius * 0.73,
      baseRadius * 0.46,
    ];

    const sweepAngle = math.pi * 1.34; // ~241 degrees
    const startAngle = -math.pi / 2 - sweepAngle / 2; // centered at top

    for (final r in arcRadii) {
      final rect = Rect.fromCircle(center: center, radius: r);
      canvas.drawArc(rect, startAngle, sweepAngle, false, strokePaint);
    }

    // Center circular emitter node
    final centerDotRadius = size.width * 0.12;
    canvas.drawCircle(center, centerDotRadius, fillPaint);

    // Bottom pointer / rounded triangular device indicator
    // Positioned below the center dot, pointing upwards towards the waves
    final triangleTop = Offset(center.dx, center.dy + size.height * 0.16);
    final triangleBottomLeft = Offset(center.dx - size.width * 0.16, center.dy + size.height * 0.45);
    final triangleBottomRight = Offset(center.dx + size.width * 0.16, center.dy + size.height * 0.45);

    // Smoother rounded triangle for the base pointer
    final rpath = Path()
      ..moveTo(triangleTop.dx, triangleTop.dy + 4)
      ..lineTo(triangleBottomRight.dx - 4, triangleBottomRight.dy - 2)
      ..quadraticBezierTo(
        triangleBottomRight.dx,
        triangleBottomRight.dy + 6,
        triangleBottomRight.dx - 8,
        triangleBottomRight.dy + 6,
      )
      ..lineTo(triangleBottomLeft.dx + 8, triangleBottomLeft.dy + 6)
      ..quadraticBezierTo(
        triangleBottomLeft.dx,
        triangleBottomLeft.dy + 6,
        triangleBottomLeft.dx + 4,
        triangleBottomLeft.dy - 2,
      )
      ..close();

    canvas.drawPath(rpath, fillPaint);
  }

  @override
  bool shouldRepaint(covariant _AirDropBeaconPainter oldDelegate) =>
      oldDelegate.color != color;
}
