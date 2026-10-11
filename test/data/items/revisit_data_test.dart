import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item.dart' as domain;
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

import '../../fakes/test_storage.dart';

/// "Revisit on" in the data layer (T4.2, REQ-021, DD-005).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  final today = LocalDate(2026, 10, 9);

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  Future<domain.Item> read(String id) async =>
      (await items.watchLiveItems().first).singleWhere((i) => i.id == id);

  Future<String> capture(String text, {ItemStatus? status}) async {
    final id = await items.capture(text, source: ItemSource.app);
    if (status != null) await items.moveTo(id, status);
    return id;
  }

  test('parking sets status scheduled and the date in one change', () async {
    final id = await capture('Fietsenrek ophangen', status: ItemStatus.active);
    await items.revisitOn(id, LocalDate(2026, 10, 12));

    final item = await read(id);
    expect(item.status, ItemStatus.scheduled);
    expect(item.revisitAt, dateOnlyToStored(LocalDate(2026, 10, 12)));
    final log = await (storage.database.select(
      storage.database.changeLog,
    )..where((e) => e.entityId.equals(id))).get();
    expect(log.last.operation, ChangeOperation.update);
    expect(log.last.payload, contains('revisit_at'));
    expect(log.last.payload, contains('scheduled'));
  });

  test('an inbox item and a parked item can be parked; a new date '
      'replaces the old', () async {
    final id = await capture('Cursus timmeren uitzoeken');
    await items.revisitOn(id, LocalDate(2026, 10, 12));
    await items.revisitOn(id, LocalDate(2026, 11, 9));
    final item = await read(id);
    expect(item.status, ItemStatus.scheduled);
    expect(item.revisitAt, dateOnlyToStored(LocalDate(2026, 11, 9)));
  });

  test('done and archived items cannot be parked', () async {
    final done = await capture('Klaar', status: ItemStatus.done);
    final archived = await capture('Weg', status: ItemStatus.archived);
    expect(
      () => items.revisitOn(done, LocalDate(2026, 10, 12)),
      throwsStateError,
    );
    expect(
      () => items.revisitOn(archived, LocalDate(2026, 10, 12)),
      throwsStateError,
    );
  });

  test('not any more: active again, without a date', () async {
    final id = await capture('Moestuinbak bijvullen');
    await items.revisitOn(id, LocalDate(2026, 10, 12));
    await items.stopRevisit(id);
    final item = await read(id);
    expect(item.status, ItemStatus.active);
    expect(item.revisitAt, isNull);

    expect(() => items.stopRevisit(id), throwsStateError);
  });

  test('moving a parked item by hand drops its date', () async {
    final a = await capture('a');
    final b = await capture('b');
    await items.revisitOn(a, LocalDate(2026, 10, 12));
    await items.revisitOn(b, LocalDate(2026, 10, 12));
    await items.moveTo(a, ItemStatus.done);
    await items.waitFor(b, null);
    expect((await read(a)).revisitAt, isNull);
    expect((await read(b)).status, ItemStatus.waiting);
    expect((await read(b)).revisitAt, isNull);
  });

  test('scheduled by hand drops an old date, so it does not return at '
      'once', () async {
    final id = await capture('Al eens terug geweest');
    await items.revisitOn(id, today);
    await items.returnRevisited(today);
    // Back in the inbox with its past date; now scheduled by hand.
    await items.moveTo(id, ItemStatus.scheduled);
    expect((await read(id)).status, ItemStatus.scheduled);
    expect((await read(id)).revisitAt, isNull);
    expect(await items.returnRevisited(today.addDays(1)), isEmpty);
  });

  test('an undo puts back the status and the date', () async {
    final id = await capture('Fietsenrek ophangen', status: ItemStatus.active);
    await items.revisitOn(id, LocalDate(2026, 10, 12));
    final parked = ItemClassification.of(await read(id));
    await items.moveTo(id, ItemStatus.done);
    await items.classify(id, parked);
    final item = await read(id);
    expect(item.status, ItemStatus.scheduled);
    expect(item.revisitAt, dateOnlyToStored(LocalDate(2026, 10, 12)));
  });

  test('returning: scheduled items whose date came go to the inbox and '
      'keep the date', () async {
    final due = await capture('vandaag terug');
    final earlier = await capture('al eerder terug');
    final later = await capture('nog weg');
    final noDate = await capture('gepland zonder datum');
    await items.revisitOn(due, today);
    await items.revisitOn(earlier, today.addDays(-3));
    await items.revisitOn(later, today.addDays(1));
    await items.moveTo(noDate, ItemStatus.scheduled);

    final back = await items.returnRevisited(today);
    expect(back.toSet(), {due, earlier});
    expect((await read(due)).status, ItemStatus.inbox);
    expect((await read(due)).revisitAt, dateOnlyToStored(today));
    expect((await read(earlier)).status, ItemStatus.inbox);
    expect((await read(later)).status, ItemStatus.scheduled);
    expect((await read(noDate)).status, ItemStatus.scheduled);

    // Once back, nothing returns again.
    expect(await items.returnRevisited(today), isEmpty);
    final log = await (storage.database.select(
      storage.database.changeLog,
    )..where((e) => e.entityId.equals(due))).get();
    expect(log.last.payload, contains('inbox'));
  });

  test('returning leaves trashed items and processed ones alone', () async {
    final trashed = await capture('in de prullenbak');
    await items.revisitOn(trashed, today);
    await items.moveToTrash(trashed);

    final processed = await capture('verwerkt');
    await items.revisitOn(processed, today.addDays(1));
    // Returned on an earlier day, then sorted into a task: the old date
    // stays, the item does not come back.
    await items.returnRevisited(today.addDays(1));
    await items.classify(
      processed,
      ItemClassification.of(
        await read(processed),
      ).withStatus(ItemStatus.active),
    );

    expect(await items.returnRevisited(today.addDays(5)), isEmpty);
    expect((await read(processed)).status, ItemStatus.active);
    final row = await (storage.database.select(
      storage.database.items,
    )..where((i) => i.id.equals(trashed))).getSingle();
    expect(row.status, ItemStatus.scheduled);
  });

  test('a date stored at another moment of the day still counts by its '
      'day', () async {
    final id = await capture('ander tijdstip');
    final db = storage.database;
    await (db.update(db.items)..where((i) => i.id.equals(id))).write(
      ItemsCompanion(
        status: const Value(ItemStatus.scheduled),
        revisitAt: Value(DateTime.utc(2026, 10, 9, 23, 30)),
      ),
    );
    expect(await items.returnRevisited(today.addDays(-1)), isEmpty);
    expect(await items.returnRevisited(today), [id]);
  });
}

extension on ItemClassification {
  ItemClassification withStatus(ItemStatus status) => ItemClassification(
    type: type,
    status: status,
    requesterId: requesterId,
    waitingOnId: waitingOnId,
    revisitAt: revisitAt,
  );
}
