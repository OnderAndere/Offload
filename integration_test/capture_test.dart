import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

/// Capture on a real device (T1.6, REQ-001): an item survives a restart of
/// the encrypted storage, and saving is fast. Uses a temporary directory and
/// a separate test key, never the real data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_capture_key')
      : WindowsKeyStore(
          directory: keyDir,
          name: 'integration_test_capture_key',
        );

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_capture_it');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  testWidgets('a captured item is still in the inbox after a restart', (
    tester,
  ) async {
    final first = await AppStorage.open(directory: dir, keyStore: newStore());
    final id = await DriftItemRepository(
      first,
    ).capture('Bel Jan over de markt', source: ItemSource.app);
    await first.close();

    final second = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(second.close);
    final inbox = await DriftItemRepository(second).watchInbox().first;

    expect(inbox, hasLength(1));
    expect(inbox.single.id, id);
    expect(inbox.single.rawText, 'Bel Jan over de markt');
    expect(inbox.single.status, ItemStatus.inbox);
  });

  testWidgets('saving an item is fast (REQ-001)', (tester) async {
    final storage = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(storage.close);
    final repository = DriftItemRepository(storage);
    // Warm up: the first write also prepares statements.
    await repository.capture('warm-up', source: ItemSource.app);

    final millis = <int>[];
    for (var i = 0; i < 20; i++) {
      final watch = Stopwatch()..start();
      await repository.capture('item $i', source: ItemSource.app);
      millis.add(watch.elapsedMilliseconds);
    }
    millis.sort();
    debugPrint(
      'capture save time (ms): median ${millis[millis.length ~/ 2]}, '
      'max ${millis.last}',
    );

    // Generous bound: REQ-001 allows 3 s from tap to stored item, of which
    // saving should be only a small part.
    expect(millis.last, lessThan(500));
  });
}
