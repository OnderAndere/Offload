// dart format width=80
// ignore_for_file: unused_local_variable, unused_import
import 'package:drift/drift.dart' hide isNull;
import 'package:drift_dev/api/migrations_native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/search/drift_search_index.dart';
import 'generated/schema.dart';

import 'generated/schema_v1.dart' as v1;
import 'generated/schema_v2.dart' as v2;

void main() {
  driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  late SchemaVerifier verifier;

  setUpAll(() {
    verifier = SchemaVerifier(GeneratedHelper());
  });

  group('simple database migrations', () {
    // These simple tests verify all possible schema updates with a simple (no
    // data) migration. This is a quick way to ensure that written database
    // migrations properly alter the schema.
    const versions = GeneratedHelper.versions;
    for (final (i, fromVersion) in versions.indexed) {
      group('from $fromVersion', () {
        for (final toVersion in versions.skip(i + 1)) {
          test('to $toVersion', () async {
            final schema = await verifier.schemaAt(fromVersion);
            final db = AppDatabase(schema.newConnection());
            await verifier.migrateAndValidate(db, toVersion);
            await db.close();
          });
        }
      });
    }
  });

  test('v1 to v2: existing items and people become searchable', () async {
    final schema = await verifier.schemaAt(1);
    final raw = schema.rawDatabase;
    raw.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source) VALUES "
      "('i1', 'h', 'Keuring van de afvoer', 'inbox', 'app'), "
      "('i2', 'h', 'al weg', 'inbox', 'app')",
    );
    raw.execute(
      "UPDATE items SET deleted_at = '2026-09-27T12:00:00.000Z' "
      "WHERE id = 'i2'",
    );
    raw.execute("INSERT INTO people (id, hlc, name) VALUES ('p1', 'h', 'Jan')");
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 2);

    // Nothing is indexed during the migration: only queued, live rows only.
    final queued = await db
        .customSelect('SELECT entity, entity_id FROM search_pending')
        .get();
    expect(
      {
        for (final r in queued)
          '${r.read<String>('entity')}/${r.read<String>('entity_id')}',
      },
      {'items/i1', 'people/p1'},
    );
    // The indexer of today reads the columns of today: on to the latest
    // version first; no later step queues or indexes anything.
    final latest = AppDatabase(schema.newConnection());
    addTearDown(latest.close);
    await verifier.migrateAndValidate(latest, GeneratedHelper.versions.last);
    final index = DriftSearchIndex(latest);
    await index.processPending();
    expect((await index.search('keur')).single.id, 'i1');
    expect((await index.search('jan')).single.id, 'p1');

    // The existing data itself is untouched.
    final items = await latest.select(latest.items).get();
    expect(
      items.map((i) => i.rawText),
      containsAll(['Keuring van de afvoer', 'al weg']),
    );
  });

  test(
    'v1 to v2 stopped halfway leaves nothing behind (review T2.5)',
    () async {
      final schema = await verifier.schemaAt(1);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO items (id, hlc, raw_text, status, source) VALUES "
        "('i1', 'h', 'Keuring', 'inbox', 'app')",
      );
      // A leftover object that makes the last statement of the step fail,
      // after the tables and triggers were created.
      raw.execute('CREATE TABLE search_pending (other TEXT)');

      final broken = AppDatabase(schema.newConnection());
      await expectLater(
        broken.customSelect('SELECT 1').get(),
        throwsA(anything),
      );
      await broken.close();

      expect(raw.select('PRAGMA user_version').single.values.single, 1);
      expect(
        raw.select("SELECT name FROM sqlite_master WHERE type = 'trigger'"),
        isEmpty,
      );
      expect(
        raw.select(
          "SELECT name FROM sqlite_master "
          "WHERE name IN ('search_index', 'search_map')",
        ),
        isEmpty,
      );

      // Once the cause is gone, the next start migrates as normal.
      raw.execute('DROP TABLE search_pending');
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);
      await verifier.migrateAndValidate(db, 2);
      final queued = await db
          .customSelect('SELECT entity_id FROM search_pending')
          .get();
      expect(queued.single.read<String>('entity_id'), 'i1');
    },
  );

  test('v3 to v4: existing projects stay, not archived', () async {
    final schema = await verifier.schemaAt(3);
    schema.rawDatabase.execute(
      "INSERT INTO contexts (id, hlc, name) VALUES ('c1', 'h', 'Renovatie')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 4);

    final project = await db.select(db.contexts).getSingle();
    expect(project.name, 'Renovatie');
    expect(project.archivedAt, isNull);
  });

  test('v4 to v5: existing people stay, merged into nobody', () async {
    final schema = await verifier.schemaAt(4);
    schema.rawDatabase.execute(
      "INSERT INTO people (id, hlc, name) VALUES ('p1', 'h', 'Jan')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 5);

    final person = await db.select(db.people).getSingle();
    expect(person.name, 'Jan');
    expect(person.mergedIntoId, isNull);
  });

  test('v5 to v6: existing items stay, never reviewed', () async {
    final schema = await verifier.schemaAt(5);
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source) "
      "VALUES ('i1', 'h', 'Bel Jan', 'inbox', 'app')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 6);

    final item = await db.select(db.items).getSingle();
    expect(item.rawText, 'Bel Jan');
    expect(item.reviewedAt, isNull);
  });

  test(
    'v6 to v7: people stay as they were; contact details are found',
    () async {
      final schema = await verifier.schemaAt(6);
      final raw = schema.rawDatabase;
      raw.execute(
        "INSERT INTO people (id, hlc, name, birthday_day, birthday_month, note) "
        "VALUES ('p1', 'h', 'Олена Коваль', 14, 3, 'Fietst graag')",
      );
      raw.execute(
        "INSERT INTO person_aliases (id, hlc, person_id, alias) "
        "VALUES ('a1', 'h', 'p1', 'Лена')",
      );
      final db = AppDatabase(schema.newConnection());
      addTearDown(db.close);

      await verifier.migrateAndValidate(db, 7);

      final person = await db.select(db.people).getSingle();
      expect(person.name, 'Олена Коваль');
      expect(person.birthdayDay, 14);
      expect(person.note, 'Fietst graag');
      expect(person.organisation, isNull);
      expect(person.jobTitle, isNull);
      expect(await db.select(db.contactDetails).get(), isEmpty);
      expect((await db.select(db.personAliases).getSingle()).alias, 'Лена');

      // The new triggers queue the person for search.
      await db.customStatement('DELETE FROM search_pending');
      await db.customStatement(
        "INSERT INTO contact_details "
        "(id, hlc, person_id, kind, value, label, sort_order) "
        "VALUES ('c1', 'h', 'p1', 'phone', '06-12 34 56 78', 'Робота', 0)",
      );
      await db.customStatement(
        "UPDATE people SET organisation = 'Тенісний клуб' WHERE id = 'p1'",
      );
      final index = DriftSearchIndex(db);
      await index.processPending();
      expect((await index.search('0612')).single.id, 'p1');
      expect((await index.search('робота')).single.id, 'p1');
      expect((await index.search('тенісний')).single.id, 'p1');
    },
  );

  test('v7 to v8: existing items stay, without priority', () async {
    final schema = await verifier.schemaAt(7);
    schema.rawDatabase.execute(
      "INSERT INTO contexts (id, hlc, name) VALUES ('c1', 'h', 'Tuin')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source, context_id) "
      "VALUES ('i1', 'h', 'Snoeien *hoog', 'active', 'app', 'c1')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 8);

    final item = await db.select(db.items).getSingle();
    expect(item.rawText, 'Snoeien *hoog');
    expect(item.contextId, 'c1');
    // The token processor sets it after the start, not the migration.
    expect(item.priority, isNull);
  });

  test('v8 to v9: existing items stay, without a commitment', () async {
    final schema = await verifier.schemaAt(8);
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source, priority) "
      "VALUES ('i1', 'h', 'Offerte *hoog', 'waiting', 'app', 'high')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 9);

    final item = await db.select(db.items).getSingle();
    expect(item.rawText, 'Offerte *hoog');
    expect(item.priority?.name, 'high');
    expect(item.askedAt, isNull);
    expect(item.promise, isNull);
    expect(item.expectedAt, isNull);
  });

  test('v9 to v10: existing items stay; no notes yet', () async {
    final schema = await verifier.schemaAt(9);
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source, promise) "
      "VALUES ('i1', 'h', 'Offerte', 'active', 'app', 'Offerte sturen')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 10);

    final item = await db.select(db.items).getSingle();
    expect(item.promise, 'Offerte sturen');
    expect(await db.select(db.snapshots).get(), isEmpty);
  });

  test('v10 to v11: existing links stay, without a label', () async {
    final schema = await verifier.schemaAt(10);
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source) VALUES "
      "('i1', 'h', 'Een', 'inbox', 'app'), ('i2', 'h', 'Twee', 'inbox', 'app')",
    );
    schema.rawDatabase.execute(
      "INSERT INTO item_links (id, hlc, from_item_id, to_item_id, kind) "
      "VALUES ('l1', 'h', 'i1', 'i2', 'related')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 11);

    final link = await db.select(db.itemLinks).getSingle();
    expect(link.kind, 'related');
    expect(link.label, isNull);
  });

  test('v11 to v12: items stay, the records table starts empty', () async {
    final schema = await verifier.schemaAt(11);
    schema.rawDatabase.execute(
      "INSERT INTO items (id, hlc, raw_text, status, source, due_at) VALUES "
      "('i1', 'h', 'Hardlopen !wekelijks', 'active', 'app', "
      "'2026-10-06T00:00:00.000Z')",
    );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 12);

    final item = await db.select(db.items).getSingle();
    expect(item.rawText, 'Hardlopen !wekelijks');
    expect(item.dueAt, DateTime.utc(2026, 10, 6));
    expect(await db.select(db.itemCompletions).get(), isEmpty);
  });

  test('v12 to v13: no table changes, attachments stay (T7.2b)', () async {
    final schema = await verifier.schemaAt(12);
    schema.rawDatabase
      ..execute(
        "INSERT INTO items (id, hlc, raw_text, status, source) VALUES "
        "('i1', 'h', 'Kozijnen', 'inbox', 'app')",
      )
      ..execute(
        "INSERT INTO attachments (id, hlc, item_id, mime_type, size_bytes, "
        "storage_path, pipeline_version) VALUES "
        "('a1', 'h', 'i1', 'audio/mp4', 1200, 'attachments/a1', 0)",
      );
    final db = AppDatabase(schema.newConnection());
    addTearDown(db.close);

    await verifier.migrateAndValidate(db, 13);

    final attachment = await db.select(db.attachments).getSingle();
    expect(attachment.storagePath, 'attachments/a1');
    expect(attachment.sizeBytes, 1200);
  });
}
