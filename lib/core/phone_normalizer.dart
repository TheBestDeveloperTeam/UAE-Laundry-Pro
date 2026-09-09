class PhoneNormalizer {
  /// Normalizes UAE phone numbers to standard format (e.g. 0501234567).
  ///
  /// Handles:
  /// - `+971 50 123 4567` -> `0501234567`
  /// - `00971501234567`   -> `0501234567`
  /// - `971501234567`     -> `0501234567`
  /// - `050-123-4567`     -> `0501234567`
  /// - `501234567`        -> `0501234567`
  static String normalizeUaePhone(String raw) {
    // Strip all non-digit characters
    String digits = raw.replaceAll(RegExp(r'\D'), '');

    if (digits.isEmpty) {
      return '';
    }

    // Strip leading zeros if more than one (e.g. 00971 -> 971)
    if (digits.startsWith('00971')) {
      digits = digits.substring(2);
    }

    // Normalize 971 prefix to 0
    if (digits.startsWith('971')) {
      digits = '0${digits.substring(3)}';
    }

    // If starts with 5 (9 digits total), prepend 0 -> 05xxxxxxxx
    if (digits.length == 9 && digits.startsWith('5')) {
      digits = '0$digits';
    }

    return digits;
  }

  /// Calculates Levenshtein distance between two strings.
  /// Used for fuzzy matching and duplicate detection.
  static int levenshtein(String s, String t) {
    if (s == t) return 0;
    if (s.isEmpty) return t.length;
    if (t.isEmpty) return s.length;

    List<int> v0 = List<int>.filled(t.length + 1, 0);
    List<int> v1 = List<int>.filled(t.length + 1, 0);

    for (int i = 0; i < v0.length; i++) {
      v0[i] = i;
    }

    for (int i = 0; i < s.length; i++) {
      v1[0] = i + 1;

      for (int j = 0; j < t.length; j++) {
        int cost = (s.codeUnitAt(i) == t.codeUnitAt(j)) ? 0 : 1;
        v1[j + 1] = [
          v1[j] + 1,
          v0[j + 1] + 1,
          v0[j] + cost,
        ].reduce((curr, next) => curr < next ? curr : next);
      }

      for (int j = 0; j < v0.length; j++) {
        v0[j] = v1[j];
      }
    }

    return v1[t.length];
  }
}
