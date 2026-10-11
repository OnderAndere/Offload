import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/backup/backup_files.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';

/// A backup on a real device, in the sqlite3mc build that ships (T7.2,
/// DD-007): the AEGIS cipher is there, Argon2id with the chosen settings
/// takes its time, and a restore opens with the device key. Prints the
/// times, for the PO decision "stronger when under a second on a phone".
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('backup and restore with AEGIS and Argon2id', (tester) async {
    final dir = Directory.systemTemp.createTempSync('offload_backup_it');
    addTearDown(() => dir.deleteSync(recursive: true));
    final database = File('${dir.path}/offload.db');
    final backup = File('${dir.path}/Offload-back-up.offload');
    final restored = File('${dir.path}/offload.restore.db');
    final key = Uint8List.fromList(List.generate(32, (i) => i * 3 & 0xff));
    final otherKey = Uint8List.fromList(List.generate(32, (i) => 255 - i));
    const passphrase = 'vier losse woorden hier';

    final db = AppDatabase(openEncryptedDatabase(database, key));
    final storage = await AppStorage.load(db);
    for (var i = 0; i < 200; i++) {
      await DriftItemRepository(
        storage,
      ).capture('Нова кухня $i', source: ItemSource.app);
    }
    final schema = db.schemaVersion;
    await db.close();

    final watch = Stopwatch()..start();
    await BackupFiles.write(
      database: database,
      key: key,
      passphrase: passphrase,
      target: backup,
    );
    final made = watch.elapsedMilliseconds;

    watch.reset();
    final info = await BackupFiles.inspect(
      backup: backup,
      passphrase: passphrase,
      appSchemaVersion: schema,
    );
    final opened = watch.elapsedMilliseconds;
    expect(info.items, 200);

    watch.reset();
    await BackupFiles.prepareRestore(
      backup: backup,
      passphrase: passphrase,
      key: otherKey,
      target: restored,
      appSchemaVersion: schema,
      localState: const {},
    );
    final prepared = watch.elapsedMilliseconds;

    final back = AppDatabase(openEncryptedDatabase(restored, otherKey));
    expect(await back.select(back.items).get(), hasLength(200));
    await back.close();

    // ignore: avoid_print
    print(
      'BACKUP-TIMES ${Platform.operatingSystem}: made $made ms, '
      'opened $opened ms, restore prepared $prepared ms',
    );
  });
}
