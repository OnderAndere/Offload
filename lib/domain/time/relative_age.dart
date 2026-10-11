import 'local_date.dart';

/// How long ago something happened, as a list row shows it (DD-018 point
/// 2): just now, minutes, hours today, yesterday, days up to a week, then
/// the date. The words come from the ARB files; this only picks the case.
sealed class RelativeAge {
  const RelativeAge();
}

/// Less than a minute ago, or a moment the clock puts in the future.
class JustNow extends RelativeAge {
  const JustNow();
}

/// 1–59 minutes ago.
class MinutesAgo extends RelativeAge {
  const MinutesAgo(this.minutes);

  final int minutes;
}

/// An hour or more ago, earlier today.
class HoursAgo extends RelativeAge {
  const HoursAgo(this.hours);

  final int hours;
}

/// The previous calendar day.
class Yesterday extends RelativeAge {
  const Yesterday();
}

/// 2–6 calendar days ago.
class DaysAgo extends RelativeAge {
  const DaysAgo(this.days);

  final int days;
}

/// A week or longer ago: the date itself.
class OnDate extends RelativeAge {
  const OnDate(this.date);

  final LocalDate date;
}

/// The age of [moment] at [now]; both in local time, so "yesterday" is the
/// calendar day before today on this device.
RelativeAge relativeAge(DateTime moment, DateTime now) {
  final elapsed = now.difference(moment);
  if (elapsed.inMinutes < 1) return const JustNow();
  if (elapsed.inMinutes < 60) return MinutesAgo(elapsed.inMinutes);
  final day = LocalDate.of(moment);
  final today = LocalDate.of(now);
  if (day == today) return HoursAgo(elapsed.inHours);
  // Counted in calendar days, so summer time does not shift the answer.
  final days = _dayNumber(today) - _dayNumber(day);
  if (days == 1) return const Yesterday();
  if (days < 7) return DaysAgo(days);
  return OnDate(day);
}

int _dayNumber(LocalDate date) =>
    DateTime.utc(date.year, date.month, date.day).millisecondsSinceEpoch ~/
    Duration.millisecondsPerDay;
