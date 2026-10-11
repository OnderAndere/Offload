import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/attachments/drift_attachment_repository.dart';
import 'package:offload/data/backup/backup_attachments.dart';
import 'package:offload/data/backup/backup_files.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../fakes/fake_aead_cipher.dart';
import '../../fakes/fake_key_store.dart';

/// Making a backup with attachments (T7.2b step A, REQ-014, DD-007 "Backup
/// with attachments" points 1–2): one encrypted file, the attachments in
/// chunk tables of the copy, never plaintext on disk.
void main() {
  const passphrase = 'vier losse woorden hier';
  late Directory dir;
  late AppStorage storage;
  late DriftAttachmentRepository attachments;
  late String itemId;
  late File backup;
  late Directory home;
  final keys = FakeKeyStore();

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_backup_attachments');
    backup = File('${dir.path}${Platform.pathSeparator}backup.offload');
    home = Directory('${dir.path}${Platform.pathSeparator}app')..createSync();
    keys.key = null;
    storage = await AppStorage.open(directory: home, keyStore: keys);
    await storage.saveBackupPassphrase(passphrase);
    attachments = DriftAttachmentRepository(
      storage,
      AttachmentStore(
        directory: storage.attachmentsDirectory!,
        attachmentsKey: storage.attachmentsKey!,
        cipher: FakeAeadCipher(),
      ),
    );
    itemId = await DriftItemRepository(
      storage,
    ).capture('Kozijnen opmeten', source: ItemSource.app);
  });
  tearDown(() async {
    await storage.close();
    dir.deleteSync(recursive: true);
  });

  Uint8List bytes(int n, int seed) =>
      Uint8List.fromList(List.generate(n, (i) => (i * seed + 5) & 0xFF));

  Future<String> add(Uint8List content, {String mime = 'audio/mp4'}) =>
      attachments.add(
        owner: ItemOwner(itemId),
        mimeType: mime,
        content: Stream.value(content),
      );

  /// The backup opened as the app opens it, with the passphrase.
  Database openBackup() {
    final kdf = backupKdfs.first;
    final db = sqlite3.open(backup.path, mode: OpenMode.readOnly);
    db
      ..execute("PRAGMA cipher = '$backupCipher'")
      ..execute('PRAGMA tcost = ${kdf.tcost}')
      ..execute('PRAGMA mcost = ${kdf.mcost}')
      ..execute('PRAGMA pcost = ${kdf.pcost}')
      ..execute("PRAGMA key = '$passphrase'");
    addTearDown(db.close);
    return db;
  }

  Map<String, String> meta(Database db) => {
    for (final row in db.select('SELECT key, value FROM backup_meta'))
      row['key'] as String: row['value'] as String,
  };

  Uint8List chunksOf(Database db, String id) {
    final out = BytesBuilder();
    for (final row in db.select(
      'SELECT data FROM backup_attachment_chunks WHERE attachment_id = ? '
      'ORDER BY seq',
      [id],
    )) {
      out.add(row['data'] as Uint8List);
    }
    return out.takeBytes();
  }

  test(
    'every live attachment goes in, in chunks, with size and SHA-256',
    () async {
      final large = bytes(BackupAttachmentTables.chunkSize * 2 + 12345, 7);
      final small = bytes(300, 3);
      final big = await add(large);
      final little = await add(small, mime: 'image/jpeg');
      await attachments.delete(await add(bytes(50, 1)));

      final result = await storage.makeBackup(
        backup,
        cipher: FakeAeadCipher.new,
      );

      expect(result.copied, 2);
      expect(result.missing, 0);
      expect(result.bytes, large.length + small.length);
      final db = openBackup();
      expect(meta(db), {'format_version': '1', 'attachments': '1'});
      expect(chunksOf(db, big), large);
      expect(chunksOf(db, little), small);
      expect(
        db.select(
          'SELECT count(*) AS n FROM backup_attachment_chunks '
          'WHERE attachment_id = ?',
          [big],
        ).first['n'],
        3,
      );
      final records = {
        for (final row in db.select('SELECT * FROM backup_attachments'))
          row['attachment_id'] as String: (row['size'], row['sha256']),
      };
      expect(records, {
        big: (large.length, sha256.convert(large).toString()),
        little: (small.length, sha256.convert(small).toString()),
      });
    },
  );

  test(
    'a file that is gone or does not verify is left out and counted',
    () async {
      final kept = await add(bytes(1000, 5));
      final gone = await add(bytes(1000, 9));
      final broken = await add(bytes(1000, 11));
      final folder = storage.attachmentsDirectory!.path;
      File('$folder${Platform.pathSeparator}$gone').deleteSync();
      final file = File('$folder${Platform.pathSeparator}$broken');
      final data = file.readAsBytesSync()..[100] ^= 1;
      file.writeAsBytesSync(data);

      final result = await storage.makeBackup(
        backup,
        cipher: FakeAeadCipher.new,
      );

      expect(result.copied, 1);
      expect(result.missing, 2);
      final db = openBackup();
      expect(
        db
            .select(
              'SELECT DISTINCT attachment_id FROM backup_attachment_chunks',
            )
            .map((r) => r['attachment_id']),
        [kept],
      );
      expect(
        db.select('SELECT attachment_id FROM backup_attachments'),
        hasLength(1),
      );
    },
  );

  test('without attachments the backup says so and holds none', () async {
    await add(bytes(1000, 5));

    final result = await storage.makeBackup(backup);

    expect(result.copied, 0);
    final db = openBackup();
    expect(meta(db), {'format_version': '1', 'attachments': '0'});
    expect(db.select('SELECT * FROM backup_attachment_chunks'), isEmpty);
    // The records are in the database copy either way.
    expect(db.select('SELECT id FROM attachments'), hasLength(1));
  });

  test('progress runs up to the total', () async {
    await add(bytes(BackupAttachmentTables.chunkSize + 1, 2));
    await add(bytes(4000, 4));
    final seen = <(int, int)>[];

    await storage.makeBackup(
      backup,
      cipher: FakeAeadCipher.new,
      onProgress: (done, total) => seen.add((done, total)),
    );
    await pumpEventQueue();

    expect(seen, isNotEmpty);
    final total = BackupAttachmentTables.chunkSize + 1 + 4000;
    expect(seen.every((p) => p.$2 == total), isTrue);
    for (var i = 1; i < seen.length; i++) {
      expect(seen[i].$1, greaterThanOrEqualTo(seen[i - 1].$1));
    }
    expect(seen.last, (total, total));
  });

  test('the backup file holds no plaintext of an attachment', () async {
    await add(
      Uint8List.fromList(utf8.encode('Bel @Sanne over de moestuin ' * 200)),
      mime: 'text/plain',
    );

    await storage.makeBackup(backup, cipher: FakeAeadCipher.new);

    final onDisk = latin1.decode(backup.readAsBytesSync());
    expect(onDisk.contains('moestuin'), isFalse);
    expect(onDisk.contains('Sanne'), isFalse);
  });

  Future<List<String>> backupTablesInLiveDatabase() async => [
    for (final row
        in await storage.database
            .customSelect(
              "SELECT name FROM sqlite_master WHERE name LIKE 'backup_%'",
            )
            .get())
      row.read<String>('name'),
  ];

  test('make, restore, make again: the tables never reach the live '
      'database (review)', () async {
    await add(bytes(1000, 5));
    await storage.makeBackup(backup, cipher: FakeAeadCipher.new);
    await storage.prepareRestore(backup, cipher: FakeAeadCipher.new);
    await storage.close();
    AppStorage.finishRestore(home);
    storage = await AppStorage.open(directory: home, keyStore: keys);

    expect(await backupTablesInLiveDatabase(), isEmpty);
    final again = File('${dir.path}${Platform.pathSeparator}again.offload');
    final result = await storage.makeBackup(again, cipher: FakeAeadCipher.new);
    expect(result.missing, 0);
  });

  test('a database that already holds the tables still backs up', () async {
    // As a restore made before this fix left them.
    for (final table in [
      BackupAttachmentTables.meta,
      BackupAttachmentTables.attachments,
      BackupAttachmentTables.chunks,
    ]) {
      await storage.database.customStatement('CREATE TABLE $table (x INTEGER)');
    }
    expect(await backupTablesInLiveDatabase(), hasLength(3));

    await storage.makeBackup(backup, cipher: FakeAeadCipher.new);

    expect(meta(openBackup()), {'format_version': '1', 'attachments': '1'});
  });
}
