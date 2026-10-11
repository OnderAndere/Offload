import '../time/local_date.dart';

/// A person's birthday (REQ-031, DD-012): day and month, the year
/// optional. Without a year 29 February is allowed; with one the date must
/// exist.
class Birthday {
  const Birthday._(this.day, this.month, this.year);

  /// The birthday, or null when it cannot exist: a month outside 1–12, a
  /// day the month never has, or (with [year]) a date that year lacks.
  static Birthday? tryCreate(int day, int month, [int? year]) {
    if (month < 1 || month > 12 || day < 1) return null;
    // A leap year gives every month its longest length.
    if (LocalDate.tryCreate(year ?? 2000, month, day) == null) return null;
    if (year != null && (year < 1 || year > 9999)) return null;
    return Birthday._(day, month, year);
  }

  final int day;
  final int month;
  final int? year;

  /// The age reached on [today], or null without a year or before birth.
  int? ageOn(LocalDate today) {
    final year = this.year;
    if (year == null) return null;
    final hadBirthday =
        today.month > month || (today.month == month && today.day >= day);
    final age = today.year - year - (hadBirthday ? 0 : 1);
    return age < 0 ? null : age;
  }

  /// A date to format: the birthday in [year], or for one without a year
  /// in a leap year, so 29 February still exists.
  LocalDate get displayDate => LocalDate(year ?? 2000, month, day);

  @override
  bool operator ==(Object other) =>
      other is Birthday &&
      other.day == day &&
      other.month == month &&
      other.year == year;

  @override
  int get hashCode => Object.hash(day, month, year);
}
