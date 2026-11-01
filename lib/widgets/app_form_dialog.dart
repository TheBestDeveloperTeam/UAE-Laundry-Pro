import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/design_system/app_tokens.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';

class AppFormDialog extends StatelessWidget {
  final String title;
  final Widget content;
  final VoidCallback onSave;
  final VoidCallback? onCancel;
  final bool isLoading;
  final String? errorText;

  AppFormDialog({
    super.key,
    required this.title,
    required this.content,
    VoidCallback? onSave,
    VoidCallback? onSuccess,
    this.onCancel,
    this.isLoading = false,
    this.errorText,
  }) : onSave = onSave ?? onSuccess ?? (() {});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppTokens.surfacePrimary,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusLarge)),
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(AppTokens.space24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: AppTokens.sectionHeading),
            const SizedBox(height: AppTokens.space16),
            if (errorText != null) ...[
              Container(
                padding: const EdgeInsets.all(AppTokens.space12),
                decoration: BoxDecoration(
                  color: AppTokens.statusBgCancelled,
                  borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
                  border: Border.all(color: AppTokens.statusCancelled.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppTokens.statusCancelled, size: 20),
                    const SizedBox(width: AppTokens.space8),
                    Expanded(
                      child: Text(
                        errorText!,
                        style: const TextStyle(color: AppTokens.statusCancelled, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppTokens.space16),
            ],
            Flexible(child: SingleChildScrollView(child: content)),
            const SizedBox(height: AppTokens.space24),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: isLoading ? null : (onCancel ?? () => Navigator.of(context).pop()),
                  child: Text(context.l10n.t('cancel'), style: const TextStyle(color: AppTokens.textSecondary)),
                ),
                const SizedBox(width: AppTokens.space12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTokens.brandTeal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTokens.radiusMedium)),
                  ),
                  onPressed: isLoading ? null : onSave,
                  child: isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(context.l10n.t('save'), style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
