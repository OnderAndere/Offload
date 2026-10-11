import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

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
import 'package:offload/platform/app_directory/platform_app_directory.dart';
import 'package:offload/platform/cipher/platform_aead_cipher.dart';

/// The platform side of T7.2b step C (DD-007 point 5) on the device: the
/// free space through the real channel, and the progress of making and
/// restoring a backup with attachments, the cipher made in the backup's
/// isolate as the screen makes it.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const passphrase = 'vier losse woorden hier';

  testWidgets('the free space of the app folder is known', (tester) async {
    final appDirectory = createPlatformAppDirectory();
    final data = await appDirectory.dataDirectory();
    final free = await appDirectory.freeBytes(data);
    expect(free, isNotNull);
    expect(free, greaterThan(0));
    // ignore: avoid_print
    print('T7.2b free space: $free bytes');
  });

  testWidgets('making and restoring report their progress', (tester) async {
    final dir = Directory.systemTemp.createTempSync('offload_progress');
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final attachmentsKey = Uint8List.fromList(
      List.generate(32, (i) => 5 * i & 0xff),
    );
    final database = File('${dir.path}/offload.db');
    final db = AppDatabase(openEncryptedDatabase(database, key));
    final storage = await AppStorage.load(db);
    final item = await DriftItemRepository(
      storage,
    ).capture('Opname van de moestuin', source: ItemSource.app);
    final folder = Directory('${dir.path}/attachments');
    final random = Random(3);
    final repository = DriftAttachmentRepository(
      storage,
      AttachmentStore(
        directory: folder,
        attachmentsKey: attachmentsKey,
        cipher: createPlatformAeadCipher(),
      ),
    );
    const size = 3 << 20;
    for (var i = 0; i < 2; i++) {
      await repository.add(
        owner: ItemOwner(item),
        mimeType: 'audio/mp4',
        content: Stream.value(
          Uint8List.fromList(List.generate(size, (_) => random.nextInt(256))),
        ),
      );
    }
    await db.close();

    final made = <(int, int)>[];
    final backup = File('${dir.path}/progress.offload');
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
      onProgress: (done, total) => made.add((done, total)),
    );
    await tester.pump();
    expect(result.copied, 2);
    expect(made.last, (2 * size, 2 * size));

    final restored = <(int, int)>[];
    final info = await BackupFiles.prepareRestore(
      backup: backup,
      passphrase: passphrase,
      key: key,
      target: File('${dir.path}/offload.restore.db'),
      appSchemaVersion: AppDatabase.currentSchemaVersion,
      localState: const {},
      attachments: RestoreAttachmentTarget(
        currentPath: folder.path,
        stagingPath: '${dir.path}/attachments.restore',
        keepListPath: '${dir.path}/attachments.keep',
        key: attachmentsKey,
        cipher: backgroundAeadCipherFactory(),
      ),
      onProgress: (done, total) => restored.add((done, total)),
    );
    await tester.pump();
    expect(info.attachments, 2);
    expect(restored.last, (2 * size, 2 * size));
    // ignore: avoid_print
    print(
      'T7.2b progress: ${made.length} reports making, '
      '${restored.length} restoring',
    );
  });
}
