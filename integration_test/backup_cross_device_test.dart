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

/// A backup with attachments from one platform restored on the other (T7.2b,
/// PO 09-10-2026): on Android it makes `cross-device.offload` in the app's
/// temporary folder (run with `--no-uninstall`, then `adb root` and pull
/// it); on Windows it restores the file named in OFFLOAD_CROSS_BACKUP and
/// checks the attachment against the SHA-256 both sides compute.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  const passphrase = 'vier losse woorden hier';

  /// The same 3 MB on both sides.
  final content = () {
    final random = Random(42);
    return Uint8List.fromList(
      List.generate(3 << 20, (_) => random.nextInt(256)),
    );
  }();
  final expected = sha256.convert(content).toString();

  testWidgets('Android makes the backup', (tester) async {
    final dir = Directory('${Directory.systemTemp.path}/cross');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
    dir.createSync();
    final key = Uint8List.fromList(List.generate(32, (i) => i));
    final attachmentsKey = Uint8List.fromList(
      List.generate(32, (i) => 7 * i & 0xff),
    );
    final db = AppDatabase(
      openEncryptedDatabase(File('${dir.path}/offload.db'), key),
    );
    final storage = await AppStorage.load(db);
    final item = await DriftItemRepository(
      storage,
    ).capture('Opname van de moestuin', source: ItemSource.app);
    final folder = Directory('${dir.path}/attachments');
    await DriftAttachmentRepository(
      storage,
      AttachmentStore(
        directory: folder,
        attachmentsKey: attachmentsKey,
        cipher: createPlatformAeadCipher(),
      ),
    ).add(
      owner: ItemOwner(item),
      mimeType: 'audio/mp4',
      content: Stream.value(content),
    );
    await db.close();
    final backup = File('${Directory.systemTemp.path}/cross-device.offload');
    final result = await BackupFiles.write(
      database: File('${dir.path}/offload.db'),
      key: key,
      passphrase: passphrase,
      target: backup,
      attachments: BackupAttachmentSource(
        directoryPath: folder.path,
        key: attachmentsKey,
        cipher: backgroundAeadCipherFactory(),
      ),
    );
    expect(result.copied, 1);
    // ignore: avoid_print
    print('T7.2b cross-device backup: ${backup.path} ($expected)');
  }, skip: !Platform.isAndroid);

  testWidgets('Windows restores it', (tester) async {
    final path = Platform.environment['OFFLOAD_CROSS_BACKUP'];
    if (path == null) {
      markTestSkipped('OFFLOAD_CROSS_BACKUP not set');
      return;
    }
    final dir = Directory.systemTemp.createTempSync('offload_cross');
    addTearDown(() => dir.deleteSync(recursive: true));
    final key = Uint8List.fromList(List.generate(32, (i) => 200 - i));
    final attachmentsKey = Uint8List.fromList(
      List.generate(32, (i) => 3 * i & 0xff),
    );
    final restored = File('${dir.path}/offload.restore.db');
    final info = await BackupFiles.prepareRestore(
      backup: File(path),
      passphrase: passphrase,
      key: key,
      target: restored,
      appSchemaVersion: AppDatabase.currentSchemaVersion,
      localState: const {},
      attachments: RestoreAttachmentTarget(
        currentPath: '${dir.path}/attachments',
        stagingPath: '${dir.path}/attachments.restore',
        keepListPath: '${dir.path}/attachments.keep',
        key: attachmentsKey,
        cipher: backgroundAeadCipherFactory(),
      ),
    );
    expect(info.withAttachments, isTrue);
    expect(info.attachments, 1);
    final db = AppDatabase(openEncryptedDatabase(restored, key));
    addTearDown(db.close);
    final record = await db.select(db.attachments).getSingle();
    final plain = await AttachmentStore(
      directory: Directory('${dir.path}/attachments.restore'),
      attachmentsKey: attachmentsKey,
      cipher: createPlatformAeadCipher(),
    ).readAll(record.id);
    expect(sha256.convert(plain).toString(), expected);
    // ignore: avoid_print
    print('T7.2b cross-device restore on Windows: SHA-256 matches');
  }, skip: !Platform.isWindows);
}
