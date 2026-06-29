import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../constants/colors.dart';

class DecibelGauge extends StatelessWidget {
  final double value;
  final bool isAnimating;

  const DecibelGauge({
    super.key,
    required this.value,
    this.isAnimating = false,
  });

  Color _getColor(double db) {
    if (db < 70) return safeColor;
    if (db < 85) return warningColor;
    return dangerColor;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      height: 300,
      child: CustomPaint(
        painter: DecibelGaugePainter(
          value: value.clamp(0.0, 130.0),
          color: _getColor(value),
          isAnimating: isAnimating,
        ),
      ),
    );
  }
}

class DecibelGaugePainter extends CustomPainter {
  final double value;
  final Color color;
  final bool isAnimating;

  DecibelGaugePainter({
    required this.value,
    required this.color,
    this.isAnimating = false,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2 - 20;

    // Background circle
    canvas.drawCircle(
      center,
      radius,
      Paint()
        ..color = Colors.grey[200]!
        ..style = PaintingStyle.fill,
    );

    // Status zones background
    _drawStatusZones(canvas, center, radius);

    // Needle
    _drawNeedle(canvas, center, radius);

    // Center circle
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = Colors.white
        ..style = PaintingStyle.fill,
    );
    canvas.drawCircle(
      center,
      15,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2,
    );

    // Scale and labels
    _drawScale(canvas, center, radius);

    // Value text
    _drawValueText(canvas, center, size);
  }

  void _drawStatusZones(Canvas canvas, Offset center, double radius) {
    // Safe zone (0-70)
    _drawArc(canvas, center, radius, 0, 70 / 130 * 180, safeColor.withOpacity(0.1));

    // Warning zone (70-85)
    _drawArc(
      canvas,
      center,
      radius,
      70 / 130 * 180,
      85 / 130 * 180,
      warningColor.withOpacity(0.1),
    );

    // Danger zone (85-130)
    _drawArc(
      canvas,
      center,
      radius,
      85 / 130 * 180,
      180,
      dangerColor.withOpacity(0.1),
    );
  }

  void _drawArc(
    Canvas canvas,
    Offset center,
    double radius,
    double startAngle,
    double endAngle,
    Color color,
  ) {
    final startRad = (startAngle - 90) * math.pi / 180;
    final endRad = (endAngle - 90) * math.pi / 180;

    final path = Path();
    path.moveTo(center.dx, center.dy);
    path.arcTo(
      Rect.fromCircle(center: center, radius: radius),
      startRad,
      endRad - startRad,
      false,
    );
    path.close();

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..style = PaintingStyle.fill,
    );
  }

  void _drawNeedle(Canvas canvas, Offset center, double radius) {
    final angle = (value / 130.0) * 180 - 90;
    final angleRad = angle * math.pi / 180;

    final needleLength = radius - 20;
    final endX = center.dx + needleLength * math.cos(angleRad);
    final endY = center.dy + needleLength * math.sin(angleRad);

    // Needle shadow
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = Colors.black.withOpacity(0.2)
        ..strokeWidth = 4,
    );

    // Needle
    canvas.drawLine(
      center,
      Offset(endX, endY),
      Paint()
        ..color = color
        ..strokeWidth = 3
        ..strokeCap = StrokeCap.round,
    );
  }

  void _drawScale(Canvas canvas, Offset center, double radius) {
    final paint = Paint()
      ..color = Colors.black
      ..strokeWidth = 2;

    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    // Major ticks and labels
    for (int i = 0; i <= 130; i += 10) {
      final angle = (i / 130.0) * 180 - 90;
      final angleRad = angle * math.pi / 180;

      final outerX = center.dx + radius * math.cos(angleRad);
      final outerY = center.dy + radius * math.sin(angleRad);

      final innerX = center.dx + (radius - 10) * math.cos(angleRad);
      final innerY = center.dy + (radius - 10) * math.sin(angleRad);

      canvas.drawLine(
        Offset(outerX, outerY),
        Offset(innerX, innerY),
        paint,
      );

      if (i % 20 == 0) {
        final labelX = center.dx + (radius - 25) * math.cos(angleRad);
        final labelY = center.dy + (radius - 25) * math.sin(angleRad);

        textPainter.text = TextSpan(
          text: '$i',
          style: const TextStyle(
            color: Colors.black,
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        );
        textPainter.layout();
        textPainter.paint(
          canvas,
          Offset(labelX - textPainter.width / 2, labelY - textPainter.height / 2),
        );
      }
    }
  }

  void _drawValueText(Canvas canvas, Offset center, Size size) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: value.toStringAsFixed(1),
        style: TextStyle(
          color: color,
          fontSize: 48,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(
        center.dx - textPainter.width / 2,
        center.dy + 30,
      ),
    );

    final unitPainter = TextPainter(
      text: const TextSpan(
        text: 'dB',
        style: TextStyle(
          color: Colors.black54,
          fontSize: 20,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    unitPainter.layout();
    unitPainter.paint(
      canvas,
      Offset(
        center.dx - unitPainter.width / 2,
        center.dy + 85,
      ),
    );
  }

  @override
  bool shouldRepaint(DecibelGaugePainter oldDelegate) {
    return oldDelegate.value != value ||
        oldDelegate.color != color ||
        oldDelegate.isAnimating != isAnimating;
  }
}
