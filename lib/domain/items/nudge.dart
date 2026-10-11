/// The nudge of waiting items that stay silent (AC REQ-047, T10.1, DD-005,
/// DD-018 point 10; PO decisions 04-10-2026): a waiting item without an
/// expected date that was not touched for X days is "silent". An item with
/// an expected date is handled by that date, never also by silence.
library;

import '../time/local_date.dart';
import 'commitment.dart';
import 'item.dart';

/// After how many days without a touch a waiting item is silent: a setting
/// of this device, 7 by default (decision a).
abstract final class NudgeAfter {
  static const choices = [3, 5, 7, 10, 14, 21];
  static const standard = 7;

  /// The stored number of days, or [standard] for a missing or unknown
  /// value.
  static int parse(String? stored) {
    final days = int.tryParse(stored ?? '');
    return choices.contains(days) ? days! : standard;
  }
}

/// The day silence counts from: the last touch (a change, *Still waiting*
/// in the weekly review, or *Chased*), else the capture; local.
LocalDate quietSince(Item item) =>
    LocalDate.of((item.lastTouch ?? item.capturedAt).toLocal());

/// Whether [item] can become silent: waiting, without an expected date.
bool canGoSilent(Item item) => hasWaitingPart(item) && item.expectedAt == null;

/// The day [item] becomes silent with [afterDays], or null when it cannot.
LocalDate? silentFrom(Item item, int afterDays) =>
    canGoSilent(item) ? quietSince(item).addDays(afterDays) : null;

/// How many days [item] has been without a touch on [today], when it is
/// silent ([afterDays] or more); else null.
int? silentDays(Item item, LocalDate today, int afterDays) {
  if (!canGoSilent(item)) return null;
  final days = today.daysSince(quietSince(item));
  return days >= afterDays ? days : null;
}

/// The silent items of [items] on [today], the longest silent first: the
/// group "Blijft stil" on Today.
List<Item> silentItems(Iterable<Item> items, LocalDate today, int afterDays) {
  final silent = <(int, Item)>[
    for (final item in items)
      if (silentDays(item, today, afterDays) case final days?) (days, item),
  ];
  silent.sort((a, b) {
    final byDays = b.$1.compareTo(a.$1);
    return byDays != 0 ? byDays : a.$2.id.compareTo(b.$2.id);
  });
  return [for (final (_, item) in silent) item];
}
