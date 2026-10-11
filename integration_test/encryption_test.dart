import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/crypto/crypto_service.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/database/database_encryption.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

const _marker = 'PLAINTEXT_MARKER_c41e';

/// End-to-end check of T1.4 on a real device (REQ-004, DD-007): the platform
/// key store, key derivation and the encrypted database file together.
/// Uses a separate test key, never the production master key.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_key')
      : WindowsKeyStore(directory: keyDir, name: 'integration_test_key');

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_it');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  testWidgets('encrypted database survives a restart and leaks no text', (
    tester,
  ) async {
    final file = File('${dir.path}${Platform.pathSeparator}offload.db');

    final first = await CryptoService.unlock(
      newStore(),
      existingDataFound: false,
    );
    final db = AppDatabase(
      openEncryptedDatabase(file, first.deriveKey(KeyPurpose.database)),
    );
    await db.customStatement(
      'INSERT INTO local_state (key, value) VALUES (?, ?)',
      ['probe', _marker],
    );
    await db.close();

    for (final path in [
      file.path,
      '${file.path}-wal',
      '${file.path}-journal',
    ]) {
      final f = File(path);
      if (!f.existsSync()) continue;
      final content = String.fromCharCodes(f.readAsBytesSync());
      expect(content.contains(_marker), isFalse, reason: path);
      expect(content.contains('SQLite format 3'), isFalse, reason: path);
    }

    // A fresh store instance, as after an app restart.
    final second = await CryptoService.unlock(
      newStore(),
      existingDataFound: true,
    );
    final reopened = AppDatabase(
      openEncryptedDatabase(file, second.deriveKey(KeyPurpose.database)),
    );
    final rows = await reopened
        .customSelect("SELECT value FROM local_state WHERE key = 'probe'")
        .get();
    expect(rows.single.read<String>('value'), _marker);
    await reopened.close();
  });

  testWidgets('existing data without its key is never given a new key', (
    tester,
  ) async {
    await expectLater(
      CryptoService.unlock(newStore(), existingDataFound: true),
      throwsA(isA<MissingMasterKeyException>()),
    );
    expect(await newStore().readMasterKey(), isNull);
  });
}
