import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/errors/api_exception.dart';
import 'package:laundrypro_uae/core/localization_extension.dart';

class UIUtils {
  static void showError(BuildContext context, Object error) {
    String message;
    if (error is ApiException) {
      if (error.code == 'ERR_INSUFFICIENT_STOCK') {
         message = context.l10n.t('err_insufficient_stock');
      } else {
         message = context.l10n.t(error.messageKey);
      }
      // Fallback if localization key isn't found
      if (message == error.messageKey) {
        message = '${error.code}: $message';
      }
    } else {
      message = error.toString();
    }

    final theme = Theme.of(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: theme.colorScheme.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 4),
      ),
    );
  }

  static void showSuccess(BuildContext context, String messageKeyOrText) {
    final localized = context.l10n.t(messageKeyOrText);
    final display = localized != messageKeyOrText ? localized : messageKeyOrText;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFF10B981), // Emerald Success
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showWarning(BuildContext context, String messageKeyOrText) {
    final localized = context.l10n.t(messageKeyOrText);
    final display = localized != messageKeyOrText ? localized : messageKeyOrText;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFFF59E0B), // Amber Warning
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  static void showInfo(BuildContext context, String messageKeyOrText) {
    final localized = context.l10n.t(messageKeyOrText);
    final display = localized != messageKeyOrText ? localized : messageKeyOrText;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.info_outline, color: Colors.white, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(display, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w500))),
          ],
        ),
        backgroundColor: const Color(0xFF0284C7), // Sky Info
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
      ),
    );
  }
}
