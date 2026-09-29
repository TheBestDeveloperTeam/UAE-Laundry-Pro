import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/theme.dart';

enum AppStatus { draft, confirmed, processing, ready, delivered, paid, pending, cancelled, failed }

class StatusBadge extends StatelessWidget {
  final AppStatus status;
  final String label;

  const StatusBadge({super.key, required this.status, required this.label});

  Color _getColor() {
    switch (status) {
      case AppStatus.confirmed:
      case AppStatus.paid:
      case AppStatus.ready:
      case AppStatus.delivered:
        return AppTheme.success;
      case AppStatus.processing:
        return AppTheme.info;
      case AppStatus.draft:
      case AppStatus.pending:
        return AppTheme.pending;
      case AppStatus.cancelled:
        return AppTheme.warning;
      case AppStatus.failed:
        return AppTheme.danger;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getColor();
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.bold,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
