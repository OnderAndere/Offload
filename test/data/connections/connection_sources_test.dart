import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/links/drift_item_link_repository.dart';
import 'package:offload/data/people/drift_people_repository.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

import '../../fakes/test_storage.dart';

/// What Connections reads (T10.14, DD-018 point 15): every live link and
/// the people named in each item.
void main() {
  late AppStorage storage;
  late DriftItemRepository items;
  late DriftItemLinkRepository links;
  late DriftPeopleRepository people;
  late DriftTokenProcessor tokens;

  setUp(() async {
    storage = await openTestStorage();
    items = DriftItemRepository(storage);
    links = DriftItemLinkRepository(storage);
    people = DriftPeopleRepository(storage);
    tokens = DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    );
  });
  tearDown(() => storage.close());

  Future<String> capture(
    String text, {
    Map<String, String> links = const {},
  }) async {
    final id = await items.capture(text, source: ItemSource.app, links: links);
    await tokens.process(id);
    return id;
  }

  group('watchAllLinks', () {
    test('every live link between live items', () async {
      final mesh = await capture('Gaas kopen');
      final measurements = await capture('Maten kippenhok');
      final coop = await capture(
        'Kippenhok bouwen, eerst [[Gaas kopen]] en [[Maten kippenhok]]',
        links: {'Gaas kopen': mesh, 'Maten kippenhok': measurements},
      );
      expect(
        await links.watchAllLinks().first,
        unorderedEquals([
          (from: coop, to: mesh),
          (from: coop, to: measurements),
        ]),
      );
    });

    test('a link to or from the trash is left out', () async {
      final mesh = await capture('Gaas kopen');
      final coop = await capture(
        'Kippenhok bouwen, eerst [[Gaas kopen]]',
        links: {'Gaas kopen': mesh},
      );
      final other = await capture(
        'Ander plan met [[Gaas kopen]]',
        links: {'Gaas kopen': mesh},
      );
      await items.moveToTrash(mesh);
      expect(await links.watchAllLinks().first, isEmpty);
      await items.restoreFromTrash(mesh);
      await items.moveToTrash(other);
      expect(await links.watchAllLinks().first, [(from: coop, to: mesh)]);
    });

    test('a link removed from the text is left out', () async {
      final mesh = await capture('Gaas kopen');
      final coop = await capture(
        'Kippenhok bouwen, eerst [[Gaas kopen]]',
        links: {'Gaas kopen': mesh},
      );
      await items.editText(coop, 'Kippenhok bouwen');
      await tokens.process(coop);
      expect(await links.watchAllLinks().first, isEmpty);
    });
  });

  group('watchMentions', () {
    test('the people named in each live item', () async {
      final both = await capture('Kippenhok met @Sanne en @Joris');
      final one = await capture('Bellen met @sanne');
      await capture('Niemand genoemd');
      final trashed = await capture('Weg @Sanne');
      await items.moveToTrash(trashed);
      final sanne = await people.find('Sanne');
      final joris = await people.find('Joris');

      expect(await items.watchMentions().first, {
        both: {sanne, joris},
        one: {sanne},
      });
    });
  });
}
