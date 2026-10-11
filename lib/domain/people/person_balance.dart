import '../items/commitment.dart';
import '../items/item.dart';
import '../projects/project_overview.dart';
import '../time/local_date.dart';
import '../tokens/token_processing.dart';

/// The commitment balance with one person (REQ-048, DD-018 point 11): the
/// open items they asked for (what I deliver), the open items waiting on
/// them (what I wait for), and the day the oldest of those started.
typedef PersonBalance = ({int deliver, int waiting, LocalDate oldest});

/// The age of an open item on the balance: what I deliver from the day it
/// was asked ([askedOn]), what I wait for from the day it was captured
/// ("waiting since" is not stored yet; DD-018 point 10).
LocalDate balanceSince(Item item, {required bool waiting}) =>
    waiting ? LocalDate.of(item.capturedAt.toLocal()) : askedOn(item);

/// The balance per person id; people with nothing open are left out. "Open"
/// as in Projects ([countsAsOpen]). [resolve] turns a stored reference into
/// the live person it stands for (someone merged, DD-015); null leaves it
/// out.
Map<String, PersonBalance> personBalances(
  Iterable<Item> items, {
  String? Function(String id)? resolve,
}) {
  String? live(String? id) =>
      id == null ? null : (resolve == null ? id : resolve(id));
  final deliver = <String, int>{};
  final waiting = <String, int>{};
  final oldest = <String, LocalDate>{};
  void older(String id, LocalDate since) {
    final known = oldest[id];
    if (known == null || since.compareTo(known) < 0) oldest[id] = since;
  }

  for (final item in items) {
    if (!countsAsOpen(item)) continue;
    if (live(item.requesterId) case final id?) {
      deliver[id] = (deliver[id] ?? 0) + 1;
      older(id, balanceSince(item, waiting: false));
    }
    // Waiting now (status waiting): `waitingOnId` stays after the wait.
    if (live(item.waitingOnId) case final id? when hasWaitingPart(item)) {
      waiting[id] = (waiting[id] ?? 0) + 1;
      older(id, balanceSince(item, waiting: true));
    }
  }
  return {
    for (final id in oldest.keys)
      id: (
        deliver: deliver[id] ?? 0,
        waiting: waiting[id] ?? 0,
        oldest: oldest[id]!,
      ),
  };
}

/// The two totals at the top of People: open items I deliver and to how
/// many people, open items I wait for and from how many.
typedef BalanceTotals = ({
  int deliver,
  int deliverPeople,
  int waiting,
  int waitingPeople,
});

BalanceTotals balanceTotals(Map<String, PersonBalance> balances) {
  var deliver = 0, deliverPeople = 0, waiting = 0, waitingPeople = 0;
  for (final balance in balances.values) {
    deliver += balance.deliver;
    waiting += balance.waiting;
    if (balance.deliver > 0) deliverPeople++;
    if (balance.waiting > 0) waitingPeople++;
  }
  return (
    deliver: deliver,
    deliverPeople: deliverPeople,
    waiting: waiting,
    waitingPeople: waitingPeople,
  );
}

/// The order of People (DD-018 point 11, PO decision 02-10-2026): people
/// with open items first, the most open items (deliver + wait) on top,
/// alphabetical ([nameKey]) when equal; then everyone else, alphabetical.
/// The id decides between equal names, so the order is always the same.
int balanceOrder(
  ({String id, String name, PersonBalance? balance}) a,
  ({String id, String name, PersonBalance? balance}) b,
) {
  int total(PersonBalance? x) => x == null ? 0 : x.deliver + x.waiting;
  final byTotal = total(b.balance).compareTo(total(a.balance));
  if (byTotal != 0) return byTotal;
  final byName = nameKey(a.name).compareTo(nameKey(b.name));
  return byName != 0 ? byName : a.id.compareTo(b.id);
}

/// Days from [oldest] to [today]; never negative.
int balanceAge(LocalDate oldest, LocalDate today) {
  final days = today.daysSince(oldest);
  return days < 0 ? 0 : days;
}

/// "Old after" (DD-018 point 11): from how many days an open item with a
/// person is old; an age of that many days or more is (PO 02-10-2026). A
/// setting of this device.
abstract final class OldAfter {
  static const choices = [7, 10, 14, 21, 30, 45, 60];
  static const standard = 21;

  /// The stored number of days, or [standard] for a missing or unknown
  /// value.
  static int parse(String? stored) {
    final days = int.tryParse(stored ?? '');
    return choices.contains(days) ? days! : standard;
  }

  static bool isOld(int ageDays, int oldAfterDays) => ageDays >= oldAfterDays;
}

/// The order of the open items of a person screen as the 1-on-1
/// preparation (DD-018 point 11): first what is overdue or late (deadline
/// or expected day passed), earliest first; then the oldest, by the same
/// day as its age on the balance ([balanceSince]): asked for what I deliver,
/// captured for what I wait for ([waiting]).
Comparator<Item> preparationOrder(LocalDate today, {required bool waiting}) =>
    (a, b) {
      LocalDate? late(Item item) {
        final due = item.dueAt == null ? null : storedToDateOnly(item.dueAt!);
        final overdue = isOverdue(item, today) ? due : null;
        final expected = daysLate(item, today) != null ? item.expectedAt : null;
        if (overdue == null) return expected;
        if (expected == null) return overdue;
        return overdue.compareTo(expected) <= 0 ? overdue : expected;
      }

      final lateA = late(a);
      final lateB = late(b);
      if (lateA != null && lateB != null) {
        final byLate = lateA.compareTo(lateB);
        if (byLate != 0) return byLate;
      } else if (lateA != null) {
        return -1;
      } else if (lateB != null) {
        return 1;
      }
      final byAge = balanceSince(
        a,
        waiting: waiting,
      ).compareTo(balanceSince(b, waiting: waiting));
      return byAge != 0 ? byAge : a.id.compareTo(b.id);
    };
