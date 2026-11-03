import 'package:flutter/material.dart';

/// Pure Vector Custom-Painted Brand Lockup Emblem for LaundryPro UAE.
/// Zero raster graphics; mathematically drawn Bézier arches, wash spiral, and luxury star.
class BrandVectorEmblem extends StatelessWidget {
  const BrandVectorEmblem({
    super.key,
    this.size = 36.0,
    this.primaryColor = const Color(0xFF00A896),
    this.accentColor = const Color(0xFF02C39A),
    this.goldColor = const Color(0xFFD4AF37),
  });

  final double size;
  final Color primaryColor;
  final Color accentColor;
  final Color goldColor;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _BrandVectorPainter(
          primaryColor: primaryColor,
          accentColor: accentColor,
          goldColor: goldColor,
        ),
      ),
    );
  }
}

class _BrandVectorPainter extends CustomPainter {
  _BrandVectorPainter({
    required this.primaryColor,
    required this.accentColor,
    required this.goldColor,
  });

  final Color primaryColor;
  final Color accentColor;
  final Color goldColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer squircle container
    final rrect = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Radius.circular(size.width * 0.28),
    );

    final bgPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [primaryColor, accentColor],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawRRect(rrect, bgPaint);

    // Subtle outer border highlight
    final borderPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0
      ..color = Colors.white.withValues(alpha: 0.35);
    canvas.drawRRect(rrect, borderPaint);

    // Inner Washing Vortex Vector Path
    final vortexPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.08
      ..strokeCap = StrokeCap.round
      ..color = Colors.white;

    final arcRect1 = Rect.fromCircle(center: center, radius: radius * 0.55);
    canvas.drawArc(arcRect1, -0.6, 4.2, false, vortexPaint);

    final arcRect2 = Rect.fromCircle(center: center, radius: radius * 0.32);
    final vortexPaint2 = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.07
      ..strokeCap = StrokeCap.round
      ..color = Colors.white.withValues(alpha: 0.85);
    canvas.drawArc(arcRect2, 1.2, 3.8, false, vortexPaint2);

    // Center Gold Core Star/Dot (Symbolizing Royal UAE Quality)
    final goldPaint = Paint()..color = goldColor;
    canvas.drawCircle(center, radius * 0.14, goldPaint);
  }

  @override
  bool shouldRepaint(_BrandVectorPainter oldDelegate) => false;
}

