import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

enum OrderStage { received, washing, drying, finishing, ready, delivered, cancelled }

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.stage,
    this.compact = false,
  });

  final String label;
  final OrderStage stage;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    Color fg;
    Color bg;
    Color dotColor;

    switch (stage) {
      case OrderStage.received:
        fg = const Color(0xFF00A896);
        bg = const Color(0xFFE6F7F5);
        dotColor = const Color(0xFF00A896);
        break;
      case OrderStage.washing:
      case OrderStage.drying:
        fg = const Color(0xFF2563EB);
        bg = const Color(0xFFEFF6FF);
        dotColor = const Color(0xFF3B82F6);
        break;
      case OrderStage.finishing:
        fg = const Color(0xFFD97706);
        bg = const Color(0xFFFFFBEB);
        dotColor = const Color(0xFFF59E0B);
        break;
      case OrderStage.ready:
      case OrderStage.delivered:
        fg = const Color(0xFF059669);
        bg = const Color(0xFFECFDF5);
        dotColor = const Color(0xFF10B981);
        break;
      case OrderStage.cancelled:
        fg = const Color(0xFFDC2626);
        bg = const Color(0xFFFEF2F2);
        dotColor = const Color(0xFFEF4444);
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8.0 : 10.0,
        vertical: compact ? 3.0 : 4.0,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(
          color: fg.withValues(alpha: 0.22),
          width: 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 5.5,
            height: 5.5,
            decoration: BoxDecoration(
              color: dotColor,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5.0),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontFamily: 'Inter',
                fontSize: compact ? 11.0 : 12.0,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: -0.1,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
