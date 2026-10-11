import '../items/item.dart';
import '../items/item_enums.dart';
import '../items/revisit.dart';
import '../items/today.dart';
import '../repeats/repeat.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';

/// The steps of the weekly review, in their order (REQ-013, DD-018 point
/// 8): the Overview first, always shown (point 12 (g)).
enum ReviewStep { insights, inbox, waiting, deadlines, stale }

/// After how many weeks without a touch an open item is stale (AC
/// REQ-051): a setting of this device, never synchronised.
abstract final class StaleAfter {
  static const min = 1;
  static const max = 12;
  static const standard = 3;

  /// The stored number of weeks, or [standard] for a missing or unknown
  /// value; kept within [min] and [max].
  static int parse(String? stored) {
    final weeks = int.tryParse(stored ?? '');
    if (weeks == null) return standard;
    return weeks.clamp(min, max);
  }
}

/// After how many calendar days since the last completed review a new one
/// is due (DD-018 point 8): a setting of this device, never synchronised.
abstract final class ReviewDueAfter {
  static const choices = [3, 5, 7, 10, 14, 21, 28];
  static const standard = 7;

  /// The stored number of days, or [standard] for a missing or unknown
  /// value.
  static int parse(String? stored) {
    final days = int.tryParse(stored ?? '');
    return choices.contains(days) ? days! : standard;
  }
}

/// Calendar days from the last completed review to [today], null when
/// there was none. A review dated after today (the clock was changed)
/// counts as today.
int? daysSinceReview(DateTime? lastCompleted, LocalDate today) {
  if (lastCompleted == null) return null;
  final days = today.daysSince(LocalDate.of(lastCompleted.toLocal()));
  return days < 0 ? 0 : days;
}

/// Whether a weekly review is due (DD-018 points 4 and 8): never done, or
/// the last one [dueAfterDays] calendar days ago or longer. The time of day
/// does not matter.
bool reviewDue(DateTime? lastCompleted, LocalDate today, int dueAfterDays) {
  final days = daysSinceReview(lastCompleted, today);
  return days == null || days >= dueAfterDays;
}

/// Oldest last touch first; an unknown touch counts as oldest.
int _byLastTouch(Item a, Item b) {
  final ta = a.lastTouch;
  final tb = b.lastTouch;
  if (ta == null || tb == null) {
    if (ta == tb) return a.id.compareTo(b.id);
    return ta == null ? -1 : 1;
  }
  final byTouch = ta.compareTo(tb);
  return byTouch != 0 ? byTouch : a.id.compareTo(b.id);
}

/// Step 2: the items waiting on someone, longest untouched first.
List<Item> waitingForReview(Iterable<Item> items) => [
  for (final item in items)
    if (item.status == ItemStatus.waiting) item,
]..sort(_byLastTouch);

/// Step 3: open items with a deadline before [today], and those from
/// [today] up to [days] days ahead; each by deadline (DD-018 point 8).
({List<Item> overdue, List<Item> upcoming}) deadlinesForReview(
  Iterable<Item> items,
  LocalDate today, {
  int days = 14,
}) {
  final last = today.addDays(days);
  final overdue = <Item>[];
  final upcoming = <Item>[];
  for (final item in items) {
    final due = item.dueAt;
    if (due == null || !isOpen(item.status)) continue;
    final date = storedToDateOnly(due);
    if (date.compareTo(today) < 0) {
      overdue.add(item);
    } else if (date.compareTo(last) <= 0) {
      upcoming.add(item);
    }
  }
  int byDue(Item a, Item b) {
    final byDate = a.dueAt!.compareTo(b.dueAt!);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  }

  return (overdue: overdue..sort(byDue), upcoming: upcoming..sort(byDue));
}

/// Step 4 (AC REQ-051): open items, notes included, whose last touch is
/// [weeks] weeks before [now] or longer, oldest first. A parked item
/// ("revisit on" after today, `isParked`) does not count: it comes back by
/// itself. Nor does a repeating task ([repeats], REQ-061): it comes back on
/// its date, on *Today*.
List<Item> staleItems(
  Iterable<Item> items,
  DateTime now,
  int weeks, {
  Map<String, ItemRepeat> repeats = const {},
}) {
  final limit = now.toUtc().subtract(Duration(days: 7 * weeks));
  final today = LocalDate.of(now);
  return [
    for (final item in items)
      if (isOpen(item.status) &&
          !isParked(item, today) &&
          !(repeats.containsKey(item.id) && repeatsAs(item.type)) &&
          !(item.lastTouch?.isAfter(limit) ?? false))
        item,
  ]..sort(_byLastTouch);
}
