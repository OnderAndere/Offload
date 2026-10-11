import '../items/item.dart';
import '../items/item_enums.dart';
import '../items/revisit.dart';
import '../items/today.dart';
import '../repeats/repeat.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';

/// The time of day the day's reminder comes (SPEC Q24, DD-005): minutes
/// after local midnight. A setting of this device.
abstract final class ReminderTime {
  /// 09:00.
  static const standard = 9 * 60;
  static const _lastMinute = 24 * 60 - 1;

  /// The stored value, or [fallback] ([standard] unless given) for a
  /// missing or unknown one.
  static int parse(String? stored, {int fallback = standard}) {
    final minutes = int.tryParse(stored ?? '');
    return minutes != null && minutes >= 0 && minutes <= _lastMinute
        ? minutes
        : fallback;
  }
}

/// How far ahead reminders are planned (DD-005): the set is planned again
/// at every start and change, so a month is plenty.
const reminderDaysAhead = 30;

/// One day with something to remind of: one notification (DD-005), at
/// [at], for the deadlines of that day and the items back from "revisit
/// on" (DD-018 point 17).
class ReminderDay {
  const ReminderDay({
    required this.day,
    required this.at,
    this.deadlineIds = const [],
    this.returningIds = const [],
  });

  /// The day of the deadlines and returns.
  final LocalDate day;

  /// When the notification comes, in local time.
  final DateTime at;

  /// The open items due that day, in the order they were captured.
  final List<String> deadlineIds;

  /// The items coming back to the inbox that day ("revisit on"), in the
  /// order they were captured; an item due that day too is a deadline only.
  final List<String> returningIds;

  /// Every item of the notification: deadlines first.
  List<String> get itemIds => [...deadlineIds, ...returningIds];

  /// A stable number for this day's notification, so a new plan replaces
  /// it rather than adding one: `yyyymmdd`.
  int get id => day.year * 10000 + day.month * 100 + day.day;
}

/// The reminders for [items] from [now] (local time; REQ-020, REQ-021,
/// DD-005, DD-018 points 16 and 17): per day one reminder at [minuteOfDay],
/// for the days from today up to [reminderDaysAhead] ahead, with
/// - the open items due that day ([isOpen]). A deadline is a date, stored
///   as midnight UTC (DD-004 point 8), so its day is that UTC date,
///   wherever the device is;
/// - the items coming back that day: parked ones (scheduled) with that
///   revisit date, and on today also those that came back already and are
///   still in the inbox (the app returns them at start, before the time).
///
/// A day whose time has passed gets none: overdue and returned items are
/// on *Today*, never reminded again. A repeating task ([repeats], REQ-061)
/// is the exception: it is also a deadline on every later date of its
/// series in the plan, so a missed daily task still gets its line every
/// day (DD-005).
List<ReminderDay> planDayReminders(
  Iterable<Item> items, {
  required DateTime now,
  required int minuteOfDay,
  Map<String, ItemRepeat> repeats = const {},
}) {
  final today = LocalDate.of(now);
  final last = today.addDays(reminderDaysAhead);
  bool inPlan(LocalDate day) =>
      day.compareTo(today) >= 0 && day.compareTo(last) <= 0;
  final due = <LocalDate, List<String>>{};
  final back = <LocalDate, List<String>>{};
  final dueOn = <(String, LocalDate)>{};
  for (final item in items) {
    final dueAt = item.dueAt;
    if (dueAt == null || !isOpen(item.status)) continue;
    final day = storedToDateOnly(dueAt);
    final repeat = repeats[item.id];
    final series = repeat != null && repeatsAs(item.type)
        ? seriesDatesBetween(repeat.anchor, repeat.rhythm, day.addDays(1), last)
        : const <LocalDate>[];
    for (final date in [day, ...series]) {
      if (!inPlan(date)) continue;
      (due[date] ??= []).add(item.id);
      dueOn.add((item.id, date));
    }
  }
  for (final item in items) {
    final day = revisitDayOf(item);
    if (day == null || !inPlan(day)) continue;
    final returning =
        item.status == ItemStatus.scheduled ||
        (item.status == ItemStatus.inbox && day == today);
    if (!returning || dueOn.contains((item.id, day))) continue;
    (back[day] ??= []).add(item.id);
  }
  final days = {...due.keys, ...back.keys}.toList()..sort();
  return [
    for (final day in days)
      if (_at(day, minuteOfDay).isAfter(now))
        ReminderDay(
          day: day,
          at: _at(day, minuteOfDay),
          // UUIDv7 ids sort by the moment of capture.
          deadlineIds: [...?due[day]]..sort(),
          returningIds: [...?back[day]]..sort(),
        ),
  ];
}

DateTime _at(LocalDate day, int minuteOfDay) =>
    DateTime(day.year, day.month, day.day, minuteOfDay ~/ 60, minuteOfDay % 60);
