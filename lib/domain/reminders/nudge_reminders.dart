import '../items/item.dart';
import '../items/nudge.dart';
import '../time/local_date.dart';
import 'day_reminders.dart';

/// The nudge notification of one day (AC REQ-047, T10.1, decision c): its
/// own, for the waiting items that become silent that day.
class NudgeDay {
  const NudgeDay({required this.day, required this.at, required this.itemIds});

  final LocalDate day;

  /// When it comes, in local time.
  final DateTime at;

  /// The items becoming silent that day, in the order of capture.
  final List<String> itemIds;

  /// A stable number, apart from the other reminders: `3yyyymmdd`.
  int get id =>
      nudgeReminderIdOffset + day.year * 10000 + day.month * 100 + day.day;
}

/// Where the ids of the nudge reminders start (`3yyyymmdd`).
const nudgeReminderIdOffset = 300000000;

/// The nudges for [items] from [now] (local time): one notification on
/// the day an item becomes silent ([silentFrom]), at [minuteOfDay], from
/// today up to [reminderDaysAhead] ahead. Never a repeat: an item silent
/// before today, or whose time today has passed, is only on *Today*. A
/// touch (*Chased*) moves the day, so the plan that follows nudges again
/// [afterDays] later.
List<NudgeDay> planNudgeReminders(
  Iterable<Item> items, {
  required DateTime now,
  required int minuteOfDay,
  required int afterDays,
}) {
  final today = LocalDate.of(now);
  final last = today.addDays(reminderDaysAhead);
  final byDay = <LocalDate, List<String>>{};
  for (final item in items) {
    final day = silentFrom(item, afterDays);
    if (day == null || day.compareTo(today) < 0 || day.compareTo(last) > 0) {
      continue;
    }
    (byDay[day] ??= []).add(item.id);
  }
  final days = byDay.keys.toList()..sort();
  return [
    for (final day in days)
      if (DateTime(
            day.year,
            day.month,
            day.day,
            minuteOfDay ~/ 60,
            minuteOfDay % 60,
          )
          case final at when at.isAfter(now))
        NudgeDay(
          day: day,
          at: at,
          // UUIDv7 ids sort by the moment of capture.
          itemIds: byDay[day]!..sort(),
        ),
  ];
}
