import 'dart:ui' as ui;
import 'package:flutter/material.dart';

class InteractiveRevenueChart extends StatefulWidget {
  const InteractiveRevenueChart({
    super.key,
    this.onPointTap,
  });

  final void Function(int index, String day, double revenue)? onPointTap;

  @override
  State<InteractiveRevenueChart> createState() => _InteractiveRevenueChartState();
}

class _InteractiveRevenueChartState extends State<InteractiveRevenueChart> {
  int? _hoveredIndex;
  Offset? _mousePosition;

  final List<double> values = const [3000.0, 4800.0, 4200.0, 5800.0, 6200.0, 7500.0, 8400.0];
  final List<String> labels = const ['Sat', 'Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri'];
  final List<int> orderCounts = const [24, 38, 31, 45, 52, 60, 68];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final stepX = constraints.maxWidth / (values.length - 1);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onHover: (event) {
            final x = event.localPosition.dx;
            final nearestIndex = (x / stepX).round().clamp(0, values.length - 1);
            setState(() {
              _hoveredIndex = nearestIndex;
              _mousePosition = event.localPosition;
            });
          },
          onExit: (_) {
            setState(() {
              _hoveredIndex = null;
              _mousePosition = null;
            });
          },
          child: GestureDetector(
            onTap: () {
              if (_hoveredIndex != null) {
                widget.onPointTap?.call(
                  _hoveredIndex!,
                  labels[_hoveredIndex!],
                  values[_hoveredIndex!],
                );
              }
            },
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                CustomPaint(
                  size: Size(constraints.maxWidth, constraints.maxHeight),
                  painter: _InteractiveRevenueChartPainter(
                    values: values,
                    labels: labels,
                    hoveredIndex: _hoveredIndex,
                  ),
                ),
                if (_hoveredIndex != null)
                  _buildTooltipPill(constraints, stepX),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTooltipPill(BoxConstraints constraints, double stepX) {
    final idx = _hoveredIndex!;
    final day = labels[idx];
    final rev = values[idx];
    final orders = orderCounts[idx];

    const min = 0.0;
    const max = 12000.0;
    const range = max - min;
    final y = constraints.maxHeight - 24 - ((rev - min) / range * (constraints.maxHeight - 30));
    final x = (idx * stepX).clamp(70.0, constraints.maxWidth - 70.0);

    return Positioned(
      left: x - 65,
      top: (y - 56).clamp(0.0, constraints.maxHeight - 60.0),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: const [
            BoxShadow(color: Color(0x33000000), blurRadius: 10, offset: Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '$day • AED ${rev.toInt()}',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 11.5,
              ),
            ),
            const SizedBox(height: 1),
            Text(
              '$orders orders (Click to inspect)',
              style: const TextStyle(
                color: Color(0xFF02C39A),
                fontWeight: FontWeight.w600,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InteractiveRevenueChartPainter extends CustomPainter {
  _InteractiveRevenueChartPainter({
    required this.values,
    required this.labels,
    this.hoveredIndex,
  });

  final List<double> values;
  final List<String> labels;
  final int? hoveredIndex;

  @override
  void paint(Canvas canvas, Size size) {
    const min = 0.0;
    const max = 12000.0;
    const range = max - min;

    final stepX = size.width / (values.length - 1);
    final points = <Offset>[];

    // Grid lines (0, 4K, 8K, 12K)
    const gridStyle = TextStyle(fontFamily: 'Inter', color: Color(0xFF94A3B8), fontSize: 10.5);
    final gridLevels = [0.0, 4000.0, 8000.0, 12000.0];
    final gridPaint = Paint()
      ..color = const Color(0xFFF1F5F9)
      ..strokeWidth = 1.0;

    for (final lvl in gridLevels) {
      final y = size.height - 24 - ((lvl - min) / range * (size.height - 30));
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
      final label = lvl == 0.0 ? '0' : '${(lvl / 1000).toInt()}K';
      final tp = TextPainter(
        text: TextSpan(text: label, style: gridStyle),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(0, y - 12));
    }

    for (int i = 0; i < values.length; i++) {
      final x = i * stepX;
      final y = size.height - 24 - ((values[i] - min) / range * (size.height - 30));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    for (int i = 0; i < points.length - 1; i++) {
      final p0 = points[i];
      final p1 = points[i + 1];
      path.quadraticBezierTo(p0.dx, p0.dy, (p0.dx + p1.dx) / 2, (p0.dy + p1.dy) / 2);
    }
    path.lineTo(points.last.dx, points.last.dy);

    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height - 24)
      ..lineTo(0, size.height - 24)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFF02C39A).withOpacity(0.35),
          const Color(0xFF02C39A).withOpacity(0.0),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height - 24));

    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = const Color(0xFF02C39A)
      ..strokeWidth = 2.8
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // Draw active vertical indicator line if hovered
    if (hoveredIndex != null) {
      final activePoint = points[hoveredIndex!];
      final linePaint = Paint()
        ..color = const Color(0xFF00A896).withOpacity(0.4)
        ..strokeWidth = 1.5;
      canvas.drawLine(
        Offset(activePoint.dx, 0),
        Offset(activePoint.dx, size.height - 24),
        linePaint,
      );
    }

    for (int i = 0; i < points.length; i++) {
      final isHovered = hoveredIndex == i;
      final radius = isHovered ? 6.5 : 4.5;
      final innerRadius = isHovered ? 3.0 : 2.2;

      canvas.drawCircle(points[i], radius, Paint()..color = const Color(0xFF00A896));
      canvas.drawCircle(points[i], innerRadius, Paint()..color = Colors.white);
    }

    const textStyle = TextStyle(fontFamily: 'Inter', color: Color(0xFF64748B), fontSize: 11, fontWeight: FontWeight.w500);
    for (int i = 0; i < labels.length; i++) {
      final tp = TextPainter(
        text: TextSpan(
          text: labels[i],
          style: hoveredIndex == i
              ? textStyle.copyWith(color: const Color(0xFF00A896), fontWeight: FontWeight.bold)
              : textStyle,
        ),
        textDirection: ui.TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(i * stepX - (tp.width / 2), size.height - 14));
    }
  }

  @override
  bool shouldRepaint(covariant _InteractiveRevenueChartPainter oldDelegate) {
    return oldDelegate.hoveredIndex != hoveredIndex;
  }
}

