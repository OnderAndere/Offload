import 'package:flutter_test/flutter_test.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/commitment.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';

/// Which part of a commitment an item shows, and when it is late (T10.1,
/// DD-018 point 10).
void main() {
  // Captured on 1 October 2026, noon UTC.
  final id = UuidV7Generator(
    now: () => DateTime.utc(2026, 10, 1, 12).millisecondsSinceEpoch,
  ).next();

  Item item({
    ItemType? type,
    ItemStatus status = ItemStatus.active,
    String? requesterId,
    LocalDate? askedAt,
    LocalDate? expectedAt,
    String itemId = '',
  }) => Item(
    id: itemId.isEmpty ? id : itemId,
    rawText: 'Offerte',
    status: status,
    source: ItemSource.app,
    type: type,
    requesterId: requesterId,
    askedAt: askedAt,
    expectedAt: expectedAt,
  );

  test('the request part: a requester, or a request without one', () {
    expect(hasRequestPart(item(requesterId: 'p')), isTrue);
    expect(hasRequestPart(item(type: ItemType.request)), isTrue);
    expect(hasRequestPart(item(type: ItemType.task)), isFalse);
    expect(hasRequestPart(item(type: ItemType.note)), isFalse);
  });

  test('the waiting part: every waiting item, whatever its type', () {
    expect(hasWaitingPart(item(status: ItemStatus.waiting)), isTrue);
    expect(
      hasWaitingPart(item(type: ItemType.idea, status: ItemStatus.waiting)),
      isTrue,
    );
    expect(hasWaitingPart(item()), isFalse);
  });

  test('asked on: the day set, else the capture day', () {
    expect(
      askedOn(item(askedAt: LocalDate(2026, 9, 28))),
      LocalDate(2026, 9, 28),
    );
    expect(askedOn(item()), LocalDate.of(uuidV7Time(id).toLocal()));
  });

  test('late: waiting, with an expected date before today', () {
    final today = LocalDate(2026, 10, 2);
    final expected = LocalDate(2026, 9, 29);
    expect(
      daysLate(item(status: ItemStatus.waiting, expectedAt: expected), today),
      3,
    );
    // Due today is not late yet.
    expect(
      daysLate(item(status: ItemStatus.waiting, expectedAt: today), today),
      isNull,
    );
    // Not waiting any more: not late.
    expect(daysLate(item(expectedAt: expected), today), isNull);
  });

  test('the late group: longest late first', () {
    final today = LocalDate(2026, 10, 2);
    final a = item(
      itemId: 'a',
      status: ItemStatus.waiting,
      expectedAt: LocalDate(2026, 9, 30),
    );
    final b = item(
      itemId: 'b',
      status: ItemStatus.waiting,
      expectedAt: LocalDate(2026, 9, 20),
    );
    final c = item(itemId: 'c', status: ItemStatus.waiting);
    expect(
      [
        for (final i in lateWaitingItems([a, b, c], today)) i.id,
      ],
      ['b', 'a'],
    );
  });
}
