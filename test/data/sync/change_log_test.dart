import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/tables.dart';
import 'package:offload/data/sync/change_log_format.dart';
import 'package:offload/data/sync/change_log_replayer.dart';
import 'package:offload/data/sync/change_log_writer.dart';
import 'package:offload/domain/ids/uuid_v7.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/people/contact_detail.dart';
import 'package:offload/domain/repeats/repeat.dart';
import 'package:offload/domain/sync/change_operation.dart';
import 'package:offload/domain/sync/hlc.dart';
import 'package:offload/domain/time/local_date.dart';

void main() {
  late AppDatabase db;
  late ChangeLogWriter writer;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    writer = ChangeLogWriter(
      db,
      clock: HlcClock(node: 'devicea'),
      ids: UuidV7Generator(),
    );
  });
  tearDown(() => db.close());

  Future<List<ChangeLogData>> log() => (db.select(
    db.changeLog,
  )..orderBy([(t) => OrderingTerm(expression: t.hlc)])).get();

  Future<String> addItem(String text) => writer.insert(
    db.items,
    ItemsCompanion(
      rawText: Value(text),
      status: const Value(ItemStatus.inbox),
      source: const Value(ItemSource.app),
    ),
  );

  Future<String> addPerson(String name) =>
      writer.insert(db.people, PeopleCompanion(name: Value(name)));

  group('ChangeLogWriter', () {
    test('insert logs every column with the format version', () async {
      final id = await addItem('Call Jan');

      final [entry] = await log();
      final item = await (db.select(
        db.items,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(entry.entity, 'items');
      expect(entry.entityId, id);
      expect(entry.operation, ChangeOperation.insert);
      expect(entry.hlc, item.hlc);
      expect(entry.formatVersion, changeLogFormatVersion);
      expect(changeLogFormatVersion, 1);
      final payload = decodePayload(entry.payload);
      expect(payload, {
        'raw_text': 'Call Jan',
        'title': null,
        'body': null,
        'type': null,
        'status': 'inbox',
        'source': 'app',
        'due_at': null,
        'revisit_at': null,
        'requester_id': null,
        'waiting_on_id': null,
        'context_id': null,
        'reviewed_at': null,
        'priority': null,
        'asked_at': null,
        'promise': null,
        'expected_at': null,
      });
    });

    test('update logs only the columns whose value changed', () async {
      final id = await addItem('Call Jan');

      final changed = await writer.update(
        db.items,
        id,
        ItemsCompanion(
          rawText: const Value('Call Jan'), // unchanged
          status: const Value(ItemStatus.active),
          dueAt: Value(DateTime.utc(2026, 10, 2, 9)),
        ),
      );

      expect(changed, isTrue);
      final entries = await log();
      expect(entries.last.operation, ChangeOperation.update);
      expect(decodePayload(entries.last.payload), {
        'status': 'active',
        'due_at': '2026-10-02T09:00:00.000Z',
      });
      final item = await (db.select(
        db.items,
      )..where((t) => t.id.equals(id))).getSingle();
      expect(item.hlc, entries.last.hlc);
      expect(
        Hlc.parse(entries.last.hlc).compareTo(Hlc.parse(entries.first.hlc)),
        greaterThan(0),
      );
    });

    test('an update that changes nothing writes nothing', () async {
      final id = await addItem('Call Jan');
      final before = await log();

      final changed = await writer.update(
        db.items,
        id,
        const ItemsCompanion(rawText: Value('Call Jan')),
      );

      expect(changed, isFalse);
      expect(await log(), hasLength(before.length));
      final item = await db.select(db.items).getSingle();
      expect(item.hlc, before.single.hlc);
    });

    test('insertWithId uses the given id and is logged like insert', () async {
      final id = UuidV7Generator().next();

      final inserted = await writer.insertWithId(
        db.items,
        id,
        const ItemsCompanion(
          rawText: Value('Call Jan'),
          status: Value(ItemStatus.inbox),
          source: Value(ItemSource.widget),
        ),
      );

      expect(inserted, isTrue);
      final entry = (await log()).single;
      expect(entry.entityId, id);
      expect(entry.operation, ChangeOperation.insert);
      expect(decodePayload(entry.payload)['source'], 'widget');
    });

    test('insertWithId writes nothing when the id exists', () async {
      final id = await addItem('Call Jan');
      final before = await log();

      final inserted = await writer.insertWithId(
        db.items,
        id,
        const ItemsCompanion(
          rawText: Value('Something else'),
          status: Value(ItemStatus.inbox),
          source: Value(ItemSource.widget),
        ),
      );

      expect(inserted, isFalse);
      expect(await log(), hasLength(before.length));
      expect((await db.select(db.items).getSingle()).rawText, 'Call Jan');
    });

    test('insertWithId refuses ids that are not version 7 UUIDs', () async {
      await expectLater(
        writer.insertWithId(
          db.items,
          '../items',
          const ItemsCompanion(rawText: Value('x')),
        ),
        throwsArgumentError,
      );
    });

    test('an update without columns fails as a Future', () async {
      final id = await addItem('Call Jan');

      // A failed Future, not a synchronous throw, so callers can await it.
      await expectLater(
        writer.update(db.items, id, const ItemsCompanion()),
        throwsArgumentError,
      );
    });

    test('delete sets a tombstone and logs only deleted_at', () async {
      final id = await addItem('Call Jan');

      await writer.delete(db.items, id);

      final item = await db.select(db.items).getSingle();
      expect(item.deletedAt, isNotNull);
      expect(item.deletedAt!.isUtc, isTrue);
      final entry = (await log()).last;
      expect(entry.operation, ChangeOperation.delete);
      expect(decodePayload(entry.payload).keys, ['deleted_at']);
      expect(item.hlc, entry.hlc);
    });

    test('a deleted or missing entity cannot be changed', () async {
      final id = await addItem('Call Jan');
      await writer.delete(db.items, id);

      expect(
        () => writer.update(
          db.items,
          id,
          const ItemsCompanion(title: Value('x')),
        ),
        throwsStateError,
      );
      expect(() => writer.delete(db.items, id), throwsStateError);
      expect(() => writer.delete(db.items, 'missing'), throwsStateError);
    });

    test(
      'restore clears the tombstone and logs only that (AC REQ-010)',
      () async {
        final id = await addItem('Call Jan');
        await writer.delete(db.items, id);

        await writer.restore(db.items, id);

        final item = await db.select(db.items).getSingle();
        expect(item.deletedAt, isNull);
        final entry = (await log()).last;
        expect(entry.operation, ChangeOperation.restore);
        expect(decodePayload(entry.payload), {'deleted_at': null});
        expect(item.hlc, entry.hlc);
        // Only a deleted entity can be restored.
        expect(() => writer.restore(db.items, id), throwsStateError);
        expect(() => writer.restore(db.items, 'missing'), throwsStateError);
      },
    );

    test('managed columns cannot be set by the caller', () async {
      for (final row in [
        const ItemsCompanion(id: Value('x')),
        const ItemsCompanion(hlc: Value('x')),
        ItemsCompanion(deletedAt: Value(DateTime.utc(2026))),
      ]) {
        expect(() => writer.insert(db.items, row), throwsArgumentError);
      }
    });

    test('local times are refused; timestamps are stored in UTC', () async {
      final id = await addItem('Call Jan');

      expect(
        () => writer.update(
          db.items,
          id,
          ItemsCompanion(dueAt: Value(DateTime(2026, 10, 2, 9))),
        ),
        throwsArgumentError,
      );
    });

    test('a failed write leaves neither a row nor a log entry', () async {
      await expectLater(
        writer.insert(
          db.attachments,
          const AttachmentsCompanion(
            itemId: Value('missing-item'),
            mimeType: Value('image/jpeg'),
            sizeBytes: Value(1),
            storagePath: Value('photos/x'),
            pipelineVersion: Value(1),
          ),
        ),
        throwsA(isA<SqliteException>()),
      );

      expect(await db.select(db.attachments).get(), isEmpty);
      expect(await log(), isEmpty);
    });
  });

  group('attachment owner (REQ-041, DD-006)', () {
    AttachmentsCompanion attachment({String? itemId, String? personId}) =>
        AttachmentsCompanion(
          itemId: Value(itemId),
          personId: Value(personId),
          mimeType: const Value('image/jpeg'),
          sizeBytes: const Value(1),
          storagePath: const Value('photos/x'),
          pipelineVersion: const Value(1),
        );

    test('is an item or a person', () async {
      final item = await addItem('Whiteboard');
      final person = await addPerson('Jan');

      await writer.insert(db.attachments, attachment(itemId: item));
      await writer.insert(db.attachments, attachment(personId: person));

      expect(await db.select(db.attachments).get(), hasLength(2));
    });

    test('is never both and never neither', () async {
      final item = await addItem('Whiteboard');
      final person = await addPerson('Jan');

      expect(
        () => writer.insert(
          db.attachments,
          attachment(itemId: item, personId: person),
        ),
        throwsA(isA<SqliteException>()),
      );
      expect(
        () => writer.insert(db.attachments, attachment()),
        throwsA(isA<SqliteException>()),
      );
    });
  });

  group('ChangeLogReplayer (AC REQ-037)', () {
    late AppDatabase target;

    setUp(() => target = AppDatabase(NativeDatabase.memory()));
    tearDown(() => target.close());

    /// Every synchronisable table plus the change log, row by row.
    Future<Map<String, List<Map<String, Object?>>>> contents(
      AppDatabase d,
    ) async => {
      for (final t in d.allTables)
        if (t is SyncColumns || t == d.changeLog)
          t.actualTableName: [
            for (final row
                in await d
                    .customSelect(
                      'SELECT * FROM "${t.actualTableName}" ORDER BY id',
                    )
                    .get())
              row.data,
          ],
    };

    /// Changes across every synchronisable table: inserts, updates and
    /// tombstones, including rows that refer to each other.
    Future<void> makeChanges() async {
      final jan = await writer.insert(
        db.people,
        const PeopleCompanion(
          name: Value('Jan'),
          birthdayDay: Value(14),
          birthdayMonth: Value(3),
        ),
      );
      final alias = await writer.insert(
        db.personAliases,
        PersonAliasesCompanion(personId: Value(jan), alias: const Value('JJ')),
      );
      final phone = await writer.insert(
        db.contactDetails,
        ContactDetailsCompanion(
          personId: Value(jan),
          kind: const Value(ContactKind.phone),
          value: const Value('06-12345678'),
          label: const Value('mobile'),
          sortOrder: const Value(0),
        ),
      );
      final mail = await writer.insert(
        db.contactDetails,
        ContactDetailsCompanion(
          personId: Value(jan),
          kind: const Value(ContactKind.email),
          value: const Value('jan@example.org'),
          sortOrder: const Value(0),
        ),
      );
      final work = await writer.insert(
        db.contexts,
        const ContextsCompanion(name: Value('Werk')),
      );
      final renovatie = await writer.insert(
        db.contexts,
        ContextsCompanion(
          name: const Value('Renovatie'),
          parentId: Value(work),
        ),
      );
      final tag = await writer.insert(
        db.tags,
        const TagsCompanion(name: Value('renovatie')),
      );
      final call = await writer.insert(
        db.items,
        ItemsCompanion(
          rawText: const Value('Call @Jan about #renovatie !fri'),
          status: const Value(ItemStatus.inbox),
          source: const Value(ItemSource.widget),
          requesterId: Value(jan),
          contextId: Value(renovatie),
          dueAt: Value(DateTime.utc(2026, 10, 2, 9)),
        ),
      );
      final note = await addItem('Whiteboard photo');
      await writer.insert(
        db.itemLinks,
        ItemLinksCompanion(
          fromItemId: Value(call),
          toItemId: Value(note),
          kind: const Value('related'),
        ),
      );
      // A `[[…]]` link with its label, removed and restored (T10.9).
      final link = await writer.insert(
        db.itemLinks,
        ItemLinksCompanion(
          fromItemId: Value(note),
          toItemId: Value(call),
          kind: const Value('link'),
          label: const Value('Подзвонити Яну'),
        ),
      );
      await writer.delete(db.itemLinks, link);
      await writer.restore(db.itemLinks, link);
      // A completed time of a recurring task under its UUIDv5 (T4.7):
      // inserted, undone and completed again on another day.
      final time = completionId(call, LocalDate(2026, 10, 2));
      ItemCompletionsCompanion doneOn(int day) => ItemCompletionsCompanion(
        itemId: Value(call),
        occurrenceOn: Value(DateTime.utc(2026, 10, 2)),
        completedOn: Value(DateTime.utc(2026, 10, day)),
      );
      await writer.put(db.itemCompletions, time, doneOn(2));
      await writer.delete(db.itemCompletions, time);
      await writer.put(db.itemCompletions, time, doneOn(3));
      final (first, second) = call.compareTo(note) < 0
          ? (call, note)
          : (note, call);
      await writer.insert(
        db.duplicateDismissals,
        DuplicateDismissalsCompanion(
          itemId: Value(first),
          otherItemId: Value(second),
        ),
      );
      await writer.insert(
        db.attachments,
        AttachmentsCompanion(
          itemId: Value(note),
          mimeType: const Value('image/jpeg'),
          sizeBytes: const Value(123456),
          storagePath: const Value('photos/a'),
          pipelineVersion: const Value(1),
        ),
      );
      await writer.insert(
        db.attachments,
        AttachmentsCompanion(
          personId: Value(jan),
          mimeType: const Value('image/jpeg'),
          sizeBytes: const Value(65432),
          storagePath: const Value('photos/b'),
          pipelineVersion: const Value(1),
        ),
      );
      await writer.update(
        db.items,
        call,
        const ItemsCompanion(
          status: Value(ItemStatus.waiting),
          type: Value(ItemType.request),
          title: Value('Call Jan'),
        ),
      );
      await writer.update(
        db.people,
        jan,
        const PeopleCompanion(
          note: Value('Prefers *mornings*'),
          organisation: Value('Tennisclub'),
          jobTitle: Value('Voorzitter'),
        ),
      );
      await writer.update(
        db.contactDetails,
        phone,
        const ContactDetailsCompanion(label: Value('Робота')),
      );
      await writer.delete(db.contactDetails, mail);
      // "Where was I" on an item and on a project; one resumed (T10.3).
      final where = await writer.insert(
        db.snapshots,
        SnapshotsCompanion(
          itemId: Value(call),
          nextStep: const Value('Jan bellen over de offerte'),
        ),
      );
      await writer.update(
        db.snapshots,
        where,
        SnapshotsCompanion(
          inMind: const Value('Eerst de prijzen naast elkaar'),
          resumedAt: Value(DateTime.utc(2026, 10, 3, 8)),
        ),
      );
      await writer.insert(
        db.snapshots,
        SnapshotsCompanion(
          contextId: Value(renovatie),
          inMind: const Value('Кухня спочатку'),
        ),
      );
      await writer.update(
        db.personAliases,
        alias,
        const PersonAliasesCompanion(alias: Value('Jantje')),
      );
      await writer.update(
        db.items,
        call,
        const ItemsCompanion(title: Value(null)),
      );
      await writer.delete(db.tags, tag);
      await writer.delete(db.items, note);
      // Out of the trash again (undo).
      await writer.restore(db.tags, tag);
    }

    test(
      'replaying the log on an empty database gives the same content',
      () async {
        await makeChanges();

        await ChangeLogReplayer(target).replay(await log());

        expect(await contents(target), await contents(db));
      },
    );

    test('the round trip covers every synchronisable table', () async {
      await makeChanges();

      final logged = {for (final e in await log()) e.entity};
      final syncTables = {
        for (final t in db.allTables)
          if (t is SyncColumns) t.actualTableName,
      };
      expect(logged, syncTables);
    });

    test('the order in which entries arrive does not matter', () async {
      await makeChanges();

      final shuffled = (await log()).reversed;
      await ChangeLogReplayer(target).replay(shuffled);

      expect(await contents(target), await contents(db));
    });

    test('an unknown format version is refused and changes nothing', () async {
      await addItem('Call Jan');
      final [entry] = await log();

      await expectLater(
        ChangeLogReplayer(target).replay([entry.copyWith(formatVersion: 2)]),
        throwsFormatException,
      );
      expect(await target.select(target.items).get(), isEmpty);
      expect(await target.select(target.changeLog).get(), isEmpty);
    });

    test('a failing entry rolls back the whole replay', () async {
      await makeChanges();
      final entries = await log();
      final broken = entries.last.copyWith(entityId: 'missing');

      await expectLater(
        ChangeLogReplayer(target).replay([...entries..removeLast(), broken]),
        throwsStateError,
      );
      for (final rows in (await contents(target)).values) {
        expect(rows, isEmpty);
      }
    });

    test('payloads cannot name other columns or tables', () async {
      await addItem('Call Jan');
      final [entry] = await log();

      for (final bad in [
        entry.copyWith(hlc: 'not-an-hlc'),
        entry.copyWith(entity: 'local_state'),
        entry.copyWith(entity: 'tokens'),
        entry.copyWith(payload: '{"raw_text": "x", "nope\\" = 1; --": 1}'),
        entry.copyWith(payload: '{"raw_text": "x", "hlc": "y"}'),
        entry.copyWith(payload: '["raw_text"]'),
        entry.copyWith(payload: '{"raw_text": 1.5}'),
      ]) {
        await expectLater(
          ChangeLogReplayer(target).replay([bad]),
          throwsA(anyOf(isFormatException, isArgumentError)),
          reason: '${bad.entity} ${bad.payload}',
        );
      }
      expect(await target.select(target.items).get(), isEmpty);
    });
  });
}
