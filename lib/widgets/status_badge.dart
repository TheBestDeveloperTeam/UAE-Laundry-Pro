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

    switch (stage) {
      case OrderStage.received:
        fg = AppTokens.statusReceived;
        bg = AppTokens.statusBgReceived;
        break;
      case OrderStage.washing:
      case OrderStage.drying:
        fg = AppTokens.statusWashing;
        bg = AppTokens.statusBgWashing;
        break;
      case OrderStage.finishing:
        fg = AppTokens.statusFinishing;
        bg = AppTokens.statusBgFinishing;
        break;
      case OrderStage.ready:
      case OrderStage.delivered:
        fg = AppTokens.statusReady;
        bg = AppTokens.statusBgReady;
        break;
      case OrderStage.cancelled:
        fg = AppTokens.statusCancelled;
        bg = AppTokens.statusBgCancelled;
        break;
    }

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? AppTokens.space8 : AppTokens.space12,
        vertical: compact ? AppTokens.space2 : AppTokens.space4,
      ),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(AppTokens.radiusPill),
        border: Border.all(color: fg.withValues(alpha: 0.3), width: 1.0),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: fg,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: AppTokens.space6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                fontSize: compact ? 11 : 12,
                fontWeight: FontWeight.w600,
                color: fg,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
