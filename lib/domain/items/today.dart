import '../time/local_date.dart';
import '../tokens/token_processing.dart';
import 'item.dart';
import 'item_enums.dart';

/// What Today shows (DD-018 point 4): every open item whose deadline is
/// [today] or earlier, in any status except done and archived (the inbox
/// included), split into what is overdue and what is due today. Each part
/// has the items with high priority on top (T4b.1, DD-004 point 11), then
/// the rest; within both, the oldest deadline first, then the order of
/// capture. Normal and low priority do not move. Items without a deadline,
/// or with a later one, are not on Today.
({List<Item> overdue, List<Item> today}) todaySections(
  Iterable<Item> items,
  LocalDate today,
) {
  final overdue = <(LocalDate, Item)>[];
  final dueToday = <(LocalDate, Item)>[];
  for (final item in items) {
    final dueAt = item.dueAt;
    if (dueAt == null || !isOpen(item.status)) continue;
    final due = storedToDateOnly(dueAt);
    final order = due.compareTo(today);
    if (order < 0) {
      overdue.add((due, item));
    } else if (order == 0) {
      dueToday.add((due, item));
    }
  }
  List<Item> sorted(List<(LocalDate, Item)> part) {
    part.sort((a, b) {
      final byPriority = _rank(a.$2).compareTo(_rank(b.$2));
      if (byPriority != 0) return byPriority;
      final byDue = a.$1.compareTo(b.$1);
      // UUIDv7 ids sort by the moment of capture.
      return byDue != 0 ? byDue : a.$2.id.compareTo(b.$2.id);
    });
    return [for (final (_, item) in part) item];
  }

  return (overdue: sorted(overdue), today: sorted(dueToday));
}

/// 0 for high priority, which goes on top; 1 for every other item.
int _rank(Item item) => item.priority == ItemPriority.high ? 0 : 1;

/// Whether an item in [status] still asks for something: not done and not
/// archived.
bool isOpen(ItemStatus status) =>
    status != ItemStatus.done && status != ItemStatus.archived;
