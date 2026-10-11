import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/platform/capture/android_capture_channel.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/presentation/capture/pending_captures.dart';

/// The widget's encrypted queue on a real Android device (T1.7, AC REQ-001,
/// DD-010): captures go from the native queue into the database and leave
/// the queue only after that. Uses a temporary database and a separate test
/// key. The queue itself is the app's real one: captures made by hand on the
/// test device end up in the temporary database of this test.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  final android = Platform.isAndroid;
  late Directory dir;
  final keyStore = AndroidKeyStore(name: 'integration_test_widget_key');

  setUp(() async {
    if (!android) return;
    dir = Directory.systemTemp.createTempSync('offload_widget_it');
    await keyStore.deleteForTesting();
  });

  tearDown(() async {
    if (!android) return;
    await keyStore.deleteForTesting();
    dir.deleteSync(recursive: true);
  });

  testWidgets('captures from the widget queue reach the inbox once', (
    tester,
  ) async {
    final channel = AndroidCaptureChannel();
    final watch = Stopwatch()..start();
    final first = await channel.enqueueForTesting(
      'Bel Jan over de markt',
      ItemSource.widget,
    );
    debugPrint(
      'widget queue write (ms, incl. channel): ${watch.elapsedMilliseconds}',
    );
    final second = await channel.enqueueForTesting(
      '  Idee: afvoer  ',
      ItemSource.widget,
    );

    // Not yet stored: taking them removes nothing.
    final before = await channel.pending();
    expect(before.captures.map((c) => c.id), containsAll([first, second]));
    expect(
      (await channel.pending()).captures,
      hasLength(before.captures.length),
    );

    final storage = await AppStorage.open(directory: dir, keyStore: keyStore);
    addTearDown(storage.close);
    final repository = DriftItemRepository(storage);
    await importPendingCaptures(channel, repository);

    final inbox = {
      for (final item in await repository.watchInbox().first) item.id: item,
    };
    expect(inbox[first]!.rawText, 'Bel Jan over de markt');
    expect(inbox[second]!.rawText, '  Idee: afvoer  ');
    expect(inbox[first]!.source, ItemSource.widget);
    expect((await channel.pending()).captures, isEmpty);

    // Delivered again (as after a crash before acknowledging): stored once.
    expect(
      await repository.captureWithId(
        first,
        'Bel Jan over de markt',
        source: ItemSource.widget,
      ),
      isFalse,
    );
  }, skip: !android);

  testWidgets('shared text keeps its lines and its source (REQ-002)', (
    tester,
  ) async {
    final channel = AndroidCaptureChannel();
    const shared = 'Offerte renovatie\nKun je voor vrijdag reageren?\n\nGroet';
    final id = await channel.enqueueForTesting(shared, ItemSource.share);

    final storage = await AppStorage.open(directory: dir, keyStore: keyStore);
    addTearDown(storage.close);
    final repository = DriftItemRepository(storage);
    await importPendingCaptures(channel, repository);

    final item = (await repository.watchInbox().first).singleWhere(
      (item) => item.id == id,
    );
    expect(item.rawText, shared);
    expect(item.source, ItemSource.share);
    expect((await channel.pending()).captures, isEmpty);
  }, skip: !android);
}
