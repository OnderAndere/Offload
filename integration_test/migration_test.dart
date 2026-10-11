import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/crypto/crypto_service.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

import '../test/drift/app_database/generated/schema_v6.dart' as v6;

/// Schema v6 to today's schema on a real device: v7 (T3.5, REQ-038), v8
/// (T10.5, REQ-050), v9 (T10.1, REQ-046/047), v10 (T10.3, REQ-049) and v11
/// (T10.9, REQ-054). An encrypted database made at v6 with real data is
/// opened by the app of today and migrated, in the sqlite3mc build that
/// ships. Uses a separate test key.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_migration_key')
      : WindowsKeyStore(
          directory: keyDir,
          name: 'integration_test_migration_key',
        );

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_migration');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  testWidgets('v6 to today keeps people and items, and finds contact details', (
    tester,
  ) async {
    final file = File('${dir.path}${Platform.pathSeparator}offload.db');
    final crypto = await CryptoService.unlock(
      newStore(),
      existingDataFound: false,
    );
    final key = crypto.deriveKey(KeyPurpose.database);

    final old = v6.DatabaseAtV6(openEncryptedDatabase(file, key));
    await old.customStatement(
      "INSERT INTO people (id, hlc, name, birthday_day, birthday_month, note) "
      "VALUES ('p1', 'h', 'Олена Коваль', 14, 3, 'Fietst graag')",
    );
    await old.customStatement(
      "INSERT INTO items (id, hlc, raw_text, status, source, requester_id) "
      "VALUES ('i1', 'h', 'Bel @Олена over de tuin', 'inbox', 'app', 'p1')",
    );
    expect(
      (await old.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      6,
    );
    await old.close();

    final db = AppDatabase(openEncryptedDatabase(file, key));
    addTearDown(db.close);
    expect(
      (await db.customSelect('PRAGMA user_version').getSingle())
          .data
          .values
          .single,
      db.schemaVersion,
    );
    final person = await db.select(db.people).getSingle();
    expect(person.name, 'Олена Коваль');
    expect(person.birthdayDay, 14);
    expect(person.organisation, isNull);
    final item = await db.select(db.items).getSingle();
    expect(item.requesterId, 'p1');
    expect(item.priority, isNull);
    expect(item.askedAt, isNull);
    expect(item.promise, isNull);
    expect(item.expectedAt, isNull);
    // v10: the table of "Where was I" is there, empty.
    expect(await db.select(db.snapshots).get(), isEmpty);
    // v11: links have a label column; none were made before.
    expect(await db.select(db.itemLinks).get(), isEmpty);
    await db.customStatement(
      "INSERT INTO item_links (id, hlc, from_item_id, to_item_id, kind, label) "
      "VALUES ('l1', 'h', 'i1', 'i1', 'link', 'Плитка')",
    );
    expect((await db.select(db.itemLinks).getSingle()).label, 'Плитка');
    // v12: the records of recurring tasks (T4.7), empty, and writable.
    expect(await db.select(db.itemCompletions).get(), isEmpty);
    await db.customStatement(
      "INSERT INTO item_completions "
      "(id, hlc, item_id, occurrence_on, completed_on) "
      "VALUES ('r1', 'h', 'i1', '2026-10-06T00:00:00.000Z', "
      "'2026-10-06T00:00:00.000Z')",
    );
    expect(
      (await db.select(db.itemCompletions).getSingle()).occurrenceOn,
      DateTime.utc(2026, 10, 6),
    );

    await db.customStatement(
      "INSERT INTO contact_details "
      "(id, hlc, person_id, kind, value, label, sort_order) "
      "VALUES ('c1', 'h', 'p1', 'phone', '06-12 34 56 78', 'Робота', 0)",
    );
    final index = DriftSearchIndex(db);
    await index.processPending();
    expect((await index.search('0612')).single.id, 'p1');
    expect((await index.search('робота')).single.id, 'p1');
  });
}
