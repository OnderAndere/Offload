import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item.dart';
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/time/local_date.dart';

import '../../fakes/test_storage.dart';

/// Commitments on the database (T10.1, REQ-046, REQ-047, DD-018 point 10).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  Future<Item> item(String id) async => (await items.watchItem(id).first)!;

  Future<String> waiting(String text) async {
    final id = await items.capture(text, source: ItemSource.app);
    await items.classify(
      id,
      const ItemClassification(
        type: ItemType.task,
        status: ItemStatus.waiting,
        requesterId: null,
        waitingOnId: null,
      ),
    );
    return id;
  }

  test('asked on, promise and expected by round-trip, and clear', () async {
    final id = await items.capture('Offerte', source: ItemSource.app);
    await items.setAskedOn(id, LocalDate(2026, 9, 28));
    await items.setPromise(id, '  Prijs en planning sturen  ');
    await items.setExpectedBy(id, LocalDate(2026, 10, 8));

    var stored = await item(id);
    expect(stored.askedAt, LocalDate(2026, 9, 28));
    expect(stored.promise, 'Prijs en planning sturen');
    expect(stored.expectedAt, LocalDate(2026, 10, 8));

    await items.setAskedOn(id, null);
    await items.setPromise(id, '   ');
    await items.setExpectedBy(id, null);
    stored = await item(id);
    expect(stored.askedAt, isNull);
    expect(stored.promise, isNull);
    expect(stored.expectedAt, isNull);
  });

  test('every change goes through the change log (REQ-008)', () async {
    final id = await items.capture('Offerte', source: ItemSource.app);
    await items.setPromise(id, 'Prijs sturen');
    final log = await (storage.database.select(
      storage.database.changeLog,
    )..where((e) => e.entityId.equals(id))).get();
    expect(log.last.operation, ChangeOperation.update);
    expect(log.last.payload, contains('Prijs sturen'));
  });

  test('a date is the same day in every time zone (date-only)', () async {
    final id = await items.capture('Offerte', source: ItemSource.app);
    await items.setExpectedBy(id, LocalDate(2026, 10, 8));
    final row = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.id.equals(id))).getSingle();
    expect(row.expectedAt, DateTime.utc(2026, 10, 8));
  });

  test(
    'late waiting: before the day, waiting only, longest late first',
    () async {
      final late2 = await waiting('Tekeningen');
      final late5 = await waiting('Offerte terug');
      final onTime = await waiting('Contract');
      final notWaiting = await items.capture(
        'Losse taak',
        source: ItemSource.app,
      );
      await items.setExpectedBy(late2, LocalDate(2026, 9, 30));
      await items.setExpectedBy(late5, LocalDate(2026, 9, 27));
      await items.setExpectedBy(onTime, LocalDate(2026, 10, 2));
      await items.setExpectedBy(notWaiting, LocalDate(2026, 9, 1));

      final late = await items.watchLateWaiting(LocalDate(2026, 10, 2)).first;

      expect([for (final i in late) i.id], [late5, late2]);
    },
  );

  group('the expected day when waiting starts (review T10.1)', () {
    test('an old date never comes back on a new wait', () async {
      final id = await items.capture('Tekeningen', source: ItemSource.app);
      await items.waitFor(id, null, expected: LocalDate(2026, 10, 1));
      expect((await item(id)).expectedAt, LocalDate(2026, 10, 1));

      await items.moveTo(id, ItemStatus.active);
      // Leaving waiting keeps it (the undo of completing needs it).
      expect((await item(id)).expectedAt, LocalDate(2026, 10, 1));

      await items.waitFor(id, null);
      expect((await item(id)).expectedAt, isNull);
    });

    test('already waiting: kept unless a new day is given', () async {
      final id = await items.capture('Tekeningen', source: ItemSource.app);
      await items.waitFor(id, null, expected: LocalDate(2026, 10, 1));
      await items.waitFor(id, null);
      expect((await item(id)).expectedAt, LocalDate(2026, 10, 1));
      await items.waitFor(id, null, expected: LocalDate(2026, 10, 9));
      expect((await item(id)).expectedAt, LocalDate(2026, 10, 9));
    });

    test(
      'classify sets or clears it in the same change, or leaves it',
      () async {
        final id = await items.capture('Tekeningen', source: ItemSource.app);
        const waiting = ItemClassification(
          type: ItemType.task,
          status: ItemStatus.waiting,
          requesterId: null,
          waitingOnId: null,
        );
        await items.classify(
          id,
          waiting,
          expected: (day: LocalDate(2026, 10, 1)),
        );
        expect((await item(id)).expectedAt, LocalDate(2026, 10, 1));
        await items.classify(id, waiting);
        expect((await item(id)).expectedAt, LocalDate(2026, 10, 1));
        await items.classify(id, waiting, expected: (day: null));
        expect((await item(id)).expectedAt, isNull);
      },
    );
  });
}
