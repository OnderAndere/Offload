import 'dart:async';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/sync/change_log_format.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item.dart' as domain;
import 'package:offload/domain/items/item_classification.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/token_processing.dart';

import '../../fakes/test_storage.dart';

void main() {
  late AppStorage storage;
  late DriftItemRepository repository;

  setUp(() async {
    storage = await openTestStorage();
    repository = DriftItemRepository(storage);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  group('capture (REQ-001, REQ-018)', () {
    test('stores the text unchanged as an inbox item', () async {
      const text = '  bel Jan @Jan !vr\nover de markt  ';

      final id = await repository.capture(text, source: ItemSource.app);

      final row = await db().select(db().items).getSingle();
      expect(row.id, id);
      expect(row.rawText, text);
      expect(row.status, ItemStatus.inbox);
      expect(row.source, ItemSource.app);
      expect(row.type, isNull);
      expect(row.deletedAt, isNull);
    });

    test('writes through the change log (REQ-008, REQ-037)', () async {
      final id = await repository.capture('Call Jan', source: ItemSource.app);

      final entry = await db().select(db().changeLog).getSingle();
      final row = await db().select(db().items).getSingle();
      expect(entry.entity, 'items');
      expect(entry.entityId, id);
      expect(entry.operation, ChangeOperation.insert);
      expect(entry.hlc, row.hlc);
      expect(decodePayload(entry.payload)['raw_text'], 'Call Jan');
    });

    test('refuses text without visible characters', () async {
      await expectLater(
        repository.capture('  \n ', source: ItemSource.app),
        throwsArgumentError,
      );
      expect(await db().select(db().items).get(), isEmpty);
      expect(await db().select(db().changeLog).get(), isEmpty);
    });
  });

  group('captureAll (the thoughts of a photo, T6a.5)', () {
    test('stores each text as an inbox item with its source, in order, '
        'through the change log', () async {
      final ids = await repository.captureAll([
        '@Anna bellen !vr',
        'kweekbak bouwen #tuin',
      ], source: ItemSource.handwriting);

      expect(ids, hasLength(2));
      final rows = await db().select(db().items).get();
      final byId = {for (final row in rows) row.id: row};
      expect(byId[ids[0]]!.rawText, '@Anna bellen !vr');
      expect(byId[ids[1]]!.rawText, 'kweekbak bouwen #tuin');
      for (final row in rows) {
        expect(row.status, ItemStatus.inbox);
        expect(row.source, ItemSource.handwriting);
      }
      expect(ids[0].compareTo(ids[1]), lessThan(0), reason: 'UUIDv7 order');
      expect(await db().select(db().changeLog).get(), hasLength(2));
    });

    test('one text without characters: nothing is stored', () async {
      await expectLater(
        repository.captureAll(['zaaien', '  '], source: ItemSource.handwriting),
        throwsArgumentError,
      );
      expect(await db().select(db().items).get(), isEmpty);
      expect(await db().select(db().changeLog).get(), isEmpty);
    });

    test('nothing to store stores nothing', () async {
      expect(
        await repository.captureAll(const [], source: ItemSource.handwriting),
        isEmpty,
      );
    });
  });

  group('captureWithId (captures from outside the app)', () {
    final id = UuidV7Generator().next();

    test('stores the capture under the given id', () async {
      final stored = await repository.captureWithId(
        id,
        'Bel Jan',
        source: ItemSource.widget,
      );

      expect(stored, isTrue);
      final row = await db().select(db().items).getSingle();
      expect(row.id, id);
      expect(row.rawText, 'Bel Jan');
      expect(row.source, ItemSource.widget);
      expect(row.status, ItemStatus.inbox);
    });

    test('the same capture twice is stored once, logged once', () async {
      await repository.captureWithId(id, 'Bel Jan', source: ItemSource.widget);

      final again = await repository.captureWithId(
        id,
        'Bel Jan',
        source: ItemSource.widget,
      );

      expect(again, isFalse);
      expect(await db().select(db().items).get(), hasLength(1));
      expect(await db().select(db().changeLog).get(), hasLength(1));
    });

    test('a deleted item is not brought back', () async {
      await repository.captureWithId(id, 'Bel Jan', source: ItemSource.widget);
      await storage.writer.delete(db().items, id);

      final again = await repository.captureWithId(
        id,
        'Bel Jan',
        source: ItemSource.widget,
      );

      expect(again, isFalse);
      expect(await repository.watchInbox().first, isEmpty);
    });

    test('refuses an id that is not a version 7 UUID', () async {
      for (final bad in [
        'not-an-id',
        '0192a1b2-c3d4-4000-8000-000000000000',
        '0192A1B2-C3D4-7000-8000-000000000000',
      ]) {
        await expectLater(
          repository.captureWithId(bad, 'x', source: ItemSource.widget),
          throwsArgumentError,
          reason: bad,
        );
      }
      expect(await db().select(db().items).get(), isEmpty);
    });

    test('refuses text without visible characters', () async {
      await expectLater(
        repository.captureWithId(id, ' \n', source: ItemSource.widget),
        throwsArgumentError,
      );
    });
  });

  group('watchInbox', () {
    test('lists inbox items, newest capture first', () async {
      await repository.capture('first', source: ItemSource.app);
      await Future<void>.delayed(const Duration(milliseconds: 2));
      await repository.capture('second', source: ItemSource.widget);

      final inbox = await repository.watchInbox().first;

      expect([for (final i in inbox) i.rawText], ['second', 'first']);
      expect(inbox.first.source, ItemSource.widget);
      expect(inbox.first.status, ItemStatus.inbox);
    });

    test('leaves out processed and deleted items', () async {
      final active = await repository.capture('active', source: ItemSource.app);
      final deleted = await repository.capture(
        'deleted',
        source: ItemSource.app,
      );
      await repository.capture('kept', source: ItemSource.app);
      await storage.writer.update(
        db().items,
        active,
        const ItemsCompanion(status: Value(ItemStatus.active)),
      );
      await storage.writer.delete(db().items, deleted);

      final inbox = await repository.watchInbox().first;

      expect([for (final i in inbox) i.rawText], ['kept']);
    });

    test('emits again when an item is captured', () async {
      final updates = StreamIterator(repository.watchInbox());
      addTearDown(updates.cancel);

      expect(await updates.moveNext(), isTrue);
      expect(updates.current, isEmpty);

      await repository.capture('Call Jan', source: ItemSource.app);

      expect(await updates.moveNext(), isTrue);
      expect(
        [for (final domain.Item i in updates.current) i.rawText],
        ['Call Jan'],
      );
    });
  });

  group('editing in the item detail (T2.3, DD-018)', () {
    Future<Item> row(String id) =>
        (db().select(db().items)..where((i) => i.id.equals(id))).getSingle();

    test(
      'the text is stored exactly as typed; empty text is refused',
      () async {
        final id = await repository.capture('Bel Jan', source: ItemSource.app);

        await repository.editText(id, '  Bel Jan\nover de offerte  ');

        expect((await row(id)).rawText, '  Bel Jan\nover de offerte  ');
        expect(() => repository.editText(id, '   '), throwsArgumentError);
      },
    );

    test('an empty note is removed', () async {
      final id = await repository.capture('Bel Jan', source: ItemSource.app);

      await repository.editNote(id, 'Vorige offerte was 12k');
      expect((await row(id)).body, 'Vorige offerte was 12k');
      await repository.editNote(id, '  ');
      expect((await row(id)).body, isNull);
    });

    test('status follows the status machine', () async {
      final id = await repository.capture('Bel Jan', source: ItemSource.app);

      await repository.moveTo(id, ItemStatus.done);
      expect((await row(id)).status, ItemStatus.done);
      await repository.moveTo(id, ItemStatus.archived);
      expect(() => repository.moveTo(id, ItemStatus.inbox), throwsStateError);
      await repository.moveTo(id, ItemStatus.active);
      expect((await row(id)).status, ItemStatus.active);
    });

    test('the type can be set and cleared', () async {
      final id = await repository.capture('Bel Jan', source: ItemSource.app);

      await repository.setType(id, ItemType.task);
      expect((await row(id)).type, ItemType.task);
      await repository.setType(id, null);
      expect((await row(id)).type, isNull);
    });

    test('trash and undo; every step is in the change log', () async {
      final id = await repository.capture('Bel Jan', source: ItemSource.app);

      await repository.moveToTrash(id);
      expect(await repository.watchItem(id).first, isNull);
      await repository.restoreFromTrash(id);
      expect((await repository.watchItem(id).first)!.rawText, 'Bel Jan');

      final operations = [
        for (final e in await (db().select(
          db().changeLog,
        )..where((e) => e.entityId.equals(id))).get())
          e.operation,
      ];
      expect(operations, [
        ChangeOperation.insert,
        ChangeOperation.delete,
        ChangeOperation.restore,
      ]);
    });

    test('processed items show in the live list, not in the inbox', () async {
      final inbox = await repository.capture(
        'Nog doen',
        source: ItemSource.app,
      );
      final done = await repository.capture('Klaar', source: ItemSource.app);
      final trashed = await repository.capture('Weg', source: ItemSource.app);
      await repository.moveTo(done, ItemStatus.done);
      await repository.moveToTrash(trashed);

      expect(
        [for (final i in await repository.watchInbox().first) i.id],
        [inbox],
      );
      expect(
        [for (final i in await repository.watchLiveItems().first) i.id],
        [done, inbox],
      );
    });
  });

  group('classify (triage, REQ-010)', () {
    test(
      'sets type, status and people in one change; undo puts it back',
      () async {
        final id = await repository.capture('Offerte', source: ItemSource.app);
        final jan = await storage.writer.insert(
          db().people,
          const PeopleCompanion(name: Value('Jan')),
        );
        final before = ItemClassification.of(
          (await repository.watchItem(id).first)!,
        );
        await repository.classify(
          id,
          ItemClassification(
            type: ItemType.request,
            status: ItemStatus.active,
            requesterId: jan,
            waitingOnId: null,
          ),
        );
        final sorted = (await repository.watchItem(id).first)!;
        expect(sorted.type, ItemType.request);
        expect(sorted.status, ItemStatus.active);
        expect(sorted.requesterId, jan);
        final log = await (db().select(
          db().changeLog,
        )..where((c) => c.entityId.equals(id))).get();
        expect(log, hasLength(2), reason: 'the capture plus one change');

        // Undo puts the item back in the inbox, exactly as it was.
        await repository.classify(id, before);
        final back = (await repository.watchItem(id).first)!;
        expect(ItemClassification.of(back), before);
        expect(back.status, ItemStatus.inbox);
      },
    );
  });

  group('watchDueThrough (Today, DD-018 point 4)', () {
    final today = LocalDate(2026, 9, 28);

    Future<String> withDue(
      String text,
      LocalDate? due,
      ItemStatus status,
    ) async {
      final id = await repository.capture(text, source: ItemSource.app);
      await (db().update(db().items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(
          dueAt: Value(due == null ? null : dateOnlyToStored(due)),
          status: Value(status),
        ),
      );
      return id;
    }

    test(
      'open items due on the day or earlier, oldest deadline first',
      () async {
        await withDue('tomorrow', today.addDays(1), ItemStatus.active);
        await withDue('today', today, ItemStatus.inbox);
        await withDue('none', null, ItemStatus.active);
        await withDue('late', today.addDays(-2), ItemStatus.waiting);
        await withDue('done', today, ItemStatus.done);
        await withDue('archived', today.addDays(-1), ItemStatus.archived);
        final trashed = await withDue('trashed', today, ItemStatus.active);
        await repository.moveToTrash(trashed);

        final due = await repository.watchDueThrough(today).first;
        expect([for (final i in due) i.rawText], ['late', 'today']);
        expect(due.first.dueAt, dateOnlyToStored(today.addDays(-2)));
      },
    );

    test('emits again when a deadline changes', () async {
      final id = await withDue('later', today.addDays(3), ItemStatus.active);
      final seen = <List<String>>[];
      final sub = repository
          .watchDueThrough(today)
          .listen((items) => seen.add([for (final i in items) i.rawText]));
      await pumpEventQueue();
      await (db().update(db().items)..where((i) => i.id.equals(id))).write(
        ItemsCompanion(dueAt: Value(dateOnlyToStored(today))),
      );
      await pumpEventQueue();
      await sub.cancel();
      expect(seen.first, isEmpty);
      expect(seen.last, ['later']);
    });
  });
}
