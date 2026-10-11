import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/person.dart';
import 'package:offload/domain/people/person_overview.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

/// Counts and lists of the people screens (DD-018 point 7).
void main() {
  final today = LocalDate(2026, 10, 1);
  var next = 0;
  Item item({
    String? requester,
    String? waitingOn,
    ItemStatus status = ItemStatus.active,
    ItemType? type = ItemType.task,
    LocalDate? due,
    String? id,
  }) => Item(
    // Ids sort like capture moments: a higher number is newer.
    id: id ?? 'i${(next++).toString().padLeft(3, '0')}',
    rawText: 'x',
    status: status,
    source: ItemSource.app,
    type: type,
    requesterId: requester,
    waitingOnId: waitingOn,
    dueAt: due == null ? null : dateOnlyToStored(due),
  );

  group('personLists', () {
    test('splits into requested by, waiting for and mentioned in', () {
      final asked = item(requester: 'jan');
      final both = item(
        requester: 'jan',
        waitingOn: 'jan',
        status: ItemStatus.waiting,
      );
      final waits = item(waitingOn: 'jan', status: ItemStatus.waiting);
      final waitedDone = item(waitingOn: 'jan', status: ItemStatus.done);
      final waitedBefore = item(waitingOn: 'jan'); // not waiting now
      final namedOnly = item();
      final namedAndAsked = item(requester: 'jan');
      final note = item(requester: 'jan', type: ItemType.note);
      final archived = item(requester: 'jan', status: ItemStatus.archived);

      final lists = personLists(
        'jan',
        [
          asked,
          both,
          waits,
          waitedDone,
          waitedBefore,
          namedOnly,
          namedAndAsked,
          note,
          archived,
        ],
        {namedOnly.id, namedAndAsked.id},
      );

      expect(
        lists[PersonList.requestedBy]!.open,
        unorderedEquals([asked, both, namedAndAsked, note]),
      );
      expect(lists[PersonList.requestedBy]!.done, isEmpty);
      expect(
        lists[PersonList.waitingFor]!.open,
        unorderedEquals([both, waits]),
      );
      expect(lists[PersonList.waitingFor]!.done, [waitedDone]);
      expect(lists[PersonList.mentionedIn]!.open, [namedOnly]);
    });

    test(
      'an item that waited on the person before is mentioned only when named',
      () {
        final waitedBefore = item(waitingOn: 'jan');
        expect(personLists('jan', [waitedBefore], {}), isEmpty);
        expect(
          personLists(
            'jan',
            [waitedBefore],
            {waitedBefore.id},
          )[PersonList.mentionedIn]!.open,
          [waitedBefore],
        );
      },
    );

    test('only lists with items; done items in the fold', () {
      final done = item(requester: 'jan', status: ItemStatus.done);
      final lists = personLists('jan', [done], {});
      expect(lists.keys, [PersonList.requestedBy]);
      expect(lists[PersonList.requestedBy]!.open, isEmpty);
      expect(lists[PersonList.requestedBy]!.done, [done]);
    });

    test('dated items first by deadline, then the rest newest first', () {
      final old = item(requester: 'jan', id: 'a');
      final newer = item(requester: 'jan', id: 'b');
      final later = item(requester: 'jan', id: 'c', due: today.addDays(3));
      final sooner = item(requester: 'jan', id: 'd', due: today.addDays(-2));
      final lists = personLists('jan', [old, newer, later, sooner], {});
      expect(lists[PersonList.requestedBy]!.open, [sooner, later, newer, old]);
    });
  });

  test('Person.matches looks in the name and the aliases, ignoring case', () {
    const jan = Person(id: 'j', name: 'Jan Bakker', aliases: ['JB', 'Сергей']);
    expect(jan.matches('bak'), isTrue);
    expect(jan.matches('jb'), isTrue);
    expect(jan.matches('СЕРГ'), isTrue);
    expect(jan.matches('petra'), isFalse);
  });

  test('initialsOf: first and last word, any script', () {
    expect(initialsOf('Jan Bakker'), 'JB');
    expect(initialsOf('jan de bakker'), 'JB');
    expect(initialsOf('Сергей Иванов'), 'СИ');
    expect(initialsOf('Petra'), 'P');
    expect(initialsOf('  '), '');
  });
}
