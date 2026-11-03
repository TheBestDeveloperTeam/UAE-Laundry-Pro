import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Interactive 3D Animated Glass Container with Matrix4 Tilt, Specular Sheen,
/// and Zero Minor Visual Defect Tolerance.
class Futuristic3dCard extends StatefulWidget {
  const Futuristic3dCard({
    super.key,
    required this.child,
    this.accentColor = const Color(0xFF00A896),
    this.borderRadius = 16.0,
    this.padding = const EdgeInsets.all(20.0),
    this.onTap,
    this.maxTilt = 0.08,
  });

  final Widget child;
  final Color accentColor;
  final double borderRadius;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final double maxTilt;

  @override
  State<Futuristic3dCard> createState() => _Futuristic3dCardState();
}

class _Futuristic3dCardState extends State<Futuristic3dCard>
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
      duration: const Duration(milliseconds: 1400),
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
      _tiltX = -normalizedY.clamp(-1.0, 1.0) * widget.maxTilt;
      _tiltY = normalizedX.clamp(-1.0, 1.0) * widget.maxTilt;
    });
  }

  void _onEnter(PointerEnterEvent event) {
    setState(() {
      _isHovered = true;
    });
    _sheenController.forward(from: 0.0);
  }

  void _onExit(PointerExitEvent event) {
    setState(() {
      _isHovered = false;
      _tiltX = 0.0;
      _tiltY = 0.0;
    });
    _sheenController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardSize = Size(constraints.maxWidth, constraints.maxHeight);

        return MouseRegion(
          cursor: widget.onTap != null
              ? SystemMouseCursors.click
              : SystemMouseCursors.basic,
          onEnter: _onEnter,
          onExit: _onExit,
          onHover: (event) => _onHover(event, cardSize),
          child: GestureDetector(
            onTap: widget.onTap,
            child: AnimatedBuilder(
              animation: _sheenController,
              builder: (context, _) {
                final matrix = Matrix4.identity()
                  ..setEntry(3, 2, 0.001) // 3D Perspective
                  ..rotateX(_tiltX)
                  ..rotateY(_tiltY);

                return Transform(
                  transform: matrix,
                  alignment: FractionalOffset.center,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOutCubic,
                    padding: widget.padding,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(widget.borderRadius),
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
                          offset: Offset(
                            _tiltY * 30,
                            _isHovered ? 8 + (_tiltX * -30) : 4,
                          ),
                        ),
                        const BoxShadow(
                          color: Color(0x04000000),
                          blurRadius: 4,
                          offset: Offset(0, 1),
                        ),
                      ],
                    ),
                    child: Stack(
                      children: [
                        widget.child,
                        // Kinetic specular sheen sweep on hover
                        if (_isHovered)
                          Positioned.fill(
                            child: IgnorePointer(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                    widget.borderRadius),
                                child: CustomPaint(
                                  painter: _SpecularSheenPainter(
                                    progress: _sheenController.value,
                                    sheenColor: widget.accentColor
                                        .withValues(alpha: 0.08),
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

class _SpecularSheenPainter extends CustomPainter {
  _SpecularSheenPainter({
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
      ..moveTo(dx - 50, 0)
      ..lineTo(dx + 30, 0)
      ..lineTo(dx - 30, height)
      ..lineTo(dx - 110, height)
      ..close();

    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          sheenColor,
          sheenColor.withValues(alpha: 0.2),
          Colors.transparent,
        ],
        stops: const [0.0, 0.4, 0.6, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, width, height));

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(_SpecularSheenPainter oldDelegate) {
    return oldDelegate.progress != progress;
  }
}

