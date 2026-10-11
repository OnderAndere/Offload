import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/platform/key_store/android_key_store.dart';
import 'package:offload/platform/key_store/key_store.dart';
import 'package:offload/platform/key_store/windows_key_store.dart';

/// Full-text search on the real, encrypted database of each platform (T2.5,
/// AC REQ-011, DD-016): FTS5, diacritics, prefix search, ranking, whether
/// the trigram tokenizer is there (for T10.13), and that capturing is not
/// slower with the index. Uses a temporary directory and a separate test
/// key, never the real data.
void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  late Directory dir;
  late Directory keyDir;

  KeyStore newStore() => Platform.isAndroid
      ? AndroidKeyStore(name: 'integration_test_search_key')
      : WindowsKeyStore(directory: keyDir, name: 'integration_test_search_key');

  Future<void> deleteTestKey() async {
    final store = newStore();
    if (store is AndroidKeyStore) await store.deleteForTesting();
    if (store is WindowsKeyStore) await store.deleteForTesting();
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offload_search_it');
    keyDir = Directory('${dir.path}${Platform.pathSeparator}keys');
    await deleteTestKey();
  });

  tearDown(() async {
    await deleteTestKey();
    dir.deleteSync(recursive: true);
  });

  testWidgets('search works on the encrypted database', (tester) async {
    final storage = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(storage.close);
    final db = storage.database;
    final version = await db
        .customSelect('SELECT sqlite_version() AS v')
        .getSingle();
    debugPrint('sqlite_version: ${version.read<String>('v')}');

    final repository = DriftItemRepository(storage);
    final index = DriftSearchIndex(db);
    final cafe = await repository.capture(
      'Afspraak in het café over de keuring',
      source: ItemSource.app,
    );
    final renovatieText = await repository.capture(
      'Iets over de renovatie',
      source: ItemSource.app,
    );
    await index.processPending();

    expect((await index.search('cafe')).single.id, cafe);
    expect((await index.search('keur')).single.id, cafe);
    expect((await index.search('renovatie')).single.id, renovatieText);

    // Survives closing and opening: the index is in the encrypted file.
    await storage.close();
    final reopened = await AppStorage.open(
      directory: dir,
      keyStore: newStore(),
    );
    addTearDown(reopened.close);
    final again = DriftSearchIndex(reopened.database);
    expect((await again.search('CAFÉ')).single.id, cafe);
  });

  testWidgets('bm25 puts a title hit above a text hit', (tester) async {
    final storage = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(storage.close);
    final repository = DriftItemRepository(storage);
    final inText = await repository.capture(
      'Een lange tekst waarin de renovatie ergens voorkomt',
      source: ItemSource.app,
    );
    final inTitle = await repository.capture('Kort', source: ItemSource.app);
    await storage.database.customStatement(
      "UPDATE items SET title = 'Renovatie' WHERE id = ?",
      [inTitle],
    );
    final index = DriftSearchIndex(storage.database);
    await index.processPending();

    expect(
      [for (final h in await index.search('renovatie')) h.id],
      [inTitle, inText],
    );
  });

  testWidgets('the trigram tokenizer is available (T10.13)', (tester) async {
    final storage = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(storage.close);
    final db = storage.database;

    await db.customStatement(
      "CREATE VIRTUAL TABLE temp.trigram_check USING fts5(x, tokenize = 'trigram')",
    );
    await db.customStatement(
      "INSERT INTO temp.trigram_check (x) VALUES ('keuring')",
    );
    final rows = await db
        .customSelect(
          "SELECT x FROM temp.trigram_check WHERE trigram_check MATCH 'urin'",
        )
        .get();
    expect(rows, hasLength(1));

    // Diacritics folding with trigram needs SQLite 3.45; only reported.
    try {
      await db.customStatement(
        'CREATE VIRTUAL TABLE temp.trigram_diacritics USING '
        "fts5(x, tokenize = 'trigram remove_diacritics 1')",
      );
      debugPrint('trigram remove_diacritics: available');
    } catch (e) {
      debugPrint('trigram remove_diacritics: not available ($e)');
    }
  });

  testWidgets('capturing is not slower with the index (REQ-001)', (
    tester,
  ) async {
    final storage = await AppStorage.open(directory: dir, keyStore: newStore());
    addTearDown(storage.close);
    final repository = DriftItemRepository(storage);

    Future<int> medianMicros() async {
      final times = <int>[];
      for (var i = 0; i < 45; i++) {
        final watch = Stopwatch()..start();
        await repository.capture(
          'Markt $i van de afvoer',
          source: ItemSource.app,
        );
        watch.stop();
        if (i >= 5) times.add(watch.elapsedMicroseconds); // warm-up
      }
      times.sort();
      return times[times.length ~/ 2];
    }

    final withIndex = await medianMicros();
    // The same without the triggers: the only work the index adds to saving.
    for (final trigger in ['items_search_insert', 'items_search_update']) {
      await storage.database.customStatement('DROP TRIGGER $trigger');
    }
    final withoutIndex = await medianMicros();
    debugPrint(
      'capture median (µs): with index $withIndex, without $withoutIndex',
    );

    // Generous against noise; a real slowdown is many times larger.
    expect(withIndex, lessThan(withoutIndex * 1.5 + 2000));
  });
}
