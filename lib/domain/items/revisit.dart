/// "Revisit on" (REQ-021, DD-005, DD-018 point 17): an item parked with
/// status scheduled and a date comes back to the inbox from the start of
/// that day. The date stays after it returned, marking it for the group
/// "Back in your inbox" on Today while it is in the inbox.
library;

import '../time/local_date.dart';
import '../tokens/token_processing.dart';
import 'item.dart';
import 'item_enums.dart';

/// The day [item] comes back, or null when it has no revisit date. Stored
/// as UTC midnight, like a deadline.
LocalDate? revisitDayOf(Item item) {
  final at = item.revisitAt;
  return at == null ? null : storedToDateOnly(at);
}

/// The day [item] is parked until: its revisit day while it is scheduled,
/// else null. A returned item keeps its past date, which is not shown.
LocalDate? parkedDayOf(Item item) =>
    item.status == ItemStatus.scheduled ? revisitDayOf(item) : null;

/// Whether [item] is parked and still away on [today]: scheduled, with a
/// revisit date after [today]. Such an item does not count as stale or as
/// standing still: it comes back by itself.
bool isParked(Item item, LocalDate today) {
  final day = revisitDayOf(item);
  return item.status == ItemStatus.scheduled &&
      day != null &&
      day.compareTo(today) > 0;
}

/// Whether [item] is due to come back on [today]: scheduled, with a revisit
/// date of [today] or earlier. Only these return, so an item that returned
/// and was processed never returns twice.
bool returnsBy(Item item, LocalDate today) {
  final day = revisitDayOf(item);
  return item.status == ItemStatus.scheduled &&
      day != null &&
      day.compareTo(today) <= 0;
}

/// The items that came back and are still in the inbox on [today]: the
/// group "Back in your inbox" on Today, earliest date first, then the
/// order of capture.
List<Item> backInInbox(Iterable<Item> items, LocalDate today) {
  final back = <(LocalDate, Item)>[
    for (final item in items)
      if (item.status == ItemStatus.inbox)
        if (revisitDayOf(item) case final day? when day.compareTo(today) <= 0)
          (day, item),
  ];
  back.sort((a, b) {
    final byDay = a.$1.compareTo(b.$1);
    // UUIDv7 ids sort by the moment of capture.
    return byDay != 0 ? byDay : a.$2.id.compareTo(b.$2.id);
  });
  return [for (final (_, item) in back) item];
}

/// The quick choices of the sheet "Revisit on" from [today].
typedef RevisitChoices = ({
  LocalDate tomorrow,
  LocalDate nextWeek,
  LocalDate inAMonth,
});

/// Tomorrow; next week, which is the next Monday (on a Monday the Monday
/// after), and on a Sunday the Sunday after (PO 04-10-2026: tomorrow is
/// Monday already); and in a month, the same day next month or that
/// month's last day.
RevisitChoices revisitChoices(LocalDate today) {
  final month = today.month == 12 ? 1 : today.month + 1;
  final year = today.month == 12 ? today.year + 1 : today.year;
  final lastDay = LocalDate(
    month == 12 ? year + 1 : year,
    month == 12 ? 1 : month + 1,
    1,
  ).addDays(-1).day;
  return (
    tomorrow: today.addDays(1),
    nextWeek: today.addDays(
      today.weekday == DateTime.sunday ? 7 : 8 - today.weekday,
    ),
    inAMonth: LocalDate(
      year,
      month,
      today.day <= lastDay ? today.day : lastDay,
    ),
  );
}

/// The first day a revisit can be set to from [today]: tomorrow. Today
/// itself would return at once.
LocalDate firstRevisitDay(LocalDate today) => today.addDays(1);
