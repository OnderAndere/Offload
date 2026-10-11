import '../time/local_date.dart';
import 'item.dart';
import 'item_enums.dart';

/// Commitments (REQ-046, REQ-047; DD-018 point 10, PO decisions
/// 02-10-2026): one per item, as fields of the item. Which part an item
/// shows depends on what is going on, not on its type.

/// Whether [item] shows the request part (asked on, promised, for): it has
/// a requester, or it is a request whose requester is not chosen yet.
bool hasRequestPart(Item item) =>
    item.requesterId != null || item.type == ItemType.request;

/// Whether [item] shows the waiting part (waits on, expected by): it is
/// waiting, also without a person.
bool hasWaitingPart(Item item) => item.status == ItemStatus.waiting;

/// The day [item] was asked: the one set, else the day it was captured on
/// this device.
LocalDate askedOn(Item item) =>
    item.askedAt ?? LocalDate.of(item.capturedAt.toLocal());

/// How many days [item] is late on [today]: waiting, with an expected date
/// before today. Null when it is not late.
int? daysLate(Item item, LocalDate today) {
  final expected = item.expectedAt;
  if (!hasWaitingPart(item) || expected == null) return null;
  final days = today.daysSince(expected);
  return days > 0 ? days : null;
}

/// The waiting items of [items] that are late on [today], the longest late
/// first: the group "Should have come in" on Today (DD-018 point 10).
List<Item> lateWaitingItems(Iterable<Item> items, LocalDate today) {
  final late = [
    for (final item in items)
      if (daysLate(item, today) != null) item,
  ];
  late.sort((a, b) {
    final byDate = a.expectedAt!.compareTo(b.expectedAt!);
    return byDate != 0 ? byDate : a.id.compareTo(b.id);
  });
  return late;
}
