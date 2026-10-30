import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';

class HardwareStatusBar extends StatelessWidget {
  const HardwareStatusBar({
    super.key,
    required this.isDbConnected,
    required this.isPrinterReady,
    required this.isScannerReady,
    required this.lastSyncTime,
    required this.version,
  });

  final bool isDbConnected;
  final bool isPrinterReady;
  final bool isScannerReady;
  final String lastSyncTime;
  final String version;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: AppTokens.space16),
      decoration: const BoxDecoration(
        color: AppTokens.surfacePrimary,
        border: Border(top: BorderSide(color: AppTokens.borderSubtle, width: 1.0)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildIndicator(
                isOk: isDbConnected,
                okLabel: 'Local database connected',
                errLabel: 'Database disconnected',
              ),
              const SizedBox(width: AppTokens.space16),
              _buildIndicator(
                isOk: isPrinterReady,
                okLabel: 'Printer ready',
                errLabel: 'Printer offline',
              ),
              const SizedBox(width: AppTokens.space16),
              _buildIndicator(
                isOk: isScannerReady,
                okLabel: 'Scanner ready',
                errLabel: 'Scanner inactive',
              ),
            ],
          ),
          Row(
            children: [
              const Icon(Icons.sync_rounded, size: 14, color: AppTokens.textMuted),
              const SizedBox(width: AppTokens.space4),
              Text(
                'Last sync: $lastSyncTime',
                style: const TextStyle(fontSize: 11, color: AppTokens.textMuted),
              ),
              const SizedBox(width: AppTokens.space16),
              Text(
                version,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTokens.textMuted,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildIndicator({required bool isOk, required String okLabel, required String errLabel}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(
            color: isOk ? AppTokens.statusReady : AppTokens.statusCancelled,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: AppTokens.space6),
        Text(
          isOk ? okLabel : errLabel,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isOk ? AppTokens.textSecondary : AppTokens.statusCancelled,
          ),
        ),
      ],
    );
  }
}

