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

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}
