class AppDateUtils {
  /// Returns whether a given date is a weekend in the UAE (Saturday or Sunday).
  static bool isUaeWeekend(DateTime date) {
    // DateTime.saturday is 6, DateTime.sunday is 7
    return date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
  }

  /// Calculates business days between two dates, excluding UAE weekends.
  static int getBusinessDays(DateTime start, DateTime end) {
    if (start.isAfter(end)) {
      return 0;
    }

    int businessDays = 0;
    DateTime current = start;

    while (current.isBefore(end) || current.isAtSameMomentAs(end)) {
      if (!isUaeWeekend(current)) {
        businessDays++;
      }
      current = current.add(const Duration(days: 1));
    }

    return businessDays;
  }

  /// Helper to calculate overtime hours. Assuming standard 8 hours a day.
  static double calculateOvertimeHours(DateTime checkIn, DateTime checkOut, {int standardHours = 8}) {
    final duration = checkOut.difference(checkIn);
    final hoursWorked = duration.inMinutes / 60.0;

    if (hoursWorked > standardHours) {
      return hoursWorked - standardHours;
    }
    return 0.0;
  }
}
