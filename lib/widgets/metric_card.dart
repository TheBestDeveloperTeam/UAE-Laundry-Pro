import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

/// Royal Futuristic KPI Metric Card with Matrix4 3D Tilt, Kinetic Specular Sheen,
/// Bezier Sparklines & Zero Minor Visual Defect Tolerance.
class MetricCard extends StatefulWidget {
  const MetricCard({
    super.key,
    required this.title,
    required this.value,
    required this.subtitle,
    required this.icon,
    required this.accentColor,
    this.badgeText,
    this.isPositive = true,
    this.sparklinePoints,
    this.onTap,
  });

  final String title;
  final String value;
  final String subtitle;
  final IconData icon;
  final Color accentColor;
  final String? badgeText;
  final bool isPositive;
  final List<double>? sparklinePoints;
  final VoidCallback? onTap;

  @override
  State<MetricCard> createState() => _MetricCardState();
}

class _MetricCardState extends State<MetricCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _sheenController;
  double _tiltX = 0.0;
  double _tiltY = 0.0;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();
    _sheenController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
  }

  @override
  void dispose() {
    _sheenController.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent event, Size size) {
    if (size.width == 0 || size.height == 0) return;
    final center = Offset(size.width / 2, size.height / 2);
    final normalizedX = (event.localPosition.dx - center.dx) / (size.width / 2);
    final normalizedY = (event.localPosition.dy - center.dy) / (size.height / 2);

    setState(() {
      _tiltX = -normalizedY.clamp(-1.0, 1.0) * 0.06;
      _tiltY = normalizedX.clamp(-1.0, 1.0) * 0.06;
    });
  }

  @override
  Widget build(BuildContext context) {
    final effectivePoints = widget.sparklinePoints ?? const [12, 16, 14, 22, 29, 36, 45];

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          cursor: widget.onTap != null ? SystemMouseCursors.click : SystemMouseCursors.basic,
          onEnter: (_) {
            setState(() => _isHovered = true);
            _sheenController.forward(from: 0.0);
          },
          onExit: (_) {
            setState(() {
              _isHovered = false;
              _tiltX = 0.0;
              _tiltY = 0.0;
            });
            _sheenController.reverse();
          },
          onHover: (event) => _onHover(event, cardSize),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _sheenController,
              builder: (context, _) {
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.001)
                  ..rotateX(_tiltX)
                  ..rotateY(_tiltY);

                return Transform(
                  transform: matrix,
                  alignment: FractionalOffset.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16.0),
                      border: Border.all(
                        color: _isHovered
                            ? widget.accentColor.withValues(alpha: 0.45)
                            : const Color(0xFFE5EBF2),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: _isHovered
                              ? widget.accentColor.withValues(alpha: 0.14)
                              : const Color(0x0A0B192C),
                          blurRadius: _isHovered ? 26 : 14,
                          offset: Offset(_tiltY * 30, _isHovered ? 8 + (_tiltX * -30) : 4),
                        ),
                        const BoxShadow(
                          color: Color(0x05000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            // Top Row: Vector Icon Container & Title
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Container(
                                  width: 38,
                                  height: 38,
                                  decoration: BoxDecoration(
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        widget.accentColor.withValues(alpha: 0.16),
                                        widget.accentColor.withValues(alpha: 0.06),
                                      ],
                                    ),
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: widget.accentColor.withValues(alpha: 0.25),
                                      width: 1.0,
                                    ),
                                  ),
                                  child: Center(
                                    child: Icon(
                                      widget.icon,
                                      color: widget.accentColor,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: AppTokens.space12),
                                Expanded(
                                  child: Text(
                                    widget.title,
                                    textAlign: TextAlign.end,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: Color(0xFF475569),
                                      letterSpacing: -0.1,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),

                            // Middle Row: Hero Metric Figure & Vector Sparkline Area
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.end,
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.value,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 27,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: -0.8,
                                      color: Color(0xFF0F172A),
                                      fontFeatures: [FontFeature.tabularFigures()],
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 88,
                                  height: 36,
                                  child: CustomPaint(
                                    painter: _FuturisticSparklinePainter(
                                      points: effectivePoints,
                                      color: widget.accentColor,
                                      isHovered: _isHovered,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),

                            // Bottom Row: Trend Badge / Subtitle Context
                            Row(
                              children: [
                                if (widget.badgeText != null) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: widget.isPositive
                                          ? const Color(0xFFE6F7F5)
                                          : const Color(0xFFFEF2F2),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          widget.isPositive ? Icons.trending_up_rounded : Icons.trending_down_rounded,
                                          size: 13,
                                          color: widget.isPositive ? const Color(0xFF00A896) : const Color(0xFFEF4444),
                                        ),
                                        const SizedBox(width: 3),
                                        Text(
                                          widget.badgeText!,
                                          style: TextStyle(
                                            fontFamily: 'Inter',
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w700,
                                            color: widget.isPositive ? const Color(0xFF00A896) : const Color(0xFFEF4444),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                Expanded(
                                  child: Text(
                                    widget.subtitle,
                                    style: const TextStyle(
                                      fontFamily: 'Inter',
                                      fontSize: 12,
                                      color: Color(0xFF94A3B8),
                                      fontWeight: FontWeight.w500,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),

                        // Kinetic Specular Sheen Overlay
                        if (_isHovered)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16.0),
                                child: CustomPaint(
                                  painter: _CardSpecularSheenPainter(
                                    progress: _sheenController.value,
                                    sheenColor: widget.accentColor.withValues(alpha: 0.12),
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}

class _CardSpecularSheenPainter extends CustomPainter {
  _CardSpecularSheenPainter({
    required this.progress,
    required this.sheenColor,
  });

  final double progress;
  final Color sheenColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (progress <= 0 || progress >= 1.0) return;
    final width = size.width;
    final height = size.height;
    final dx = (width * 1.8) * progress - (width * 0.4);

    final path = Path()
      ..moveTo(dx - 40, 0)
      ..lineTo(dx + 25, 0)
      ..lineTo(dx - 25, height)
      ..lineTo(dx - 90, height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          sheenColor,
          sheenColor.withValues(alpha: 0.25),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_CardSpecularSheenPainter oldDelegate) => oldDelegate.progress != progress;
}

class _FuturisticSparklinePainter extends CustomPainter {
  _FuturisticSparklinePainter({
    required this.points,
    required this.color,
    required this.isHovered,
  });

  final List<double> points;
  final Color color;
  final bool isHovered;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final minVal = points.reduce(math.min);
    final maxVal = points.reduce(math.max);
    final range = (maxVal - minVal) == 0 ? 1.0 : (maxVal - minVal);

    final stepX = size.width / (points.length - 1);
    final path = Path();
    final fillPath = Path();

    final offsets = <Offset>[];
    for (int i = 0; i < points.length; i++) {
      final x = i * stepX;
      final y = size.height - ((points[i] - minVal) / range * (size.height - 8)) - 4;
      offsets.add(Offset(x, y));
    }

    path.moveTo(offsets.first.dx, offsets.first.dy);
    fillPath.moveTo(offsets.first.dx, size.height);
    fillPath.lineTo(offsets.first.dx, offsets.first.dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.quadraticBezierTo(p0.dx, p0.dy, controlX, (p0.dy + p1.dy) / 2);
      fillPath.quadraticBezierTo(p0.dx, p0.dy, controlX, (p0.dy + p1.dy) / 2);
    }

    path.lineTo(offsets.last.dx, offsets.last.dy);
    fillPath.lineTo(offsets.last.dx, offsets.last.dy);
    fillPath.lineTo(offsets.last.dx, size.height);
    fillPath.close();

    // Ambient gradient fill under the sparkline curve
    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: isHovered ? 0.35 : 0.18),
          color.withValues(alpha: 0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    canvas.drawPath(fillPath, fillPaint);

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = isHovered ? 2.5 : 2.0
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, linePaint);

    // Endpoint Indicator Ring
    final lastPoint = offsets.last;
    canvas.drawCircle(
      lastPoint,
      isHovered ? 4.5 : 3.5,
      Paint()..color = color,
    );
    canvas.drawCircle(
      lastPoint,
      isHovered ? 2.2 : 1.6,
      Paint()..color = Colors.white,
    );
  }

  @override
  bool shouldRepaint(_FuturisticSparklinePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.color != color ||
        oldDelegate.isHovered != isHovered;
  }
}
