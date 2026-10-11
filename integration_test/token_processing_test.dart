import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/time/local_date.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';
import 'package:offload/domain/tokens/token_processing.dart';
import 'package:offload/l10n/app_localizations.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';
import 'package:offload/presentation/tokens/token_display.dart';

/// Working out tokens on a real device (T2.2 step B): persons, tags, tokens
/// and the deadline survive a restart of the encrypted storage. Uses a
/// temporary directory and a separate test key, never the real data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_tokens_key')
      : WindowsKeyStore(directory: keyDir, name: 'integration_test_tokens_key');

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_tokens_it');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  DriftTokenProcessor processorFor(AppStorage storage) => DriftTokenProcessor(
    storage,
    registry: InlineTokenRegistry.standard(),
    dates: () => dateVocabularyOf(lookupAppLocalizations(const Locale('nl'))),
  );

  testWidgets('tokens, persons and the deadline survive a restart', (
    tester,
  ) async {
    final first = await AppStorage.open(directory: dir, keyStore: newStore());
    final items = DriftItemRepository(first);
    final id = await items.capture(
      'Bel (@Jan) en @Олена over #renovatie !morgen',
      source: ItemSource.app,
    );
    final watch = Stopwatch()..start();
    await processorFor(first).process(id);
    debugPrint('token processing (ms): ${watch.elapsedMilliseconds}');
    await first.close();

    final second = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(second.close);
    final db = second.database;
    final names = [for (final p in await db.select(db.people).get()) p.name];
    final item = await db.select(db.items).getSingle();
    final tokens = await db.select(db.tokens).get();

    expect(names, unorderedEquals(['Jan', 'Олена']));
    expect((await db.select(db.tags).getSingle()).name, 'renovatie');
    expect(tokens, hasLength(4));
    expect(
      storedToDateOnly(item.dueAt!),
      LocalDate.of(DateTime.now()).addDays(1),
    );
    expect(item.rawText, 'Bel (@Jan) en @Олена over #renovatie !morgen');

    // Again with other case: the same persons, no new ones (DD-015).
    final again = await DriftItemRepository(
      second,
    ).capture('@jan @олена', source: ItemSource.app);
    await processorFor(second).process(again);
    expect(await db.select(db.people).get(), hasLength(2));
  });
}
