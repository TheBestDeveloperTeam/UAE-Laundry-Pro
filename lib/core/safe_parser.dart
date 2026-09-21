class SafeParser {
  static int parseInt(dynamic value, [int defaultValue = 0]) {
    if (value == null) return defaultValue;
    if (value is int) return value;
    if (value is double) return value.toInt();
    if (value is String) {
      return int.tryParse(value) ?? double.tryParse(value)?.toInt() ?? defaultValue;
    }
    return defaultValue;
  }

  static double parseDouble(dynamic value, [double defaultValue = 0.0]) {
    if (value == null) return defaultValue;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) {
      return double.tryParse(value) ?? defaultValue;
    }
    return defaultValue;
  }

  static DateTime parseDateTime(dynamic value, {DateTime? fallback}) {
    final defaultTime = fallback ?? DateTime.now();
    if (value == null) return defaultTime;
    if (value is DateTime) return value;
    if (value is String) {
      return DateTime.tryParse(value) ?? defaultTime;
    }
    return defaultTime;
  }
}
