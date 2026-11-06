import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Royal Futuristic Animated Vector Empty State Emblem.
/// Pure Flutter custom math drawing with subtle breathing pulse.
class EmptyStateVectorEmblem extends StatefulWidget {
  const EmptyStateVectorEmblem({
    super.key,
    this.size = 80.0,
    this.accentColor = const Color(0xFF00A896),
    this.iconData = Icons.inbox_outlined,
  });

  final double size;
  final Color accentColor;
  final IconData iconData;

  @override
  State<EmptyStateVectorEmblem> createState() => _EmptyStateVectorEmblemState();
}

class _EmptyStateVectorEmblemState extends State<EmptyStateVectorEmblem>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseController,
      builder: (context, _) {
        final scale = 1.0 + (_pulseController.value * 0.05);

        return Transform.scale(
          scale: scale,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CustomPaint(
                  size: Size(widget.size, widget.size),
                  painter: _EmblemRingsPainter(
                    accentColor: widget.accentColor,
                    pulseProgress: _pulseController.value,
                  ),
                ),
                Container(
                  width: widget.size * 0.62,
                  height: widget.size * 0.62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        widget.accentColor.withValues(alpha: 0.18),
                        widget.accentColor.withValues(alpha: 0.06),
                      ],
                    ),
                    border: Border.all(
                      color: widget.accentColor.withValues(alpha: 0.35),
                      width: 1.2,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      widget.iconData,
                      size: widget.size * 0.32,
                      color: widget.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _EmblemRingsPainter extends CustomPainter {
  _EmblemRingsPainter({
    required this.accentColor,
    required this.pulseProgress,
  });

  final Color accentColor;
  final double pulseProgress;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final baseRadius = size.width / 2;

    // Outer subtle expanding ring
    final outerPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.06 + (pulseProgress * 0.06))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, baseRadius * 0.95, outerPaint);

    // Orbiting dashed vector arcs
    final arcPaint = Paint()
      ..color = accentColor.withValues(alpha: 0.25)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final angleOffset = pulseProgress * math.pi;
    final arcRect = Rect.fromCircle(center: center, radius: baseRadius * 0.78);
    canvas.drawArc(arcRect, angleOffset, 1.2, false, arcPaint);
    canvas.drawArc(arcRect, angleOffset + math.pi, 1.2, false, arcPaint);
  }

  @override
  bool shouldRepaint(_EmblemRingsPainter oldDelegate) {
    return oldDelegate.pulseProgress != pulseProgress;
  }
}

