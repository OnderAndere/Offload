/// A calendar date without time or time zone, e.g. the deadline `!vr`
/// (DD-004): "Friday" is the same day wherever the device is.
class LocalDate implements Comparable<LocalDate> {
  /// Throws [ArgumentError] for a date that does not exist, e.g. 31-02.
  LocalDate(this.year, this.month, this.day) {
    final check = DateTime.utc(year, month, day);
    if (check.year != year || check.month != month || check.day != day) {
      throw ArgumentError('No such date: $year-$month-$day');
    }
  }

  /// The date of [moment] in its own time zone.
  factory LocalDate.of(DateTime moment) =>
      LocalDate(moment.year, moment.month, moment.day);

  /// Null when the date does not exist.
  static LocalDate? tryCreate(int year, int month, int day) {
    try {
      return LocalDate(year, month, day);
    } on ArgumentError {
      return null;
    }
  }

  final int year;
  final int month;
  final int day;

  /// Monday = 1 ... Sunday = 7, as [DateTime.weekday].
  int get weekday => _utc.weekday;

  DateTime get _utc => DateTime.utc(year, month, day);

  LocalDate addDays(int days) => LocalDate.of(_utc.add(Duration(days: days)));

  /// The Monday of this date's week (ISO 8601).
  LocalDate get monday => addDays(1 - weekday);

  /// The ISO 8601 week number, 1 to 53: the week that holds the Thursday
  /// of this date's week, counted from the week with the year's first
  /// Thursday.
  int get isoWeek {
    final thursday = addDays(4 - weekday);
    return thursday.daysSince(LocalDate(thursday.year, 1, 1)) ~/ 7 + 1;
  }

  /// Whole calendar days from [earlier] to this date; negative when
  /// [earlier] is later.
  int daysSince(LocalDate earlier) => _utc.difference(earlier._utc).inDays;

  /// Midnight at the start of this date, in local time.
  DateTime toLocalDateTime() => DateTime(year, month, day);

  @override
  int compareTo(LocalDate other) => _utc.compareTo(other._utc);

  @override
  bool operator ==(Object other) =>
      other is LocalDate &&
      other.year == year &&
      other.month == month &&
      other.day == day;

  @override
  int get hashCode => Object.hash(year, month, day);

  @override
  String toString() =>
      '$year-${month.toString().padLeft(2, '0')}-'
      '${day.toString().padLeft(2, '0')}';
}
