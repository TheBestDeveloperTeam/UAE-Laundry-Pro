import 'package:flutter/material.dart';
import 'package:laundrypro_uae/core/localization.dart';

extension LocalizationX on BuildContext {
  AppLocalization get l10n => Localizations.of<AppLocalization>(this, AppLocalization)!;
}
