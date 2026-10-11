import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart' hide SearchIndex;
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/links/drift_item_link_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/sync/change_log_replayer.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

import '../../fakes/test_storage.dart';

/// Links between items (T10.9, REQ-054, DD-004 point 13).
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftItemLinkRepository links;
  late DriftTokenProcessor processor;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    links = DriftItemLinkRepository(storage);
    processor = DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    );
  });
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<String> capture(String text, {Map<String, String> links = const {}}) =>
      items.capture(text, source: ItemSource.app, links: links);

  /// Indexes what was saved: typed links match titles through the index.
  Future<void> index() => DriftSearchIndex(db()).processPending();

  /// The HLC has millisecond time: changes in a test must not share one.
  Future<void> later() => Future<void>.delayed(const Duration(milliseconds: 5));

  Future<List<ItemLink>> liveLinks(String from) => links.liveLinksFrom(from);

  Future<String?> resolvedLink(String itemId) async {
    final tokens =
        await (db().select(db().tokens)..where(
              (t) => t.itemId.equals(itemId) & t.tokenType.equals('link'),
            ))
            .get();
    return tokens.single.resolvedValue;
  }

  group('chosen links are saved with the text', () {
    test('capture stores the link with its label', () async {
      final offer = await capture('Offerte kozijnen vergelijken');
      final order = await capture(
        'Bestellen, zie [[Offerte kozijnen vergelijken]]',
        links: {'Offerte kozijnen vergelijken': offer},
      );

      final link = (await liveLinks(order)).single;
      expect(link.toItemId, offer);
      expect(link.kind, 'link');
      expect(link.label, 'Offerte kozijnen vergelijken');
      expect(await links.areLinked(offer, order), isTrue);
    });

    test('through the change log (REQ-008)', () async {
      final offer = await capture('Offerte');
      await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      final logged = await (db().select(
        db().changeLog,
      )..where((e) => e.entity.equals('item_links'))).get();
      expect(logged, hasLength(1));
    });

    test('a new choice for a label replaces the old link', () async {
      final a = await capture('Offerte A');
      final b = await capture('Offerte B');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': a});
      await later();
      await items.editText(order, 'Zie [[Offerte]]', links: {'Offerte': b});

      final live = await liveLinks(order);
      expect(live.single.toItemId, b);
    });

    test('the same choice again keeps the one link', () async {
      final a = await capture('Offerte');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': a});
      await items.editText(order, 'Zie [[Offerte]] nu', links: {'Offerte': a});
      expect(await liveLinks(order), hasLength(1));
    });

    test('an item never links to itself', () async {
      final id = await capture('Zie [[Zelf]]');
      await items.editText(id, 'Zie [[Zelf]].', links: {'Zelf': id});
      expect(await liveLinks(id), isEmpty);
    });
  });

  group('Koppelen and "geen item"', () {
    test('appendLink writes [[…]] at the end of the text and links', () async {
      final older = await capture('Offerte kozijnen vergelijken');
      final newer = await capture('Offertes voor kozijnen naast elkaar  ');

      await items.appendLink(newer, older, 'Offerte kozijnen vergelijken');

      final item = await (db().select(
        db().items,
      )..where((i) => i.id.equals(newer))).getSingle();
      expect(
        item.rawText,
        'Offertes voor kozijnen naast elkaar [[Offerte kozijnen vergelijken]]',
      );
      expect((await liveLinks(newer)).single.toItemId, older);
    });

    test('captureLinked makes an inbox item and links it', () async {
      final from = await capture('Daarna [[Container bestellen]]');
      final made = await items.captureLinked(
        from,
        'Container bestellen',
        source: ItemSource.app,
      );

      final item = await (db().select(
        db().items,
      )..where((i) => i.id.equals(made))).getSingle();
      expect(item.rawText, 'Container bestellen');
      expect(item.status, ItemStatus.inbox);
      expect((await liveLinks(from)).single.toItemId, made);
    });
  });

  group('processing keeps the links with the text', () {
    test('a chosen link resolves its token', () async {
      final offer = await capture('Offerte');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      await processor.process(order);
      expect(await resolvedLink(order), offer);
    });

    test('removing [[…]] from the text removes the link', () async {
      final offer = await capture('Offerte');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      await processor.process(order);
      await later();
      await items.editText(order, 'Zie de offerte');
      await processor.process(order);

      expect(await liveLinks(order), isEmpty);
      expect(await links.areLinked(order, offer), isFalse);
    });

    test('typing it back restores the chosen target', () async {
      // Two items with the same title: only the choice tells them apart.
      final a = await capture('Offerte');
      await capture('Offerte');
      await index();
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': a});
      await processor.process(order);
      await later();
      await items.editText(order, 'Zie [[Offer');
      await processor.process(order);
      await later();
      await items.editText(order, 'Zie [[Offerte]]');
      await processor.process(order);

      expect((await liveLinks(order)).single.toItemId, a);
      expect(await resolvedLink(order), a);
    });

    test('case and spacing in the text do not remove the link', () async {
      final offer = await capture('Offerte kozijnen');
      final order = await capture(
        'Zie [[Offerte kozijnen]]',
        links: {'Offerte kozijnen': offer},
      );
      await later();
      await items.editText(order, 'Zie [[offerte  Kozijnen]]');
      await processor.process(order);
      expect((await liveLinks(order)).single.toItemId, offer);
    });

    test('renaming the target keeps the link', () async {
      final offer = await capture('Offerte');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      await processor.process(order);
      await later();
      await items.editText(offer, 'Offertes vergelijken');
      await processor.process(order);
      expect(await resolvedLink(order), offer);
    });

    test('a target in the trash keeps its link', () async {
      final offer = await capture('Offerte');
      final order = await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      await items.moveToTrash(offer);
      await processor.process(order);

      expect(await resolvedLink(order), offer);
      final shown = (await links.watchLinksFrom(order).first).single;
      expect(shown.trashed, isTrue);
    });
  });

  group('typed without choosing (decision b)', () {
    test('links to the one item with that title', () async {
      final offer = await capture('Offerte kozijnen vergelijken @Jan');
      await index();
      final order = await capture('Zie [[offerte kozijnen vergelijken]]');
      await processor.process(order);
      expect(await resolvedLink(order), offer);
      expect(
        (await liveLinks(order)).single.label,
        'offerte kozijnen vergelijken',
      );
    });

    test('a Cyrillic title with spaces', () async {
      final kitchen = await capture('Нова кухня');
      await index();
      final order = await capture('Плитка для [[нова кухня]]');
      await processor.process(order);
      expect(await resolvedLink(order), kitchen);
    });

    test('several items with that title: no link', () async {
      await capture('Offerte');
      await capture('Offerte');
      await index();
      final order = await capture('Zie [[Offerte]]');
      await processor.process(order);
      expect(await resolvedLink(order), isNull);
      expect(await liveLinks(order), isEmpty);
    });

    test('no item with that title: nothing is created', () async {
      final order = await capture('Daarna [[Container bestellen]]');
      await processor.process(order);
      expect(await resolvedLink(order), isNull);
      expect(await db().select(db().items).get(), hasLength(1));
    });

    test('a cut label (…) only links through its own link', () async {
      await capture('Offerte');
      await index();
      final order = await capture('Zie [[Offerte…]]');
      await processor.process(order);
      expect(await resolvedLink(order), isNull);
    });

    test('an item in the trash is not linked by title', () async {
      final offer = await capture('Offerte');
      await index();
      await items.moveToTrash(offer);
      final order = await capture('Zie [[Offerte]]');
      await processor.process(order);
      expect(await resolvedLink(order), isNull);
    });
  });

  group('backlinks', () {
    test('live linking items, not those in the trash', () async {
      final offer = await capture('Offerte');
      final a = await capture('Zie [[Offerte]]', links: {'Offerte': offer});
      final b = await capture('Ook [[Offerte]]', links: {'Offerte': offer});
      await items.moveToTrash(b);

      final back = await links.watchBacklinks(offer).first;
      expect([for (final l in back) l.itemId], [a]);
    });
  });

  test('replaying the change log gives the same links', () async {
    final offer = await capture('Offerte');
    await capture('Offerte');
    final kitchen = await capture('Нова кухня');
    await index();
    final order = await capture(
      'Zie [[Offerte]] en [[нова кухня]]',
      links: {'Offerte': offer},
    );
    await processor.process(order);
    await later();
    await items.editText(order, 'Zie [[нова кухня]]');
    await processor.process(order);
    expect((await liveLinks(order)).single.toItemId, kitchen);

    final target = AppDatabase(NativeDatabase.memory());
    addTearDown(target.close);
    await ChangeLogReplayer(
      target,
    ).replay(await db().select(db().changeLog).get());

    List<String> rows(List<ItemLink> links) => [
      for (final l in links)
        '${l.id} ${l.fromItemId} ${l.toItemId} ${l.label} ${l.deletedAt}',
    ]..sort();
    expect(
      rows(await target.select(target.itemLinks).get()),
      rows(await db().select(db().itemLinks).get()),
    );
  });

  test('labels without an item are watched (no item chip)', () async {
    final offer = await capture('Offerte');
    final order = await capture(
      'Zie [[Offerte]] en [[Container]]',
      links: {'Offerte': offer},
    );
    await processor.process(order);
    expect(await links.watchUnlinkedLabels(order).first, {'container'});
  });
}
