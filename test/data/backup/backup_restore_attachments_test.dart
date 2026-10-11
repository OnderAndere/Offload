import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/attachments/drift_attachment_repository.dart';
import 'package:offload/data/backup/backup_files.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/backup/backup.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:sqlite3/sqlite3.dart';

import '../../fakes/fake_aead_cipher.dart';
import '../../fakes/fake_key_store.dart';

/// Restoring a backup with its attachments (T7.2b step B, REQ-014, DD-007
/// "Backup with attachments" point 3; PO 09-10-2026: a backup without
/// attachments keeps this device's files of restored records, option b).
void main() {
  const passphrase = 'vier losse woorden hier';
  late Directory root;
  late Directory phone;
  late Directory tablet;
  late File backup;
  final phoneKeys = FakeKeyStore();
  final tabletKeys = FakeKeyStore();

  setUp(() {
    root = Directory.systemTemp.createTempSync('offload_restore_att');
    phone = Directory('${root.path}/phone')..createSync();
    tablet = Directory('${root.path}/tablet')..createSync();
    backup = File('${root.path}/Offload-back-up.offload');
    phoneKeys.key = null;
    tabletKeys.key = null;
  });
  tearDown(() => root.deleteSync(recursive: true));

  Future<AppStorage> open(Directory dir, FakeKeyStore keys) =>
      AppStorage.open(directory: dir, keyStore: keys);

  DriftAttachmentRepository attachmentsOf(AppStorage s) =>
      DriftAttachmentRepository(
        s,
        AttachmentStore(
          directory: s.attachmentsDirectory!,
          attachmentsKey: s.attachmentsKey!,
          cipher: FakeAeadCipher(),
        ),
      );

  Future<String> addAttachment(AppStorage s, String text) async {
    final item = await DriftItemRepository(
      s,
    ).capture('Item met $text', source: ItemSource.app);
    return attachmentsOf(s).add(
      owner: ItemOwner(item),
      mimeType: 'audio/mp4',
      content: Stream.value(utf8.encode(text)),
    );
  }

  Future<String?> contentOf(AppStorage s, String id) async {
    final files = attachmentsOf(s).files;
    if (!files.exists(id)) return null;
    return utf8.decode(await files.readAll(id));
  }

  /// Restores [backup] on the device in [dir], as the screen does.
  Future<AppStorage> restore(
    AppStorage s,
    Directory dir,
    FakeKeyStore keys, {
    bool cipher = true,
  }) async {
    await s.prepareRestore(
      backup,
      passphrase: passphrase,
      cipher: cipher ? FakeAeadCipher.new : null,
    );
    await s.close();
    AppStorage.finishRestore(dir);
    return open(dir, keys);
  }

  List<String> leftovers(Directory dir) => [
    for (final name in [
      AppStorage.restoreAttachmentsFolderName,
      AppStorage.beforeRestoreAttachmentsFolderName,
      AppStorage.restoreKeepListName,
    ])
      if (FileSystemEntity.typeSync('${dir.path}/$name') !=
          FileSystemEntityType.notFound)
        name,
  ];

  test('with attachments onto another device: its files, its key', () async {
    final p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    final one = await addAttachment(p, 'eerste opname');
    final two = await addAttachment(p, 'tweede opname');
    await p.makeBackup(backup, cipher: FakeAeadCipher.new);
    await p.close();

    var t = await open(tablet, tabletKeys);
    final own = await addAttachment(t, 'van de tablet');
    final info = await BackupFiles.inspect(
      backup: backup,
      passphrase: passphrase,
      appSchemaVersion: t.database.schemaVersion,
    );
    expect(info.withAttachments, isTrue);
    expect(info.attachments, 2);
    t = await restore(t, tablet, tabletKeys);
    addTearDown(t.close);

    expect(await contentOf(t, one), 'eerste opname');
    expect(await contentOf(t, two), 'tweede opname');
    expect(await contentOf(t, own), isNull);
    expect(leftovers(tablet), isEmpty);
    expect(
      await t.database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE name LIKE 'backup_%'",
          )
          .get(),
      isEmpty,
    );
  });

  test('without attachments on the same device: its own files stay '
      '(option b)', () async {
    var p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    final inBackup = await addAttachment(p, 'voor de back-up');
    await p.makeBackup(backup);
    final later = await addAttachment(p, 'na de back-up');

    final info = await BackupFiles.inspect(
      backup: backup,
      passphrase: passphrase,
      appSchemaVersion: p.database.schemaVersion,
    );
    expect(info.withAttachments, isFalse);
    p = await restore(p, phone, phoneKeys, cipher: false);
    addTearDown(p.close);

    expect(await contentOf(p, inBackup), 'voor de back-up');
    // Its record is not in the backup: the file goes.
    expect(attachmentsOf(p).files.exists(later), isFalse);
    expect(leftovers(phone), isEmpty);
  });

  test('without attachments onto another device: no files', () async {
    final p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    final one = await addAttachment(p, 'opname');
    await p.makeBackup(backup);
    await p.close();

    var t = await open(tablet, tabletKeys);
    final own = await addAttachment(t, 'van de tablet');
    t = await restore(t, tablet, tabletKeys, cipher: false);
    addTearDown(t.close);

    expect(await attachmentsOf(t).liveFor(ItemOwner('x')), isEmpty);
    expect(attachmentsOf(t).files.exists(one), isFalse);
    expect(attachmentsOf(t).files.exists(own), isFalse);
    expect(leftovers(tablet), isEmpty);
  });

  test('a changed chunk stops the restore; nothing changes', () async {
    final p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    await addAttachment(p, 'opname');
    await p.makeBackup(backup, cipher: FakeAeadCipher.new);
    await p.close();
    final copy = _openBackup(backup, passphrase);
    copy.execute("UPDATE backup_attachment_chunks SET data = X'00'");
    copy.close();

    final t = await open(tablet, tabletKeys);
    addTearDown(t.close);
    final own = await addAttachment(t, 'van de tablet');
    await expectLater(
      t.prepareRestore(
        backup,
        passphrase: passphrase,
        cipher: FakeAeadCipher.new,
      ),
      throwsA(isA<BackupException>()),
    );
    expect(await contentOf(t, own), 'van de tablet');
    expect(leftovers(tablet), isEmpty);
  });

  test('a newer layout of the attachment tables is too new', () async {
    final p = await open(phone, phoneKeys);
    addTearDown(p.close);
    await p.saveBackupPassphrase(passphrase);
    await p.makeBackup(backup);
    final copy = _openBackup(backup, passphrase);
    copy.execute(
      "UPDATE backup_meta SET value = '2' WHERE key = 'format_version'",
    );
    copy.close();

    await expectLater(
      p.prepareRestore(backup, passphrase: passphrase),
      throwsA(
        isA<BackupException>().having(
          (e) => e.problem,
          'problem',
          BackupProblem.tooNew,
        ),
      ),
    );
  });

  test(
    'stopped after the database swap: the next start swaps the folder',
    () async {
      final p = await open(phone, phoneKeys);
      await p.saveBackupPassphrase(passphrase);
      final one = await addAttachment(p, 'opname');
      await p.makeBackup(backup, cipher: FakeAeadCipher.new);
      await p.close();

      final t = await open(tablet, tabletKeys);
      final own = await addAttachment(t, 'van de tablet');
      await t.prepareRestore(
        backup,
        passphrase: passphrase,
        cipher: FakeAeadCipher.new,
      );
      await t.close();
      AppStorage.finishRestore(tablet);
      // As if the app stopped between the database and the folder swap.
      Directory(
        '${tablet.path}/attachments',
      ).renameSync('${tablet.path}/attachments.restore');
      Directory(
        '${tablet.path}/attachments.before-restore',
      ).renameSync('${tablet.path}/attachments');

      final again = await open(tablet, tabletKeys);
      addTearDown(again.close);
      expect(await contentOf(again, one), 'opname');
      expect(attachmentsOf(again).files.exists(own), isFalse);
      expect(leftovers(tablet), isEmpty);
    },
  );

  test(
    'a restored database that does not open: the old folder is back',
    () async {
      final p = await open(phone, phoneKeys);
      await p.saveBackupPassphrase(passphrase);
      await addAttachment(p, 'opname');
      await p.makeBackup(backup, cipher: FakeAeadCipher.new);
      await p.close();

      final t = await open(tablet, tabletKeys);
      final own = await addAttachment(t, 'van de tablet');
      await t.prepareRestore(
        backup,
        passphrase: passphrase,
        cipher: FakeAeadCipher.new,
      );
      await t.close();
      AppStorage.finishRestore(tablet);
      // The restored database is broken: opening puts the previous one back.
      File(
        '${tablet.path}/${AppStorage.databaseFileName}',
      ).writeAsBytesSync(Uint8List(4096));

      final again = await open(tablet, tabletKeys);
      addTearDown(again.close);
      expect(await contentOf(again, own), 'van de tablet');
      // The app says so once it has started (T7.2 follow-up).
      expect(again.restoreUndone, isTrue);
      expect(leftovers(tablet), isEmpty);
    },
  );

  test('restoring reports the attachment bytes, ending at the total '
      '(step C)', () async {
    final p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    await addAttachment(p, 'eerste opname');
    await addAttachment(p, 'tweede');
    await p.makeBackup(backup, cipher: FakeAeadCipher.new);
    await p.close();

    final t = await open(tablet, tabletKeys);
    addTearDown(t.close);
    final heard = <(int, int)>[];
    await t.prepareRestore(
      backup,
      passphrase: passphrase,
      cipher: FakeAeadCipher.new,
      onProgress: (done, total) => heard.add((done, total)),
    );
    // The port hands its messages over after the isolate ends.
    await pumpEventQueue();
    const total = 'eerste opname'.length + 'tweede'.length;
    expect(heard, isNotEmpty);
    expect(heard.last, (total, total));
    for (final (index, (done, _)) in heard.indexed.skip(1)) {
      expect(done, greaterThanOrEqualTo(heard[index - 1].$1));
    }
    AppStorage.discardRestore(tablet);
  });

  /// A restore with attachments swapped in on the tablet, its database
  /// broken, as before an undo; returns the tablet's own attachment.
  Future<String> brokenRestore() async {
    final p = await open(phone, phoneKeys);
    await p.saveBackupPassphrase(passphrase);
    await addAttachment(p, 'opname');
    await p.makeBackup(backup, cipher: FakeAeadCipher.new);
    await p.close();

    final t = await open(tablet, tabletKeys);
    final own = await addAttachment(t, 'van de tablet');
    await t.prepareRestore(
      backup,
      passphrase: passphrase,
      cipher: FakeAeadCipher.new,
    );
    await t.close();
    AppStorage.finishRestore(tablet);
    return own;
  }

  test('undo stopped after removing the restored database: the next start '
      'finishes it (review)', () async {
    final own = await brokenRestore();
    // The first step of the undo: the restored database is gone, the
    // folders not yet swapped back.
    for (final name in [
      AppStorage.databaseFileName,
      '${AppStorage.databaseFileName}-journal',
    ]) {
      final f = File('${tablet.path}/$name');
      if (f.existsSync()) f.deleteSync();
    }

    final again = await open(tablet, tabletKeys);
    addTearDown(again.close);
    expect(await contentOf(again, own), 'van de tablet');
    expect(leftovers(tablet), isEmpty);
  });

  test('undo stopped after the folder went back: the next start finishes '
      'it', () async {
    final own = await brokenRestore();
    for (final name in [
      AppStorage.databaseFileName,
      '${AppStorage.databaseFileName}-journal',
    ]) {
      final f = File('${tablet.path}/$name');
      if (f.existsSync()) f.deleteSync();
    }
    Directory('${tablet.path}/attachments').deleteSync(recursive: true);
    Directory(
      '${tablet.path}/attachments.before-restore',
    ).renameSync('${tablet.path}/attachments');

    final again = await open(tablet, tabletKeys);
    addTearDown(again.close);
    expect(await contentOf(again, own), 'van de tablet');
    expect(leftovers(tablet), isEmpty);
  });

  Future<(String, String)> twoKeptFiles(AppStorage p) async {
    await p.saveBackupPassphrase(passphrase);
    final one = await addAttachment(p, 'eerste');
    final two = await addAttachment(p, 'tweede');
    await p.makeBackup(backup);
    await p.prepareRestore(backup, passphrase: passphrase);
    await p.close();
    AppStorage.finishRestore(phone);
    return (one, two);
  }

  test('settling stopped halfway: the next start finishes it', () async {
    final (one, two) = await twoKeptFiles(await open(phone, phoneKeys));
    // As if the restored database opened (its predecessor deleted) and the
    // app stopped after moving one of the kept files.
    for (final name in [
      AppStorage.beforeRestoreFileName,
      '${AppStorage.beforeRestoreFileName}-journal',
    ]) {
      final f = File('${phone.path}/$name');
      if (f.existsSync()) f.deleteSync();
    }
    File(
      '${phone.path}/attachments.before-restore/$one',
    ).renameSync('${phone.path}/attachments/$one');

    final again = await open(phone, phoneKeys);
    addTearDown(again.close);
    expect(await contentOf(again, one), 'eerste');
    expect(await contentOf(again, two), 'tweede');
    expect(leftovers(phone), isEmpty);
  });

  test('a file that cannot move fails the start, never the restore '
      '(review)', () async {
    final (one, two) = await twoKeptFiles(await open(phone, phoneKeys));
    // Something in the way of one kept file: a folder under its name.
    Directory('${phone.path}/attachments/$two').createSync(recursive: true);

    await expectLater(
      open(phone, phoneKeys),
      throwsA(isA<StorageOpenException>()),
    );
    // The restore stands: the database from before it is gone.
    expect(
      File('${phone.path}/${AppStorage.beforeRestoreFileName}').existsSync(),
      isFalse,
    );

    Directory('${phone.path}/attachments/$two').deleteSync();
    final again = await open(phone, phoneKeys);
    addTearDown(again.close);
    expect(await contentOf(again, one), 'eerste');
    expect(await contentOf(again, two), 'tweede');
    expect(leftovers(phone), isEmpty);
  });
}

Database _openBackup(File backup, String passphrase) {
  final kdf = backupKdfs.first;
  return sqlite3.open(backup.path)
    ..execute("PRAGMA cipher = '$backupCipher'")
    ..execute('PRAGMA tcost = ${kdf.tcost}')
    ..execute('PRAGMA mcost = ${kdf.mcost}')
    ..execute('PRAGMA pcost = ${kdf.pcost}')
    ..execute("PRAGMA key = '$passphrase'");
}
