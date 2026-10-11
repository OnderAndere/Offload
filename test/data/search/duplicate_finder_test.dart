import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/links/drift_item_link_repository.dart';
import 'package:offload/data/search/drift_duplicate_dismissals.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/search/duplicates.dart';

import '../../fakes/test_storage.dart';

/// Finding the older item a new item repeats, and ignoring a pair (REQ-053;
/// T2.5 step C).
void main() {
  late AppStorage storage;
  late DriftSearchIndex index;
  late DriftDuplicateDismissals dismissals;
  late DuplicateFinder finder;

  setUp(() async {
    storage = await openTestStorage();
    index = DriftSearchIndex(storage.database);
    dismissals = DriftDuplicateDismissals(storage);
    finder = DuplicateFinder(index, dismissals);
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text) =>
      DriftItemRepository(storage).capture(text, source: ItemSource.app);

  test('the newer item points at the older one, not the other way', () async {
    final older = await capture('Offerte renovatie opvragen bij Jan');
    await index.processPending();
    final newer = await capture('offerte renovatie opvragen');

    // The new item needs no index entry yet: its own text is compared.
    expect(
      (await finder.olderDuplicateOf(newer, 'offerte renovatie opvragen'))?.id,
      older,
    );
    await index.processPending();
    expect(
      await finder.olderDuplicateOf(
        older,
        'Offerte renovatie opvragen bij Jan',
      ),
      isNull,
    );
  });

  test('different items give no hint', () async {
    await capture('Bel Piet');
    await index.processPending();
    final newer = await capture('Bel Jan');

    expect(await finder.olderDuplicateOf(newer, 'Bel Jan'), isNull);
  });

  test('a done item counts, one in the trash does not', () async {
    final done = await capture('Afvoer keuren meubelplan');
    final trashed = await capture('Renovatie offerte versturen vandaag');
    await storage.writer.update(
      db().items,
      done,
      const ItemsCompanion(status: Value(ItemStatus.done)),
    );
    await storage.writer.delete(db().items, trashed);
    await index.processPending();

    final a = await capture('afvoer keuren meubelplan');
    final b = await capture('renovatie offerte versturen vandaag');

    expect(
      (await finder.olderDuplicateOf(a, 'afvoer keuren meubelplan'))?.id,
      done,
    );
    expect(
      await finder.olderDuplicateOf(b, 'renovatie offerte versturen vandaag'),
      isNull,
    );
  });

  test(
    'ignoring a pair holds in both directions and is synchronised',
    () async {
      final older = await capture('Bel Jan over de renovatie');
      await index.processPending();
      final newer = await capture('bel jan over de renovatie');

      await dismissals.dismiss(newer, older);

      expect(await dismissals.isDismissed(older, newer), isTrue);
      expect(
        await finder.olderDuplicateOf(newer, 'bel jan over de renovatie'),
        isNull,
      );
      final logged = await (db().select(
        db().changeLog,
      )..where((e) => e.entity.equals('duplicate_dismissals'))).get();
      expect(logged, hasLength(1));

      // Ignoring again adds nothing.
      await dismissals.dismiss(older, newer);
      expect(await db().select(db().duplicateDismissals).get(), hasLength(1));
    },
  );

  test('another older duplicate still shows after ignoring one', () async {
    final first = await capture('Bel Jan over de renovatie');
    final second = await capture('bel jan over de renovatie!');
    await index.processPending();
    final newest = await capture('Bel Jan over de renovatie.');

    final best = await finder.olderDuplicateOf(
      newest,
      'Bel Jan over de renovatie.',
    );
    await dismissals.dismiss(newest, best!.id);
    final next = await finder.olderDuplicateOf(
      newest,
      'Bel Jan over de renovatie.',
    );

    expect({best.id, next?.id}, {first, second});
  });

  group('links (T10.9, DD-004 point 13)', () {
    test('linked items are no duplicates', () async {
      final older = await capture('Offerte renovatie opvragen bij Jan');
      await index.processPending();
      final newer = await DriftItemRepository(storage).capture(
        'offerte renovatie opvragen [[Offerte renovatie opvragen bij Jan]]',
        source: ItemSource.app,
        links: {'Offerte renovatie opvragen bij Jan': older},
      );
      final linked = DuplicateFinder(
        index,
        dismissals,
        DriftItemLinkRepository(storage),
      );
      expect(
        await linked.olderDuplicateOf(newer, 'offerte renovatie opvragen'),
        isNull,
      );
    });

    test('the text of a link does not count', () async {
      final older = await capture('Offerte kozijnen vergelijken');
      await index.processPending();
      final newer = await capture('Bestellen [[Offerte kozijnen vergelijken]]');
      expect(
        await finder.olderDuplicateOf(
          newer,
          'Bestellen [[Offerte kozijnen vergelijken]]',
        ),
        isNull,
      );
      expect(older, isNotNull);
    });
  });
}
