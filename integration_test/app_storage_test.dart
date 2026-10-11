import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/settings/language_choice.dart';
import 'package:offload/platform/app_directory/platform_app_directory.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

/// Start-up of the storage on a real device (T1.6, REQ-004, DD-007): the
/// platform data directory, the platform key store and the encrypted file.
/// Uses a temporary directory and a separate test key, never the real data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_storage_key')
      : WindowsKeyStore(
          directory: keyDir,
          name: 'integration_test_storage_key',
        );

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_storage_it');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  testWidgets('the platform data directory exists and is private', (
    tester,
  ) async {
    final data = await createPlatformAppDirectory().dataDirectory();

    expect(data.existsSync(), isTrue);
    expect(data.path, contains('eu.marandos.offload'));
  });

  testWidgets('device id and language survive a restart', (tester) async {
    final first = await AppStorage.open(directory: dir, keyStore: newStore());
    final deviceId = first.writer.clock.node;
    await first.saveLanguageChoice(const LanguageChoice.language('en'));
    await first.close();

    final second = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(second.close);

    expect(second.writer.clock.node, deviceId);
    expect(second.languageChoice, const LanguageChoice.language('en'));
  });

  testWidgets('data without its key is never given a new key', (tester) async {
    final first = await AppStorage.open(directory: dir, keyStore: newStore());
    await first.close();
    final file = File(
      '${dir.path}${Platform.pathSeparator}${AppStorage.databaseFileName}',
    );
    final before = file.readAsBytesSync();
    await deleteTestKey();

    await expectLater(
      AppStorage.open(directory: dir, keyStore: newStore()),
      throwsA(
        isA<StorageOpenException>().having(
          (e) => e.failure,
          'failure',
          StorageFailure.missingKey,
        ),
      ),
    );

    expect(await newStore().readMasterKey(), isNull);
    expect(file.readAsBytesSync(), before);
  });
}
