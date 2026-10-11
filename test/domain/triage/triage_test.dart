import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/triage/triage.dart';

/// Triage (REQ-010, AC REQ-010, DD-018 point 3).
void main() {
  const item = Item(
    id: 'x',
    rawText: 'Bel Jan',
    status: ItemStatus.inbox,
    source: ItemSource.app,
  );

  group('sortInto (AC REQ-010)', () {
    ItemClassification sort(TriageDestination d, {String? person}) =>
        sortInto(item, d, personId: person);

    test('task, idea and note become active with that type', () {
      expect(sort(TriageDestination.task).type, ItemType.task);
      expect(sort(TriageDestination.idea).type, ItemType.idea);
      expect(sort(TriageDestination.note).type, ItemType.note);
      for (final d in [
        TriageDestination.task,
        TriageDestination.idea,
        TriageDestination.note,
      ]) {
        expect(sort(d).status, ItemStatus.active);
      }
    });

    test('a request is active with the requester', () {
      final c = sort(TriageDestination.request, person: 'jan');
      expect(c.type, ItemType.request);
      expect(c.status, ItemStatus.active);
      expect(c.requesterId, 'jan');
      expect(c.waitingOnId, isNull);
    });

    test('waiting for keeps the type and waits on the person', () {
      const typed = Item(
        id: 'y',
        rawText: 'Offerte',
        status: ItemStatus.inbox,
        source: ItemSource.app,
        type: ItemType.task,
        requesterId: 'piet',
      );
      final c = sortInto(typed, TriageDestination.waitingFor, personId: 'jan');
      expect(c.type, ItemType.task);
      expect(c.status, ItemStatus.waiting);
      expect(c.waitingOnId, 'jan');
      expect(c.requesterId, 'piet');
    });

    test('without a person the role stays as it was', () {
      expect(sort(TriageDestination.request).requesterId, isNull);
      expect(sort(TriageDestination.waitingFor).waitingOnId, isNull);
    });

    test('only request and waiting for ask for a person', () {
      expect(
        [
          for (final d in TriageDestination.values)
            if (d.asksForPerson) d,
        ],
        [TriageDestination.request, TriageDestination.waitingFor],
      );
    });

    test('the trash is no classification', () {
      expect(() => sort(TriageDestination.trash), throwsArgumentError);
    });
  });

  group('TriageSession', () {
    test('goes card by card and counts', () {
      final s = TriageSession(['a', 'b', 'c']);
      expect((s.current, s.position, s.total), ('a', 1, 3));
      s.decide(s.current!, TriageOutcome.sorted);
      s.decide(s.current!, TriageOutcome.skipped);
      expect((s.current, s.position), ('c', 3));
      s.decide(s.current!, TriageOutcome.sorted);
      expect(s.current, isNull);
      expect((s.processed, s.skipped), (2, 1));
    });

    test('new captures come at the end and raise the total', () {
      final s = TriageSession(['b', 'a']);
      s.decide(s.current!, TriageOutcome.sorted);
      s.update(['new', 'a']);
      expect((s.current, s.position, s.total), ('a', 2, 3));
      s.decide(s.current!, TriageOutcome.sorted);
      expect(s.current, 'new');
    });

    test('a card that left the inbox another way is passed over', () {
      final s = TriageSession(['a', 'b', 'c']);
      s.update(['a', 'c']);
      s.decide(s.current!, TriageOutcome.sorted);
      expect(s.current, 'c');
      expect(s.total, 2);
    });

    test('undo brings the last card back and forgets its outcome', () {
      final s = TriageSession(['a', 'b']);
      expect(s.undo('a'), isFalse);
      s.decide(s.current!, TriageOutcome.sorted);
      // The sorted card left the inbox; that does not remove it.
      s.update(['b']);
      expect(s.undo('a'), isTrue);
      expect((s.current, s.processed), ('a', 0));
    });

    test('an undone card is kept until the inbox has it again', () {
      final s = TriageSession(['a', 'b']);
      s.decide(s.current!, TriageOutcome.sorted);
      s.undo('a');
      // An older update, from before the undo was written.
      s.update(['b']);
      expect(s.current, 'a');
      s.update(['a', 'b']);
      // Back in the inbox: from now on it is an ordinary card again.
      s.update(['b']);
      expect(s.current, 'b');
    });

    test('a choice for a card that is not current is refused', () {
      final s = TriageSession(['a', 'b']);
      expect(s.decide('b', TriageOutcome.sorted), isFalse);
      expect(s.decide('a', TriageOutcome.sorted), isTrue);
      // A double tap on the same card does not decide the next one.
      expect(s.decide('a', TriageOutcome.sorted), isFalse);
      expect((s.current, s.processed), ('b', 1));
    });

    test('undo only takes back the last decision, once', () {
      final s = TriageSession(['a', 'b', 'c']);
      s.decide('a', TriageOutcome.sorted);
      s.decide('b', TriageOutcome.skipped);
      // A late undo for a, after b was decided, is refused.
      expect(s.undo('a'), isFalse);
      expect(s.undo('b'), isTrue);
      expect(s.undo('b'), isFalse);
      expect(s.current, 'b');
      expect((s.processed, s.skipped), (1, 0));
    });
  });
}
