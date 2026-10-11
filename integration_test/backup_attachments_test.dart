import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/attachments/attachment_store.dart';
import 'package:offload/data/attachments/drift_attachment_repository.dart';
import 'package:offload/data/backup/backup_attachments.dart';
import 'package:offload/data/backup/backup_files.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/attachments/attachment.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/platform/cipher/platform_aead_cipher.dart';
import 'package:sqlite3/sqlite3.dart';

/// A backup with attachments on a real device (T7.2b step A): the platform
/// cipher works inside the backup's isolate (on Android through the root
/// isolate's token), and the attachments land in the encrypted backup file.
/// Prints the time for 20 MB.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('attachments go into the backup from its isolate', (
    tester,
  ) async {
    final dir = Directory.systemTemp.createTempSync('offload_backup_att_it');
    addTearDown(() => dir.deleteSync(recursive: true));
    final database = File('${dir.path}/offload.db');
    final backup = File('${dir.path}/Offload-back-up.offload');
    final folder = Directory('${dir.path}/attachments');
    final key = Uint8List.fromList(List.generate(32, (i) => i * 5 & 0xff));
    final attachmentsKey = Uint8List.fromList(List.generate(32, (i) => 99 - i));
    const passphrase = 'vier losse woorden hier';

    final db = AppDatabase(openEncryptedDatabase(database, key));
    final storage = await AppStorage.load(db);
    final item = await DriftItemRepository(
      storage,
    ).capture('Kozijnen opmeten', source: ItemSource.app);
    final repository = DriftAttachmentRepository(
      storage,
      AttachmentStore(
        directory: folder,
        attachmentsKey: attachmentsKey,
        cipher: createPlatformAeadCipher(),
      ),
    );
    final random = Random(20);
    final content = Uint8List.fromList(
      List.generate(20 << 20, (_) => random.nextInt(256)),
    );
    final id = await repository.add(
      owner: ItemOwner(item),
      mimeType: 'audio/mp4',
      content: Stream.value(content),
    );
    await db.close();

    final watch = Stopwatch()..start();
    final result = await BackupFiles.write(
      database: database,
      key: key,
      passphrase: passphrase,
      target: backup,
      attachments: BackupAttachmentSource(
        directoryPath: folder.path,
        key: attachmentsKey,
        cipher: backgroundAeadCipherFactory(),
      ),
    );
    final made = watch.elapsedMilliseconds;
    expect(result.copied, 1);
    expect(result.missing, 0);

    final kdf = backupKdfs.first;
    final copy = sqlite3.open(backup.path, mode: OpenMode.readOnly)
      ..execute("PRAGMA cipher = '$backupCipher'")
      ..execute('PRAGMA tcost = ${kdf.tcost}')
      ..execute('PRAGMA mcost = ${kdf.mcost}')
      ..execute('PRAGMA pcost = ${kdf.pcost}')
      ..execute("PRAGMA key = '$passphrase'");
    addTearDown(copy.close);
    final hasher = sha256.convert([
      for (final row in copy.select(
        'SELECT data FROM backup_attachment_chunks WHERE attachment_id = ? '
        'ORDER BY seq',
        [id],
      ))
        ...(row['data'] as Uint8List),
    ]);
    expect(hasher, sha256.convert(content));
    expect(
      copy.select('SELECT sha256 FROM backup_attachments').single['sha256'],
      sha256.convert(content).toString(),
    );
    // ignore: avoid_print
    print('T7.2b ${Platform.operatingSystem}: backup with 20 MB in $made ms');
  });
}
