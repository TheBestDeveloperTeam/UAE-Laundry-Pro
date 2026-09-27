class Validators {
  /// Validates standard email format.
  static String? email(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  /// Validates a UAE Phone Number. Assumes +971 or 05x format.
  static String? uaePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }

    // Optional +971, then optional 0, then 5, then 8 digits
    final uaePhoneRegex = RegExp(r'^(?:\+971|00971|0)?(?:5[024568])\d{7}$');
    final stripped = value.replaceAll(RegExp(r'\s|-'), '');

    if (!uaePhoneRegex.hasMatch(stripped)) {
      return 'Please enter a valid UAE phone number';
    }
    return null;
  }

  /// Validates UAE TRN (Tax Registration Number), which is exactly 15 digits.
  static String? uaeTrn(String? value) {
    if (value == null || value.isEmpty) {
      return null; // TRN is usually optional
    }

    final trnRegex = RegExp(r'^\d{15}$');
    final stripped = value.replaceAll(RegExp(r'\s|-'), '');

    if (!trnRegex.hasMatch(stripped)) {
      return 'TRN must be exactly 15 digits';
    }
    return null;
  }

  /// Basic required field validator.
  static String? required(String? value, {String fieldName = 'Field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
