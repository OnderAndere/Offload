import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/items/item_status_machine.dart';

/// Where an item may go (REQ-018, DD-018 point 1).
void main() {
  test('every open status can be completed', () {
    for (final open in [
      ItemStatus.inbox,
      ItemStatus.active,
      ItemStatus.waiting,
      ItemStatus.scheduled,
    ]) {
      expect(nextStatuses(open), contains(ItemStatus.done), reason: '$open');
      // Archiving does not require done (PO decision 01-10-2026).
      expect(
        nextStatuses(open),
        contains(ItemStatus.archived),
        reason: '$open',
      );
      expect(primaryNextStatus(open), ItemStatus.done);
    }
  });

  test('done can be reopened or archived; archived only reopened', () {
    expect(nextStatuses(ItemStatus.done), {
      ItemStatus.active,
      ItemStatus.archived,
    });
    expect(nextStatuses(ItemStatus.archived), {ItemStatus.active});
    expect(primaryNextStatus(ItemStatus.done), ItemStatus.active);
    expect(primaryNextStatus(ItemStatus.archived), ItemStatus.active);
  });

  test('never back to the inbox, never to itself', () {
    for (final status in ItemStatus.values) {
      expect(nextStatuses(status), isNot(contains(ItemStatus.inbox)));
      expect(nextStatuses(status), isNot(contains(status)));
    }
  });

  test('every type is offered; a thought is an idea (Q20)', () {
    expect(selectableItemTypes.toSet(), ItemType.values.toSet());
  });
}
