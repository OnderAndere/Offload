import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/person_balance.dart';
import 'package:offload/domain/people/person_overview.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// The commitment balance per person (T10.2, REQ-048, DD-018 point 11).
void main() {
  final today = LocalDate(2026, 10, 2);
  var n = 0;

  /// An item captured [daysAgo] days before [today] (noon UTC).
  Item item({
    String? requester,
    String? waitingOn,
    ItemStatus status = ItemStatus.active,
    ItemType type = ItemType.task,
    int daysAgo = 0,
    LocalDate? askedAt,
    LocalDate? due,
    LocalDate? expectedAt,
  }) {
    final day = today.addDays(-daysAgo);
    final id = UuidV7Generator(
      now: () => DateTime.utc(
        day.year,
        day.month,
        day.day,
        12,
      ).add(Duration(milliseconds: n++)).millisecondsSinceEpoch,
    ).next();
    return Item(
      id: id,
      rawText: 'item $n',
      status: status,
      source: ItemSource.app,
      type: type,
      requesterId: requester,
      waitingOnId: waitingOn,
      askedAt: askedAt,
      dueAt: due == null ? null : dateOnlyToStored(due),
      expectedAt: expectedAt,
    );
  }

  group('personBalances', () {
    test('deliver, wait and the oldest day per person', () {
      final balances = personBalances([
        item(requester: 'jan', daysAgo: 5),
        item(requester: 'jan', daysAgo: 25),
        item(waitingOn: 'jan', status: ItemStatus.waiting, daysAgo: 3),
        item(waitingOn: 'petra', status: ItemStatus.waiting, daysAgo: 12),
      ]);
      expect(balances['jan'], (
        deliver: 2,
        waiting: 1,
        oldest: today.addDays(-25),
      ));
      expect(balances['petra'], (
        deliver: 0,
        waiting: 1,
        oldest: today.addDays(-12),
      ));
    });

    test('delivering counts from the day asked, if set', () {
      final balances = personBalances([
        item(requester: 'jan', daysAgo: 2, askedAt: today.addDays(-30)),
      ]);
      expect(balances['jan']!.oldest, today.addDays(-30));
    });

    test('done, archived, notes and no longer waiting do not count', () {
      final balances = personBalances([
        item(requester: 'jan', status: ItemStatus.done),
        item(requester: 'jan', status: ItemStatus.archived),
        item(requester: 'jan', type: ItemType.note),
        item(waitingOn: 'jan'), // waited before, active now
      ]);
      expect(balances, isEmpty);
    });

    test('a merged person counts as the one they went into', () {
      final balances = personBalances([
        item(requester: 'old'),
      ], resolve: (id) => id == 'old' ? 'new' : id);
      expect(balances.keys, ['new']);
    });
  });

  test('totals: items and people per side', () {
    final totals = balanceTotals({
      'jan': (deliver: 3, waiting: 1, oldest: today),
      'petra': (deliver: 1, waiting: 3, oldest: today),
      'anna': (deliver: 1, waiting: 0, oldest: today),
    });
    expect(totals, (
      deliver: 5,
      deliverPeople: 3,
      waiting: 4,
      waitingPeople: 2,
    ));
  });

  test('order: most open first, alphabetical when equal, then the rest', () {
    final rows = [
      (
        id: 'p1',
        name: 'anna',
        balance: (deliver: 1, waiting: 0, oldest: today),
      ),
      (id: 'p2', name: 'Kees', balance: null),
      (
        id: 'p3',
        name: 'Petra',
        balance: (deliver: 1, waiting: 3, oldest: today),
      ),
      (id: 'p4', name: 'Bert', balance: null),
      (id: 'p5', name: 'Jan', balance: (deliver: 3, waiting: 1, oldest: today)),
    ]..sort(balanceOrder);
    expect(
      [for (final r in rows) r.name],
      ['Jan', 'Petra', 'anna', 'Bert', 'Kees'],
    );
  });

  test('order: the id decides between equal names', () {
    final rows = [
      (id: 'b', name: 'Jan', balance: null),
      (id: 'a', name: 'jan', balance: null),
    ]..sort(balanceOrder);
    expect([for (final r in rows) r.id], ['a', 'b']);
  });

  test('old: the threshold itself counts as old', () {
    expect(OldAfter.isOld(21, 21), isTrue);
    expect(OldAfter.isOld(20, 21), isFalse);
    expect(OldAfter.isOld(90, 60), isTrue);
    expect(balanceAge(today.addDays(-25), today), 25);
    expect(balanceAge(today.addDays(2), today), 0);
    expect(OldAfter.parse('45'), 45);
    expect(OldAfter.parse('8'), OldAfter.standard);
    expect(OldAfter.parse(null), 21);
  });

  test('preparation: overdue and late first, then the oldest', () {
    final recent = item(requester: 'jan', daysAgo: 2);
    final old = item(requester: 'jan', daysAgo: 25);
    final overdue = item(requester: 'jan', daysAgo: 1, due: today.addDays(-1));
    final late = item(
      waitingOn: 'jan',
      status: ItemStatus.waiting,
      daysAgo: 1,
      expectedAt: today.addDays(-3),
    );
    final lists = personLists(
      'jan',
      [recent, old, overdue, late],
      {},
      today: today,
    );
    expect(
      [for (final i in lists[PersonList.requestedBy]!.open) i.id],
      [overdue.id, old.id, recent.id],
    );
    expect(
      [for (final i in lists[PersonList.waitingFor]!.open) i.id],
      [late.id],
    );
  });

  test('preparation: what I wait for is as old as its capture', () {
    // Asked long ago, captured recently: as old as the balance says.
    final askedLongAgo = item(
      requester: 'jan',
      waitingOn: 'jan',
      status: ItemStatus.waiting,
      daysAgo: 2,
      askedAt: today.addDays(-40),
    );
    final capturedEarlier = item(
      waitingOn: 'jan',
      status: ItemStatus.waiting,
      daysAgo: 10,
    );
    final lists = personLists(
      'jan',
      [askedLongAgo, capturedEarlier],
      {},
      today: today,
    );
    expect(
      [for (final i in lists[PersonList.waitingFor]!.open) i.id],
      [capturedEarlier.id, askedLongAgo.id],
    );
    expect(
      [for (final i in lists[PersonList.requestedBy]!.open) i.id],
      [askedLongAgo.id],
    );
  });
}
