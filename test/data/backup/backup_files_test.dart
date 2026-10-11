import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/backup/backup_files.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/backup/backup.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:sqlite3/sqlite3.dart';

/// Backups with a passphrase on the real SQLite3MultipleCiphers (T7.2,
/// REQ-014, DD-007): AEGIS with Argon2id, nothing in the clear.
void main() {
  const marker = 'Нова кухня PLAINTEXT_7f3a';
  const passphrase = "Олена's 100% зелене яблуко";
  late Directory dir;
  late File database;
  late File backup;
  late int schema;

  Uint8List key(int seed) =>
      Uint8List.fromList(List.generate(32, (i) => (i * 7 + seed) & 0xff));

  bool containsText(File file, String text) =>
      file.existsSync() &&
      latin1
          .decode(file.readAsBytesSync())
          .contains(latin1.decode(utf8.encode(text)));

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_backup_test');
    database = File('${dir.path}/offload.db');
    backup = File('${dir.path}/Offload-back-up.offload');
    final db = AppDatabase(openEncryptedDatabase(database, key(1)));
    schema = db.schemaVersion;
    final storage = await AppStorage.load(db);
    await DriftItemRepository(storage).capture(marker, source: ItemSource.app);
    await db.customStatement(
      "INSERT INTO local_state (key, value) VALUES ('backup_passphrase', ?)",
      [passphrase],
    );
    await db.close();
  });
  tearDown(() => dir.deleteSync(recursive: true));

  Future<void> write([String phrase = passphrase]) => BackupFiles.write(
    database: database,
    key: key(1),
    passphrase: phrase,
    target: backup,
  );

  test('the backup holds nothing in the clear', () async {
    await write();
    expect(backup.existsSync(), isTrue);
    expect(containsText(backup, marker), isFalse);
    expect(containsText(backup, 'SQLite format 3'), isFalse);
    expect(containsText(backup, 'зелене'), isFalse);
  });

  test('the passphrase opens it; it tells what it holds', () async {
    await write();
    final info = await BackupFiles.inspect(
      backup: backup,
      passphrase: passphrase,
      appSchemaVersion: schema,
    );
    expect(info.schemaVersion, schema);
    expect(info.items, 1);
    expect(info.newestChange, isNotNull);
  });

  test('another passphrase does not', () async {
    await write();
    await expectLater(
      BackupFiles.inspect(
        backup: backup,
        passphrase: 'een ander wachtwoord',
        appSchemaVersion: schema,
      ),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.wrongPassphrase,
        ),
      ),
    );
  });

  test('a file that is no backup is reported the same way', () async {
    backup.writeAsStringSync('geen back-up');
    await expectLater(
      BackupFiles.inspect(
        backup: backup,
        passphrase: passphrase,
        appSchemaVersion: schema,
      ),
      throwsA(isA<BackupException>()),
    );
  });

  test('the Argon2id settings are really used', () async {
    await write();
    // The library defaults (19 MiB, 2 passes) do not open it.
    final db = sqlite3.open(backup.path, mode: OpenMode.readOnly);
    addTearDown(db.close);
    db.execute("PRAGMA cipher = 'aegis'");
    db.execute("PRAGMA key = '${passphrase.replaceAll("'", "''")}'");
    expect(
      () => db.select('SELECT count(*) FROM sqlite_master'),
      throwsA(anything),
    );
  });

  test('a passphrase shorter than 12 characters is refused', () async {
    await expectLater(
      write('kort'),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.passphraseTooShort,
        ),
      ),
    );
    expect(backup.existsSync(), isFalse);
  });

  group('restoring', () {
    late File restored;
    setUp(() => restored = File('${dir.path}/offload.restore.db'));

    Future<BackupInfo> prepare({
      String phrase = passphrase,
      int? appSchema,
      Map<String, String> localState = const {'ui_language': 'nl'},
    }) => BackupFiles.prepareRestore(
      backup: backup,
      passphrase: phrase,
      key: key(2),
      target: restored,
      appSchemaVersion: appSchema ?? schema,
      localState: localState,
    );

    test('a copy opens with the device key, with all data', () async {
      await write();
      final info = await prepare();
      expect(info.items, 1);
      expect(backup.existsSync(), isTrue);

      final db = AppDatabase(openEncryptedDatabase(restored, key(2)));
      addTearDown(db.close);
      final items = await db.select(db.items).get();
      expect(items.single.rawText, marker);
      expect(containsText(restored, marker), isFalse);
    });

    test('only this device\'s settings: no device id, no passphrase', () async {
      await write();
      await prepare(localState: {'ui_language': 'en', 'phone_country': 'BE'});

      final db = AppDatabase(openEncryptedDatabase(restored, key(2)));
      addTearDown(db.close);
      final rows = await db.select(db.localState).get();
      expect(
        {for (final r in rows) r.key: r.value},
        {'ui_language': 'en', 'phone_country': 'BE'},
      );
    });

    test('a wrong passphrase leaves no copy behind', () async {
      await write();
      await expectLater(
        prepare(phrase: 'een ander wachtwoord'),
        throwsA(isA<BackupException>()),
      );
      expect(restored.existsSync(), isFalse);
    });

    test('a backup of a newer app is refused, no copy left', () async {
      await write();
      await expectLater(
        prepare(appSchema: schema - 1),
        throwsA(
          isA<BackupException>().having(
            (e) => e.problem,
            'problem',
            BackupProblem.tooNew,
          ),
        ),
      );
      expect(restored.existsSync(), isFalse);
    });
  });

  test('timing of the Argon2id settings on this machine', () async {
    final watch = Stopwatch()..start();
    await write();
    final made = watch.elapsedMilliseconds;
    watch.reset();
    await BackupFiles.inspect(
      backup: backup,
      passphrase: passphrase,
      appSchemaVersion: schema,
    );
    // ignore: avoid_print
    print('backup made in $made ms, opened in ${watch.elapsedMilliseconds} ms');
  });

  test('a backup that fails leaves no file behind', () async {
    final missing = File('${dir.path}/geen-map/back-up.offload');
    await expectLater(
      BackupFiles.write(
        database: database,
        key: key(1),
        passphrase: passphrase,
        target: missing,
      ),
      throwsA(isA<BackupException>()),
    );
    expect(missing.existsSync(), isFalse);
  });
}
