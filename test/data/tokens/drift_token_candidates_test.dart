import 'package:drift/drift.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:offload/data/database/app_database.dart';
import 'package:offload/data/items/drift_item_repository.dart';
import 'package:offload/data/projects/drift_project_repository.dart';
import 'package:offload/data/search/drift_search_index.dart';
import 'package:offload/data/storage/app_storage.dart';
import 'package:offload/data/tokens/drift_token_candidates.dart';
import 'package:offload/data/tokens/drift_token_processor.dart';
import 'package:offload/domain/items/item_enums.dart';
import 'package:offload/domain/tokens/inline_token.dart';
import 'package:offload/domain/tokens/inline_token_registry.dart';

import '../../fakes/test_storage.dart';

/// Persons and tags for the suggestion list, with how often they are used.
void main() {
  late AppStorage storage;

  setUp(() async => storage = await openTestStorage());
  tearDown(() => storage.close());

  AppDatabase db() => storage.database;

  Future<void> captureAndProcess(String text) async {
    final id = await DriftItemRepository(
      storage,
    ).capture(text, source: ItemSource.app);
    await DriftTokenProcessor(
      storage,
      registry: InlineTokenRegistry.standard(),
      dates: () => DateVocabulary.empty,
    ).process(id);
  }

  test('people with their aliases and number of linked items', () async {
    await captureAndProcess('@Jan @Jan'); // one item: counts once
    await captureAndProcess('@Jan #renovatie');
    await captureAndProcess('@Piet');
    final janId = (await (db().select(
      db().people,
    )..where((p) => p.name.equals('Jan'))).getSingle()).id;
    await storage.writer.insert(
      db().personAliases,
      PersonAliasesCompanion(personId: Value(janId), alias: const Value('JD')),
    );

    final people = await DriftTokenCandidates(db()).people();

    final byName = {for (final p in people) p.name: p};
    expect(byName['Jan']!.uses, 2);
    expect(byName['Jan']!.aliases, ['JD']);
    expect(byName['Piet']!.uses, 1);
  });

  test('deleted people and tags are not suggested', () async {
    await captureAndProcess('@Oud #weg');
    final person = await db().select(db().people).getSingle();
    final tag = await db().select(db().tags).getSingle();
    await storage.writer.delete(db().people, person.id);
    await storage.writer.delete(db().tags, tag.id);

    final source = DriftTokenCandidates(db());

    expect(await source.people(), isEmpty);
    expect(await source.tags(), isEmpty);
  });

  test('items in the trash do not count as uses', () async {
    await captureAndProcess('@Jan');
    final item = await db().select(db().items).getSingle();
    await storage.writer.delete(db().items, item.id);

    final jan = (await DriftTokenCandidates(db()).people()).single;

    expect(jan.uses, 0);
  });

  test('tags with their number of linked items', () async {
    await captureAndProcess('#renovatie');
    await captureAndProcess('#renovatie #afvoer');

    final tags = {
      for (final t in await DriftTokenCandidates(db()).tags()) t.name: t.uses,
    };

    expect(tags, {'renovatie': 2, 'afvoer': 1});
  });

  test('projects, archived ones included, with their uses', () async {
    final projects = DriftProjectRepository(storage);
    final garden = await projects.create('Tuin');
    final oldProject = await projects.create('Oud');
    await projects.archive(oldProject);
    await captureAndProcess('snoeien ^tuin');
    await captureAndProcess('maaien ^tuin');

    final found = await DriftTokenCandidates(db()).projects();

    expect({for (final p in found.projects) p.name}, {'Tuin', 'Oud'});
    expect(found.uses, {garden: 2});
  });

  group('items for [[ (T10.9)', () {
    late DriftItemRepository items;
    setUp(() => items = DriftItemRepository(storage));

    Future<String> capture(String text) =>
        items.capture(text, source: ItemSource.app);

    Future<void> later() =>
        Future<void>.delayed(const Duration(milliseconds: 2));

    test('without a query: the newest live items, not itself', () async {
      final old = await capture('Oud');
      await later();
      final trashed = await capture('Weg');
      await items.moveToTrash(trashed);
      await later();
      final self = await capture('Zelf');
      await later();
      final newest = await capture('Nieuw');

      final found = await DriftTokenCandidates(db()).items('', excludeId: self);
      expect([for (final c in found) c.id], [newest, old]);
    });

    test('a query searches the index: items only, with project', () async {
      final renovation = await DriftProjectRepository(
        storage,
      ).create('Renovatie');
      final offer = await capture('Offerte kozijnen');
      await items.setProject(offer, renovation);
      await db()
          .into(db().people)
          .insert(
            PeopleCompanion.insert(id: 'p', hlc: 'h', name: 'Offerte Piet'),
          );
      await DriftSearchIndex(db()).processPending();

      final found = await DriftTokenCandidates(db()).items('offer');
      expect(found.single.id, offer);
      expect(found.single.project, 'Renovatie');
      expect(found.single.status, ItemStatus.inbox);
    });
  });
}
